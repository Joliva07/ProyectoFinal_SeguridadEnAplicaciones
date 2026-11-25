<?php
/**
 * AuroraShop — wp-config.php (issue #40)
 *
 * Este archivo NO contiene secretos y se versiona con otro nombre (el .gitignore excluye
 * wp-config.php). En la imagen se copia a /srv/aurora/wp-config.php, un nivel arriba del
 * webroot, asi que Nginx nunca lo sirve.
 *
 * Los valores sensibles vienen de /run/aurora/config.php, generado al arrancar por
 * generate-config.php.
 */

$aurora_config_file = '/run/aurora/config.php';
if (!is_readable($aurora_config_file)) {
    error_log('[aurora] falta /run/aurora/config.php; revisar el entrypoint');
    http_response_code(503);
    exit('Servicio no disponible.');
}
$aurora = require $aurora_config_file;

// --- Base de datos ---
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

// --- URLs ---
define('WP_HOME', $aurora['WP_HOME']);
define('WP_SITEURL', $aurora['WP_SITEURL']);
define('WP_ENVIRONMENT_TYPE', $aurora['AURORA_ENV'] === 'local' ? 'local' : 'production');
define('FORCE_SSL_ADMIN', $aurora['FORCE_SSL_ADMIN']);

// --- Hardening ---
define('DISALLOW_FILE_EDIT', true);          // sin editor de temas/plugins en wp-admin
define('DISALLOW_FILE_MODS', true);          // sin instalar/actualizar plugins desde wp-admin (imagen inmutable)
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
