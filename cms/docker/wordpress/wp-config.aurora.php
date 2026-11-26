<?php
/**
 * AuroraShop — wp-config.php (issue #40)
 *
 * Este archivo NO contiene secretos y se versiona con otro nombre (el .gitignore excluye
 * wp-config.php). En la imagen se copia a /var/www/wp-config.php, un nivel arriba del
 * webroot, asi que Nginx nunca lo sirve.
 *
 * Los valores sensibles vienen del config.php que genera generate-config.php al arrancar
 * (/run/aurora si existe ese emptyDir en memoria; si no, /tmp/aurora).
 */

$aurora = null;
foreach (['/run/aurora/config.php', '/tmp/aurora/config.php'] as $aurora_config_file) {
    if (is_readable($aurora_config_file)) {
        $aurora = require $aurora_config_file;
        break;
    }
}
if (!is_array($aurora)) {
    error_log('[aurora] falta config.php generado; revisar el entrypoint');
    http_response_code(503);
    exit('Servicio no disponible.');
}

// --- Base de datos (en GKE: cloud-sql-proxy en 127.0.0.1 con autenticacion IAM) ---
define('DB_NAME', $aurora['DB_NAME']);
define('DB_USER', $aurora['DB_USER']);
define('DB_PASSWORD', $aurora['DB_PASSWORD']);
define('DB_HOST', $aurora['DB_HOST']);
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// --- Claves y salts (unicas por ambiente, desde Secret Manager) ---
foreach ([
    'AUTH_KEY', 'SECURE_AUTH_KEY', 'LOGGED_IN_KEY', 'NONCE_KEY',
    'AUTH_SALT', 'SECURE_AUTH_SALT', 'LOGGED_IN_SALT', 'NONCE_SALT',
] as $aurora_key) {
    define($aurora_key, $aurora[$aurora_key]);
}

// Prefijo distinto de wp_ para dificultar inyecciones genericas
$table_prefix = $aurora['TABLE_PREFIX'];

// --- URLs: si no se fijan, WordPress usa las guardadas en la BD al instalar ---
if ($aurora['WP_HOME'] !== '') {
    define('WP_HOME', $aurora['WP_HOME']);
}
if ($aurora['WP_SITEURL'] !== '') {
    define('WP_SITEURL', $aurora['WP_SITEURL']);
}
define('WP_ENVIRONMENT_TYPE', $aurora['WP_ENVIRONMENT_TYPE']);
define('FORCE_SSL_ADMIN', $aurora['FORCE_SSL_ADMIN']);

// --- Hardening ---
define('DISALLOW_FILE_EDIT', true);          // sin editor de temas/plugins en wp-admin
define('DISALLOW_FILE_MODS', true);          // sin instalar/actualizar plugins desde wp-admin (imagen inmutable)
define('DISALLOW_UNFILTERED_HTML', true);    // nadie (ni admin) guarda HTML/JS sin filtrar: evita XSS almacenado (#44)
define('AUTOMATIC_UPDATER_DISABLED', true);  // las actualizaciones llegan con una imagen nueva por CI
define('WP_AUTO_UPDATE_CORE', false);

define('WP_DEBUG', false);
define('WP_DEBUG_DISPLAY', false);
define('WP_DEBUG_LOG', false);
define('SCRIPT_DEBUG', false);

// Bloquea peticiones HTTP salientes salvo a los hosts permitidos (lista separada por comas)
define('WP_HTTP_BLOCK_EXTERNAL', $aurora['BLOCK_EXTERNAL']);
if ($aurora['ACCESSIBLE_HOSTS'] !== '') {
    define('WP_ACCESSIBLE_HOSTS', $aurora['ACCESSIBLE_HOSTS']);
}

define('DISABLE_WP_CRON', $aurora['DISABLE_WP_CRON']);
define('WP_POST_REVISIONS', 10);
define('EMPTY_TRASH_DAYS', 30);
define('WP_TEMP_DIR', '/tmp/');

unset($aurora, $aurora_config_file, $aurora_key);

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/html/');
}

require_once ABSPATH . 'wp-settings.php';
