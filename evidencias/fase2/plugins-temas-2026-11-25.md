# Evidencia: inventario y CVE de plugins y temas (#48)

Fecha: 2026-11-25 · Responsable: Horacio · Imagen: `cms/docker/Dockerfile` en `main` (`5c139bb`)

## 1. Inventario (EV-48-01)

Ejecutado dentro del contenedor PHP (la imagen no trae WP-CLI):

```sh
docker compose exec -T php php -r '
  define("WP_USE_THEMES", false); require "/var/www/html/wp-load.php";
  require_once ABSPATH . "wp-admin/includes/plugin.php";
  // get_plugins(), get_mu_plugins(), wp_get_themes(), get_dropins()'
```

```text
core: WordPress 7.1.5 | PHP 8.3.37
--- plugins (wp-content/plugins)
woocommerce/woocommerce.php      11.3.1     ACTIVO   autor=Automattic
--- must-use (wp-content/mu-plugins)
00-aurora-two-factor.php
aurora-hardening.php
  two-factor (cargado por mu): 0.17.0
--- temas
twentytwentyfive     1.5      ACTIVO
--- dropins: 0
```

Dependencias Composer empaquetadas en WooCommerce (`vendor/composer/installed.json`): 20 paquetes, entre ellos `automattic/jetpack-connection` 6.19.2, `maxmind-db/reader` 1.12.1, `opis/json-schema` 2.6.0, `woocommerce/action-scheduler` 4.1.0 y `woocommerce/email-editor` 2.19.0.

La imagen oficial `wordpress:7.1.5-php8.3-fpm-alpine` trae además `akismet`, `hello.php`, `twentytwentythree` y `twentytwentyfour`. El `Dockerfile` los elimina en la etapa `app` (EV-48-03).

## 2. Correlación de CVE y versiones (EV-48-02)

Fuentes: API pública de WPVulnerability (`https://www.wpvulnerability.net/{core,plugin,theme}/<slug>/`) y API de wordpress.org (`api.wordpress.org/plugins/info/1.2/`). Se cruzó el rango afectado de cada vulnerabilidad con la versión instalada.

| Componente | Instalada | Última | Vulnerabilidades históricas | Afectan a la instalada |
|---|---|---|---|---|
| WordPress | 7.1.5 | 7.1.5 | 0 | 0 |
| WooCommerce | 11.3.1 | 11.3.1 | 101 (32 CVE); la más reciente corregida en < 11.3.0 | **0** |
| Two Factor | 0.17.0 | 0.17.0 | 1: CVE-2026-100508, CVSS 5.3, CWE-770, corregida en 0.17.0 | **0** |
| Twenty Twenty-Five | 1.5 | 1.5 | 0 | 0 |

Las 3 vulnerabilidades más recientes de WooCommerce, todas corregidas antes de 11.3.1:

| CVE | Rango afectado | CVSS |
|---|---|---|
| CVE-2026-125801 | 11.0.0 – < 11.3.0 | 6.5 |
| CVE-2026-106608 | 9.8.0 – < 11.2.0 | 7.2 |
| CVE-2026-48888 | < 11.1.0 | 7.5 |

## 3. WPScan del pipeline (EV-48-04)

Run `45750237868` de `security-ci.yml` (merge del PR #67): el job *SCA · WPScan live inventory* terminó en verde con el umbral CVSS ≥ 7 de `.github/scripts/wpscan-threshold.py`. El reporte `wpscan.json` queda como artefacto del run.
