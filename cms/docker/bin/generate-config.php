<?php
/**
 * AuroraShop — genera config.php al arrancar el contenedor PHP (issue #40).
 *
 * wp-config.php (versionado, sin secretos) lee ese archivo. Los secretos nunca quedan en la
 * imagen ni en el repositorio. Salida: /run/aurora/config.php si ese directorio es escribible
 * (emptyDir en memoria, recomendado); si no, /tmp/aurora/config.php (emptyDir php-tmp).
 *
 * Contrato con infra/k8s/base/deployment.yaml (contenedor php-fpm):
 *   DB_HOST, DB_PORT, DB_NAME, DB_USER   conexion via cloud-sql-proxy en 127.0.0.1:3306
 *   DB_PASSWORD=""                       autenticacion IAM (--auto-iam-authn): sin contrasena
 *   WP_ENVIRONMENT_TYPE                  production | staging | development | local
 *   WP_SECRET_DIR                        volumen del Secret Manager CSI driver
 *
 * Origen de secretos (AURORA_SECRETS_SOURCE, por defecto files):
 *   files -> archivos del CSI driver en WP_SECRET_DIR (o AURORA_SECRETS_DIR)
 *   gsm   -> API de Secret Manager con la identidad del pod; requiere GCP_PROJECT_ID
 *   env   -> variables de entorno; solo con WP_ENVIRONMENT_TYPE=local (docker compose)
 *
 * Secretos (nombre de archivo en files, id del secreto en gsm):
 *   AURORA_SECRET_AUTH_KEYS   (files: auth-keys)  JSON {"AUTH_KEY","SECURE_AUTH_KEY","LOGGED_IN_KEY","NONCE_KEY"}
 *   AURORA_SECRET_SALTS       (files: salts)      JSON {"AUTH_SALT","SECURE_AUTH_SALT","LOGGED_IN_SALT","NONCE_SALT"}
 *   AURORA_SECRET_DB_PASSWORD (opcional)          solo si la BD usa contrasena en vez de IAM
 *
 * Opcionales: WP_HOME, WP_SITEURL (si faltan, WordPress usa las URLs guardadas en la BD),
 *   WP_TABLE_PREFIX (aur_), FORCE_SSL_ADMIN, AURORA_BLOCK_EXTERNAL, AURORA_ACCESSIBLE_HOSTS,
 *   DISABLE_WP_CRON.
 */

declare(strict_types=1);

const KEY_NAMES  = ['AUTH_KEY', 'SECURE_AUTH_KEY', 'LOGGED_IN_KEY', 'NONCE_KEY'];
const SALT_NAMES = ['AUTH_SALT', 'SECURE_AUTH_SALT', 'LOGGED_IN_SALT', 'NONCE_SALT'];
const ENV_TYPES  = ['local', 'development', 'staging', 'production'];
const OUT_DIRS   = ['/run/aurora', '/tmp/aurora'];

function info(string $msg): void
{
    fwrite(STDERR, "[aurora-config] {$msg}\n");
}

function fail(string $msg): never
{
    fwrite(STDERR, "[aurora-config] ERROR: {$msg}\n");
    exit(1);
}

function env_req(string $name): string
{
    $v = getenv($name);
    if ($v === false || trim($v) === '') {
        fail("falta la variable {$name}");
    }
    return $v;
}

function env_opt(string $name, string $default = ''): string
{
    $v = getenv($name);
    return ($v === false || trim($v) === '') ? $default : $v;
}

function env_bool(string $name, bool $default): bool
{
    $v = getenv($name);
    if ($v === false || $v === '') {
        return $default;
    }
    return in_array(strtolower($v), ['1', 'true', 'yes', 'on'], true);
}

function check_url(string $name, string $url): string
{
    $url = rtrim($url, '/');
    if (!filter_var($url, FILTER_VALIDATE_URL) || !preg_match('#^https?://#', $url)) {
        fail("{$name} no es una URL http(s) valida");
    }
    return $url;
}

