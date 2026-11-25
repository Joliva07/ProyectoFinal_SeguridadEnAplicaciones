<?php
/**
 * AuroraShop — genera /run/aurora/config.php al arrancar el contenedor (issue #40).
 *
 * wp-config.php (versionado, sin secretos) lee ese archivo. Los secretos nunca quedan
 * en la imagen ni en el repositorio.
 *
 * Origen de secretos (AURORA_SECRETS_SOURCE):
 *   env   -> variables de entorno (solo pruebas locales con docker compose, AURORA_ENV=local)
 *   files -> archivos montados por el Secret Manager CSI driver en GKE (un archivo por secreto)
 *   gsm   -> API de Secret Manager con la identidad del pod (Workload Identity, sin claves JSON)
 *
 * Variables no secretas (ConfigMap en GKE / compose en local):
 *   DB_HOST, DB_NAME, DB_USER, WP_HOME, [WP_SITEURL], [WP_TABLE_PREFIX], [AURORA_ENV],
 *   [FORCE_SSL_ADMIN], [AURORA_BLOCK_EXTERNAL], [AURORA_ACCESSIBLE_HOSTS], [DISABLE_WP_CRON]
 *
 * Nombres de secretos (modos files y gsm; por defecto con prefijo aurorashop-, que es lo
 * que permite el IAM de sa-gke-workload segun la arquitectura):
 *   [GSM_SECRET_DB_PASSWORD=aurorashop-db-password]
 *   [GSM_SECRET_AUTH_KEYS=aurorashop-auth-keys]   JSON {"AUTH_KEY":"...","SECURE_AUTH_KEY":"...","LOGGED_IN_KEY":"...","NONCE_KEY":"..."}
 *   [GSM_SECRET_SALTS=aurorashop-salts]           JSON {"AUTH_SALT":"...","SECURE_AUTH_SALT":"...","LOGGED_IN_SALT":"...","NONCE_SALT":"..."}
 * Solo files: [AURORA_SECRETS_DIR=/var/secrets/aurora]  (mountPath del volumen CSI)
 * Solo gsm:   GCP_PROJECT_ID
 */

declare(strict_types=1);

const KEY_NAMES  = ['AUTH_KEY', 'SECURE_AUTH_KEY', 'LOGGED_IN_KEY', 'NONCE_KEY'];
const SALT_NAMES = ['AUTH_SALT', 'SECURE_AUTH_SALT', 'LOGGED_IN_SALT', 'NONCE_SALT'];

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

function env_opt(string $name, string $default): string
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

function check_secret_name(string $secret): void
{
    if (!preg_match('/^[A-Za-z0-9_-]{1,255}$/', $secret)) {
        fail("nombre de secreto invalido: {$secret}");
    }
}

function file_secret(string $dir, string $secret): string
{
    check_secret_name($secret);
    $path = rtrim($dir, '/') . '/' . $secret;
    $raw  = is_readable($path) ? file_get_contents($path) : false;
    // Los archivos suelen terminar en salto de linea; no forma parte del secreto
    $raw = $raw === false ? '' : rtrim($raw, "\r\n");
    if ($raw === '') {
        fail("secreto vacio o ilegible: {$path}");
    }
    return $raw;
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

// ---------------------------------------------------------------------------

$env    = env_opt('AURORA_ENV', 'production');
$source = env_opt('AURORA_SECRETS_SOURCE', 'gsm');
$out    = '/run/aurora/config.php';

$prefix = env_opt('WP_TABLE_PREFIX', 'aur_');
if (!preg_match('/^[A-Za-z0-9_]{1,20}$/', $prefix)) {
    fail('WP_TABLE_PREFIX solo admite letras, numeros y guion bajo');
}

$home = rtrim(env_req('WP_HOME'), '/');
if (!filter_var($home, FILTER_VALIDATE_URL)) {
    fail('WP_HOME no es una URL valida');
}

$config = [
    'AURORA_ENV'          => $env,
    'DB_HOST'             => env_req('DB_HOST'),
    'DB_NAME'             => env_req('DB_NAME'),
    'DB_USER'             => env_req('DB_USER'),
    'TABLE_PREFIX'        => $prefix,
    'WP_HOME'             => $home,
    'WP_SITEURL'          => rtrim(env_opt('WP_SITEURL', $home), '/'),
    'FORCE_SSL_ADMIN'     => env_bool('FORCE_SSL_ADMIN', $env !== 'local'),
    'BLOCK_EXTERNAL'      => env_bool('AURORA_BLOCK_EXTERNAL', true),
    'ACCESSIBLE_HOSTS'    => env_opt('AURORA_ACCESSIBLE_HOSTS', ''),
    'DISABLE_WP_CRON'     => env_bool('DISABLE_WP_CRON', false),
];

if ($source === 'env') {
    if ($env !== 'local') {
        fail('AURORA_SECRETS_SOURCE=env solo se permite con AURORA_ENV=local');
    }
    $config['DB_PASSWORD'] = env_req('DB_PASSWORD');
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
    $sPass  = env_opt('GSM_SECRET_DB_PASSWORD', 'aurorashop-db-password');
    $sKeys  = env_opt('GSM_SECRET_AUTH_KEYS', 'aurorashop-auth-keys');
    $sSalts = env_opt('GSM_SECRET_SALTS', 'aurorashop-salts');

    if ($source === 'files') {
        $dir   = env_opt('AURORA_SECRETS_DIR', '/var/secrets/aurora');
        $read  = fn (string $s): string => file_secret($dir, $s);
        $where = "archivos en {$dir} (CSI driver)";
    } else {
        $project = env_req('GCP_PROJECT_ID');
        $token   = gsm_token();
        $read    = fn (string $s): string => gsm_secret($project, $s, $token);
        $where   = "API de Secret Manager (proyecto {$project})";
    }

    $config['DB_PASSWORD'] = $read($sPass);
    $config += json_keys($read($sKeys), KEY_NAMES, $sKeys);
    $config += json_keys($read($sSalts), SALT_NAMES, $sSalts);
    info("secretos leidos de {$where}: {$sPass}, {$sKeys}, {$sSalts}");
} else {
    fail("AURORA_SECRETS_SOURCE desconocido: {$source} (usa env, files o gsm)");
}

// Escritura atomica, solo legible por el usuario del proceso (10001)
$tmp = $out . '.tmp';
$php = "<?php\n// Generado por generate-config.php al arrancar. No editar.\nreturn "
     . var_export($config, true) . ";\n";
if (file_put_contents($tmp, $php, LOCK_EX) === false || !chmod($tmp, 0400) || !rename($tmp, $out)) {
    fail("no se pudo escribir {$out}");
}
info("configuracion escrita en {$out} (entorno: {$env})");
