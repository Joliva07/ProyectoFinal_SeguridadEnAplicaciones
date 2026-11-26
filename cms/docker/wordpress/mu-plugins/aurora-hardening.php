<?php
/**
 * Plugin Name: AuroraShop — hardening del CMS
 * Description: 2FA obligatorio para personal, sin enumeracion de usuarios, versiones ocultas, login con mensajes genericos y bloqueo por intentos, roles minimos y uploads restringidos (issue #44).
 *
 * Es must-use: siempre se carga y no se puede desactivar desde wp-admin. Complementa (no sustituye)
 * las reglas de Nginx y del WAF de Cloudflare: si una capa falla, la otra sigue protegiendo.
 */

if (!defined('ABSPATH')) {
    exit;
}

const AURORA_LOGIN_MAX_FAILS   = 5;                 // intentos fallidos por usuario+IP
const AURORA_LOGIN_LOCK_SECS   = 15 * MINUTE_IN_SECONDS;
const AURORA_ROLES_VERSION     = '1';
const AURORA_GENERIC_LOGIN_MSG = '<strong>Error:</strong> usuario o contraseña incorrectos.';

/* -------------------------------------------------------------------------
 * 1. 2FA (TOTP) obligatorio para administradores y gestores de la tienda
 * ---------------------------------------------------------------------- */

/** Personal con acceso privilegiado al panel. */
function aurora_is_privileged($user): bool
{
    return $user instanceof WP_User && $user->exists()
        && (user_can($user, 'manage_options') || user_can($user, 'manage_woocommerce'));
}

/** Personal privilegiado que todavia no configuro su segundo factor. */
function aurora_needs_2fa_enrollment($user): bool
{
    return aurora_is_privileged($user)
        && class_exists('Two_Factor_Core')
        && !Two_Factor_Core::is_user_using_two_factor($user->ID);
}

// Solo TOTP (app autenticadora) y codigos de respaldo. Sin correo (no hay SMTP) ni el proveedor de pruebas.
add_filter('two_factor_providers', static function (array $providers): array {
    return array_intersect_key($providers, array_flip(['Two_Factor_Totp', 'Two_Factor_Backup_Codes']));
});

// Mientras no tenga 2FA, el personal solo puede entrar a su perfil para configurarlo.
add_action('admin_init', static function (): void {
    if (wp_doing_ajax() || !aurora_needs_2fa_enrollment(wp_get_current_user())) {
        return;
    }
    if ($GLOBALS['pagenow'] !== 'profile.php') {
        wp_safe_redirect(admin_url('profile.php?aurora_2fa=required#two-factor-options'));
        exit;
    }
});

add_action('admin_notices', static function (): void {
    if (!aurora_needs_2fa_enrollment(wp_get_current_user())) {
        return;
    }
    echo '<div class="notice notice-error"><p><strong>AuroraShop:</strong> tu cuenta tiene permisos de administración. '
        . 'Activa la verificación en dos pasos con una app autenticadora (<em>Time Based One-Time Password</em>) '
        . 'y genera tus códigos de respaldo en la sección <strong>Two-Factor Options</strong> de abajo. '
        . 'Hasta entonces el resto del panel está bloqueado.</p></div>';
});

// La API REST tampoco sirve de atajo: sin 2FA solo se permiten las rutas del propio Two Factor.
add_filter('rest_authentication_errors', static function ($result) {
    if (!empty($result) || !is_user_logged_in() || !aurora_needs_2fa_enrollment(wp_get_current_user())) {
        return $result;
    }
    $route = (string) ($GLOBALS['wp']->query_vars['rest_route'] ?? '');
    if (str_starts_with($route, '/two-factor/')) {
        return $result;
    }
    return new WP_Error('aurora_2fa_required', 'Configura la verificación en dos pasos antes de usar la API.', ['status' => 403]);
});

// Las contraseñas de aplicación permiten entrar por REST sin segundo factor.
add_filter('wp_is_application_passwords_available', '__return_false');

/* -------------------------------------------------------------------------
 * 2. Login: mensajes genericos y bloqueo temporal por usuario + IP
 * ---------------------------------------------------------------------- */

function aurora_login_key(string $username): string
{
    $ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '');   // IP real: Nginx la toma de CF-Connecting-IP
    return 'aurora_lf_' . hash('sha256', $ip . '|' . strtolower(trim($username)));
}

add_filter('authenticate', static function ($user, $username) {
    $username = (string) $username;
    if ($username !== '') {
        $fails = (int) get_transient(aurora_login_key($username));
        if ($fails >= AURORA_LOGIN_MAX_FAILS) {
            // Incluso con la contraseña correcta: el bloqueo no debe revelar si se acerto.
            return new WP_Error('aurora_locked', AURORA_GENERIC_LOGIN_MSG);
        }
    }
    if (is_wp_error($user) && array_intersect($user->get_error_codes(), ['invalid_username', 'invalid_email', 'incorrect_password'])) {
        return new WP_Error('aurora_invalid_login', AURORA_GENERIC_LOGIN_MSG);
    }
    return $user;
}, 99, 2);