function check_secret_name(string $secret): void
{
    if (!preg_match('/^[A-Za-z0-9_-]{1,255}$/', $secret)) {
        fail("nombre de secreto invalido: {$secret}");
    }
}

function http_get(string $url, array $headers): string
{
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_FOLLOWLOCATION => false,
    ]);
    $body = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    $err  = curl_error($ch);
    curl_close($ch);
    if ($body === false || $code !== 200) {
        // No se imprime el cuerpo: podria contener datos sensibles
        fail("peticion fallida a " . parse_url($url, PHP_URL_HOST) . " (HTTP {$code}) {$err}");
    }
    return (string) $body;
}

function file_secret(string $dir, string $secret): string
{
    check_secret_name($secret);
    $path = rtrim($dir, '/') . '/' . $secret;
    $raw  = is_readable($path) ? file_get_contents($path) : false;
    // Los archivos suelen terminar en salto de linea; no forma parte del secreto
    $raw = $raw === false ? '' : rtrim($raw, "\r\n");
    if ($raw === '') {
        fail("secreto vacio o ilegible: {$path} (¿tiene version cargada en Secret Manager?)");
    }
    return $raw;
}

function gsm_token(): string
{
    $json = http_get(
        'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
        ['Metadata-Flavor: Google']
    );
    $data = json_decode($json, true);
    if (!is_array($data) || empty($data['access_token'])) {
        fail('respuesta invalida del metadata server');
    }
    return $data['access_token'];
}

function gsm_secret(string $project, string $secret, string $token): string
{
    check_secret_name($secret);
    $url = sprintf(
        'https://secretmanager.googleapis.com/v1/projects/%s/secrets/%s/versions/latest:access',
        rawurlencode($project),
        rawurlencode($secret)
    );
    $data = json_decode(http_get($url, ["Authorization: Bearer {$token}"]), true);
    $raw  = is_array($data) ? base64_decode($data['payload']['data'] ?? '', true) : false;
    if ($raw === false || $raw === '') {
        fail("secreto vacio o ilegible: {$secret}");
    }
    return $raw;
}

function json_keys(string $json, array $names, string $secret): array
{
    $data = json_decode($json, true);
    if (!is_array($data)) {
        fail("el secreto {$secret} no es JSON valido");
    }
    $out = [];
    foreach ($names as $n) {
        if (empty($data[$n]) || !is_string($data[$n])) {
            fail("el secreto {$secret} no tiene {$n}");
        }
        $out[$n] = $data[$n];
    }
    return $out;
}

function write_config(array $config): string
{
    $php = "<?php\n// Generado por generate-config.php al arrancar. No editar.\nreturn "
         . var_export($config, true) . ";\n";
    foreach (OUT_DIRS as $dir) {
        if (!is_dir($dir) && !@mkdir($dir, 0700, true)) {
            continue;
        }
        $out = "{$dir}/config.php";
        $tmp = "{$out}.tmp";
        // Escritura atomica, solo legible por el usuario del proceso (10001)
        if (@file_put_contents($tmp, $php, LOCK_EX) !== false && chmod($tmp, 0400) && rename($tmp, $out)) {
            return $out;
        }
        @unlink($tmp);
    }
    fail('no hay directorio escribible para la configuracion (' . implode(', ', OUT_DIRS) . ')');
}

// ---------------------------------------------------------------------------

$envType = env_opt('WP_ENVIRONMENT_TYPE', env_opt('AURORA_ENV', 'production'));
if (!in_array($envType, ENV_TYPES, true)) {
    fail('WP_ENVIRONMENT_TYPE debe ser uno de: ' . implode(', ', ENV_TYPES));
}
$isLocal = $envType === 'local';
$source  = env_opt('AURORA_SECRETS_SOURCE', 'files');

$prefix = env_opt('WP_TABLE_PREFIX', 'aur_');
if (!preg_match('/^[A-Za-z0-9_]{1,20}$/', $prefix)) {
    fail('WP_TABLE_PREFIX solo admite letras, numeros y guion bajo');
}

