<?php
/**
 * Plugin Name: AuroraShop — carga de Two Factor (2FA)
 * Description: Carga el plugin oficial Two Factor como must-use: no aparece en Plugins ni se puede desactivar desde wp-admin (issue #44).
 *
 * El codigo de Two Factor viene fijado por version y SHA-256 en el Dockerfile (TWO_FACTOR_VERSION).
 * Las reglas de obligatoriedad estan en aurora-hardening.php.
 */

if (!defined('ABSPATH')) {
    exit;
}

$aurora_two_factor = __DIR__ . '/two-factor/two-factor.php';
if (is_readable($aurora_two_factor)) {
    require_once $aurora_two_factor;
}
unset($aurora_two_factor);
