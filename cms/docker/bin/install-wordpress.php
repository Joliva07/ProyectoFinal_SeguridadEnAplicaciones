<?php
// AuroraShop — instalacion inicial de WordPress + WooCommerce SIN pasar por la web (issue #40).
//
// Nginx bloquea /wp-admin/install.php, asi que la instalacion se hace desde dentro del contenedor:
//   kubectl exec -i <pod> -n aurorashop -c php-fpm -- php -- https://aurorashop.ancordss.me.uk < cms/docker/bin/install-wordpress.php > credenciales.txt
//   docker compose exec -T php php -- http://localhost:8080 < bin/install-wordpress.php > credenciales.txt
//
// Requiere que el usuario de BD tenga temporalmente CREATE, ALTER, INDEX y REFERENCES (ver README).
// La contrasena del administrador se genera aqui y SOLO sale por STDOUT: redirigirla a un archivo,
// guardarla en un gestor de contrasenas y borrar el archivo. Los mensajes de estado van a STDERR.
// Si WordPress ya esta instalado no cambia nada.

$url   = rtrim($argv[1] ?? '', '/');
$user  = $argv[2] ?? 'aurora-admin';
$email = $argv[3] ?? 'admin@example.invalid';
if (!preg_match('~^https?://[A-Za-z0-9.-]+(:\d+)?$~', $url)) {
    fwrite(STDERR, "Uso: php -- <URL del sitio> [usuario] [correo] < install-wordpress.php\n");
    exit(2);
}
$parts = parse_url($url);
$_SERVER['HTTP_HOST']   = $parts['host'] . (isset($parts['port']) ? ':' . $parts['port'] : '');
$_SERVER['HTTPS']       = $parts['scheme'] === 'https' ? 'on' : '';
$_SERVER['REQUEST_URI'] = '/';
define('WP_INSTALLING', true);

require '/var/www/html/wp-load.php';
require_once ABSPATH . 'wp-admin/includes/upgrade.php';
require_once ABSPATH . 'wp-admin/includes/plugin.php';

if (is_blog_installed()) {
    fwrite(STDERR, "WordPress ya estaba instalado; no se cambia nada.\n");
    exit(0);
}

$pass = wp_generate_password(24, true, false);
$r = wp_install('AuroraShop', $user, $email, true, '', $pass, 'es_ES');
if (is_wp_error($r) || empty($r['user_id'])) {
    fwrite(STDERR, "ERROR en wp_install\n");
    exit(1);
}
update_option('siteurl', $url);
update_option('home', $url);
update_option('permalink_structure', '/%postname%/');
update_option('users_can_register', 0);
update_option('default_comment_status', 'closed');
update_option('blogdescription', 'Tienda demo del proyecto de Seguridad en Aplicaciones');

$a = activate_plugin('woocommerce/woocommerce.php', '', false, true);
if (is_wp_error($a)) {
    fwrite(STDERR, 'ERROR activando WooCommerce: ' . $a->get_error_message() . "\n");
    exit(1);
}
// Cargar WooCommerce en este proceso para crear sus tablas y paginas (tienda, carrito, mi cuenta)
include_once WP_PLUGIN_DIR . '/woocommerce/woocommerce.php';
if (class_exists('WC_Install')) {
    WC_Install::install();
    WC_Install::create_pages();
}
update_option('woocommerce_currency', 'GTQ');
update_option('woocommerce_default_country', 'GT');
flush_rewrite_rules(true);

global $wpdb;
$tablas = (int) $wpdb->get_var($wpdb->prepare(
    'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = %s', DB_NAME));
fwrite(STDERR, 'OK: WordPress ' . get_bloginfo('version') . ' instalado, WooCommerce '
    . (defined('WC_VERSION') ? WC_VERSION : '?') . " activo, $tablas tablas, URL " . home_url() . "\n");

echo "Usuario: $user\nContrasena: $pass\nURL: $url/wp-admin/\n";