add_action('wp_login_failed', static function (string $username): void {
    $key = aurora_login_key($username);
    set_transient($key, (int) get_transient($key) + 1, AURORA_LOGIN_LOCK_SECS);
});

add_action('wp_login', static function (string $username): void {
    delete_transient(aurora_login_key($username));
});

// "Olvide mi contraseña": misma respuesta exista o no la cuenta.
$aurora_lostpassword = static function (): void {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        return;
    }
    if (function_exists('retrieve_password')) {
        retrieve_password();   // el resultado se ignora a proposito
    }
    wp_safe_redirect(add_query_arg('checkemail', 'confirm', wp_login_url()));
    exit;
};
add_action('login_form_lostpassword', $aurora_lostpassword);
add_action('login_form_retrievepassword', $aurora_lostpassword);

/* -------------------------------------------------------------------------
 * 3. Sin enumeracion de usuarios
 * ---------------------------------------------------------------------- */

// /?author=N y /author/<slug>/ -> 404 para visitantes (antes revelaba el usuario del administrador).
add_action('template_redirect', static function (): void {
    if (is_user_logged_in() || (!isset($_GET['author']) && !is_author())) {
        return;
    }
    remove_action('template_redirect', 'redirect_canonical');
    global $wp_query;
    $wp_query->set_404();
    status_header(404);
    nocache_headers();
}, 1);

add_filter('author_link', static function (string $link): string {
    return is_user_logged_in() ? $link : home_url('/');
});

// Sitemap de usuarios (wp-sitemap-users-1.xml).
add_filter('wp_sitemaps_add_provider', static function ($provider, string $name) {
    return $name === 'users' ? false : $provider;
}, 10, 2);

// REST /wp/v2/users por cualquier ruta (/wp-json/... o ?rest_route=...): solo personal que edita contenido.
add_filter('rest_pre_dispatch', static function ($result, $server, WP_REST_Request $request) {
    if (preg_match('#^/wp/v2/users(/|$)#', $request->get_route()) && !current_user_can('edit_posts')) {
        return new WP_Error('rest_user_cannot_view', 'No autorizado.', ['status' => 401]);
    }
    return $result;
}, 10, 3);

// oEmbed publica el nombre y la URL del autor.
add_filter('oembed_response_data', static function (array $data): array {
    unset($data['author_name'], $data['author_url']);
    return $data;
});

/* -------------------------------------------------------------------------
 * 4. Versiones ocultas y superficie de XML-RPC
 * ---------------------------------------------------------------------- */

remove_action('wp_head', 'wp_generator');
add_filter('the_generator', '__return_empty_string');   // HTML, feeds y la etiqueta de WooCommerce

// ?ver=7.1.5 / ?ver=11.3.1 -> token opaco y estable (sigue sirviendo para invalidar cache).
$aurora_hide_ver = static function (string $src): string {
    $query = (string) wp_parse_url($src, PHP_URL_QUERY);
    parse_str($query, $args);
    if (!isset($args['ver']) || !is_string($args['ver'])) {
        return $src;
    }
    return add_query_arg('ver', substr(hash_hmac('sha256', $args['ver'], wp_salt('nonce')), 0, 10), $src);
};
add_filter('style_loader_src', $aurora_hide_ver, 20);
add_filter('script_loader_src', $aurora_hide_ver, 20);

add_filter('xmlrpc_enabled', '__return_false');          // Nginx ya responde 403; defensa en profundidad
add_filter('wp_headers', static function (array $headers): array {
    unset($headers['X-Pingback']);
    return $headers;
});
remove_action('wp_head', 'rsd_link');

/* -------------------------------------------------------------------------
 * 5. Roles minimos
 * ---------------------------------------------------------------------- */

// Una sola vez por version: quita roles que la tienda no usa. HTML sin filtrar lo bloquea
// DISALLOW_UNFILTERED_HTML en wp-config.php.
add_action('init', static function (): void {
    if (wp_installing() || get_option('aurora_roles_version') === AURORA_ROLES_VERSION) {
        return;
    }
    foreach (['author', 'contributor'] as $role) {
        if (get_role($role) && !get_users(['role' => $role, 'number' => 1, 'fields' => 'ID'])) {
            remove_role($role);
        }
    }
    if (!get_role((string) get_option('default_role'))) {
        update_option('default_role', get_role('customer') ? 'customer' : 'subscriber');
    }
    update_option('aurora_roles_version', AURORA_ROLES_VERSION);
});

/* -------------------------------------------------------------------------
 * 6. Uploads: solo imagenes, PDF y CSV (importador de WooCommerce)
 * ---------------------------------------------------------------------- */

add_filter('upload_mimes', static function (): array {
    return [
        'jpg|jpeg|jpe' => 'image/jpeg',
        'png'          => 'image/png',
        'gif'          => 'image/gif',
        'webp'         => 'image/webp',
        'pdf'          => 'application/pdf',
        'csv'          => 'text/csv',
    ];
}, 99);