// DB_HOST y DB_PORT por separado (deployment) o juntos "host:puerto"
$dbHost = env_req('DB_HOST');
$dbPort = env_opt('DB_PORT');
if ($dbPort !== '') {
    if (!ctype_digit($dbPort)) {
        fail('DB_PORT debe ser numerico');
    }
    if (!str_contains($dbHost, ':')) {
        $dbHost .= ':' . $dbPort;
    }
}

$home    = env_opt('WP_HOME');
$siteurl = env_opt('WP_SITEURL', $home);

$config = [
    'WP_ENVIRONMENT_TYPE' => $envType,
    'DB_HOST'             => $dbHost,
    'DB_NAME'             => env_req('DB_NAME'),
    'DB_USER'             => env_req('DB_USER'),
    'DB_PASSWORD'         => (string) getenv('DB_PASSWORD'),
    'TABLE_PREFIX'        => $prefix,
    'WP_HOME'             => $home === '' ? '' : check_url('WP_HOME', $home),
    'WP_SITEURL'          => $siteurl === '' ? '' : check_url('WP_SITEURL', $siteurl),
    'FORCE_SSL_ADMIN'     => env_bool('FORCE_SSL_ADMIN', !$isLocal),
    'BLOCK_EXTERNAL'      => env_bool('AURORA_BLOCK_EXTERNAL', true),
    'ACCESSIBLE_HOSTS'    => env_opt('AURORA_ACCESSIBLE_HOSTS'),
    'DISABLE_WP_CRON'     => env_bool('DISABLE_WP_CRON', false),
];

if ($source === 'env') {
    if (!$isLocal) {
        fail('AURORA_SECRETS_SOURCE=env solo se permite con WP_ENVIRONMENT_TYPE=local');
    }
    if ($config['DB_PASSWORD'] === '') {
        fail('en local se requiere DB_PASSWORD');
    }
    $generated = 0;
    foreach (array_merge(KEY_NAMES, SALT_NAMES) as $n) {
        $v = getenv($n);
        if ($v === false || $v === '') {
            $v = bin2hex(random_bytes(32));
            $generated++;
        }
        $config[$n] = $v;
    }
    if ($generated > 0) {
        info("{$generated} claves/salts generadas al azar (solo local; las sesiones se pierden al reiniciar)");
    }
    info('secretos tomados de variables de entorno (modo local)');
} elseif ($source === 'files' || $source === 'gsm') {
    if ($source === 'files') {
        $dir   = env_opt('AURORA_SECRETS_DIR', env_opt('WP_SECRET_DIR', '/var/run/aurorashop-secrets'));
        $sKeys = env_opt('AURORA_SECRET_AUTH_KEYS', 'auth-keys');
        $sSalt = env_opt('AURORA_SECRET_SALTS', 'salts');
        $read  = fn (string $s): string => file_secret($dir, $s);
        $where = "archivos en {$dir} (CSI driver)";
    } else {
        $project = env_req('GCP_PROJECT_ID');
        $sKeys   = env_req('AURORA_SECRET_AUTH_KEYS');
        $sSalt   = env_req('AURORA_SECRET_SALTS');
        $token   = gsm_token();
        $read    = fn (string $s): string => gsm_secret($project, $s, $token);
        $where   = "API de Secret Manager (proyecto {$project})";
    }

    $config += json_keys($read($sKeys), KEY_NAMES, $sKeys);
    $config += json_keys($read($sSalt), SALT_NAMES, $sSalt);

    $sPass = env_opt('AURORA_SECRET_DB_PASSWORD');
    if ($sPass !== '') {
        $config['DB_PASSWORD'] = $read($sPass);
    }
    $dbAuth = $config['DB_PASSWORD'] === '' ? 'IAM (sin contrasena, via cloud-sql-proxy)' : 'contrasena';
    info("secretos leidos de {$where}: {$sKeys}, {$sSalt}; autenticacion BD: {$dbAuth}");
} else {
    fail("AURORA_SECRETS_SOURCE desconocido: {$source} (usa files, gsm o env)");
}

$out = write_config($config);
info("configuracion escrita en {$out} (entorno: {$envType})");
