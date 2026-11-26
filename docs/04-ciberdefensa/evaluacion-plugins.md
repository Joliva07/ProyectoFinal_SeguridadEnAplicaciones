# Evaluación de plugins y temas (3.4)

Dueño: **Horacio** · Insumo: `docs/03-devsecops/plugins-temas.md` · Issue #48 · Fecha de corte: 2026-11-25

## 1. Método

1. Inventario real desde el contenedor PHP de la imagen (`get_plugins()`, `get_mu_plugins()`, `wp_get_themes()`), equivalente a `wp plugin list` / `wp theme list`. La imagen no trae WP-CLI a propósito.
2. WPScan en el pipeline (`security-ci.yml`, job *SCA · WPScan live inventory*) contra la tienda en vivo, con token API y umbral CVSS ≥ 7 (`.github/scripts/wpscan-threshold.py`).
3. Correlación con la base pública WPVulnerability (agrega CVE, Wordfence y Patchstack) y con la API de wordpress.org para la última versión publicada.
4. Revisión de código del plugin propio (`aurora-hardening.php`): Semgrep en CI + lectura dirigida con la lista del §3.
5. Prueba de explotación: no aplica; ningún CVE afecta a las versiones instaladas (ver §2).
6. Decisión por componente: mantener, actualizar, reemplazar o eliminar.

## 2. Tabla de resultados

| Plugin / tema | Versión | Última publicada | CVE / hallazgo | CVSS | Alcanzable | Prueba | Decisión | Evidencia |
|---|---|---|---|---|---|---|---|---|
| WordPress (núcleo) | 7.1.5 | 7.1.5 | Ninguno registrado para 7.1.5 | — | — | No aplica | Mantener | EV-48-01, EV-48-02 |
| WooCommerce | 11.3.1 | 11.3.1 | 101 vulnerabilidades históricas (32 CVE), **0 afectan a 11.3.1**. Las más recientes ya corregidas: CVE-2026-125801 (< 11.3.0), CVE-2026-106608 (9.8.0 – < 11.2.0), CVE-2026-48888 (< 11.1.0) | 6.5 / 7.2 / 7.5 (corregidas) | Sí, la Store API (`/wp-json/wc/store/*`) y el checkout son públicos; por eso se exige estar en la última versión | No aplica | Mantener; actualizar por PR al salir una versión nueva | EV-48-01, EV-48-02 |
| Two Factor (must-use) | 0.17.0 | 0.17.0 | 1 histórica: CVE-2026-100508 (< 0.17.0), consumo de recursos sin límite (CWE-770), **ya corregida en 0.17.0** | 5.3 (corregida) | El formulario de 2FA es público tras la contraseña | No aplica | Mantener | EV-48-01, EV-48-02 |
| Twenty Twenty-Five (tema activo) | 1.5 | 1.5 | Ninguno registrado | — | — | No aplica | Mantener | EV-48-01, EV-48-02 |
| `aurora-hardening.php` (plugin propio, must-use) | repo | — | Sin hallazgos de Semgrep; revisión manual en §3 | — | Sí: login, REST y `?author=` | Pruebas de #44 | Mantener | `evidencias/fase2/hardening-cms-2026-11-25.md` |
| Akismet | (imagen oficial) | — | No se usa (sin clave ni formularios de comentarios) | — | — | — | **Eliminado** en el `Dockerfile` | EV-48-03 |
| Hello Dolly | (imagen oficial) | — | Plugin de ejemplo sin función | — | — | — | **Eliminado** | EV-48-03 |
| Twenty Twenty-Three y Twenty Twenty-Four | (imagen oficial) | — | Inactivos, pero alcanzables por URL y enumerables | — | Sí (archivos estáticos) | — | **Eliminados** | EV-48-03 |

**Dependencias empaquetadas en WooCommerce:** 20 paquetes Composer (Jetpack *connection/status/assets…*, `maxmind-db/reader` 1.12.1, `opis/json-schema` 2.6.0, `woocommerce/action-scheduler` 4.1.0, entre otros). Viajan dentro del zip verificado por SHA-256 y Trivy los inventaría en el escaneo de la imagen (job *Container scan*).

## 3. Revisión de código del plugin propio

Archivo: `cms/docker/wordpress/mu-plugins/aurora-hardening.php` (226 líneas, issue #44).

| Punto | Qué se busca | Resultado |
|---|---|---|
| Registro de endpoints | `register_rest_route` con `permission_callback` | No registra endpoints. Solo restringe los existentes (`rest_pre_dispatch`, `rest_authentication_errors`) |
| Capacidades | `current_user_can` antes de mutar datos | No muta datos de negocio. Decide quién es "personal" con `user_can(manage_options / manage_woocommerce)` y la lista de usuarios por REST exige `edit_posts` |
| Nonces | `wp_verify_nonce` en formularios y AJAX | No agrega formularios. El de "olvidé mi contraseña" reutiliza `retrieve_password()` del núcleo, que tampoco usa nonce; el flujo lo limita el `limit_req` de Nginx en `/wp-login.php` |
| SQL | `$wpdb->prepare` en toda consulta | Sin SQL directo. Usa la API de transients y opciones |
| Salida | `esc_html` / `esc_attr` / `wp_kses_post` | La única salida es un aviso con texto fijo, sin datos del usuario. No hay nada que escapar |
| Subidas | validación MIME, tamaño y destino | Restringe tipos con `upload_mimes` (JPG, PNG, GIF, WebP, PDF, CSV). El tamaño lo limita PHP y Nginx no ejecuta nada dentro de `uploads/` |
| Serialización | sin `unserialize` de entrada de usuario | Sin `unserialize`, `eval`, `base64_decode` ni ejecución de comandos |
| Entrada | superglobales saneadas | 3 lecturas: `REMOTE_ADDR` (se hashea, nunca se imprime), `REQUEST_METHOD` (solo se compara) y `isset($_GET['author'])` (solo existencia) |

**Observaciones (riesgo bajo, aceptadas):**

- El bloqueo de login se cuenta por **usuario + IP**. Un atacante que rote IP no queda limitado por esta capa; lo cubren el rate limit de Nginx (10 por minuto por IP, ráfaga de 5) y el WAF de Cloudflare. A cambio, un atacante **no puede bloquear** a un usuario legítimo que entra desde otra IP.
- La IP sale de `CF-Connecting-IP`, y Nginx solo la acepta de los rangos del balanceador de Google (`set_real_ip_from 35.191.0.0/16, 130.211.0.0/22`), así que no se puede falsificar desde fuera.

**Tema hijo:** el plan prevé `aurora-child`, pero **todavía no existe** en el repositorio. La tienda usa Twenty Twenty-Five sin modificar. Si se crea, debe pasar la misma lista del §3 antes de entrar a la imagen.

## 4. Riesgo de cadena de suministro

- Los plugins **no se instalan desde el panel**: `DISALLOW_FILE_MODS` lo impide (prueba en #44: *"Sorry, you are not allowed to access this page"*). Entran solo con la imagen.
- Cada zip se descarga de `downloads.wordpress.org` por HTTPS con versión fija y **SHA-256 fijado** en el `Dockerfile`. Si el zip cambia, el build falla.
- El código es de solo lectura en el pod (propiedad de root, proceso con UID 10001).
- Cada actualización pasa por WPScan y Trivy en el PR antes de llegar a `demo`.
- Ningún componente está abandonado: WooCommerce se actualizó el 2026-11-19 (7 M de instalaciones), Two Factor el 2026-09-28 (100 k) y Twenty Twenty-Five el 2026-05-20.

## 5. Salida para el informe

- **Superficie de terceros:** 1 plugin normal (WooCommerce), 1 plugin must-use de terceros (Two Factor), 1 tema. Más el plugin propio de hardening.
- **Con CVE que afecten a la versión instalada:** 0 de 4. Todos los componentes están en la **última versión publicada**.
- **Eliminados:** Akismet, Hello Dolly y los temas por defecto inactivos, por no tener uso demostrable.
- **No admitidos:** los plugins de pagos, envíos, antispam, SEO, caché y backup que contemplaba el plan. La demo usa los métodos de pago y envío del propio WooCommerce. Turnstile se aplica en el borde (Cloudflare), no como plugin.

## Evidencias

| ID | Qué es | Dónde |
|---|---|---|
| EV-48-01 | Inventario desde el contenedor | `evidencias/fase2/plugins-temas-2026-11-25.md` §1 |
| EV-48-02 | Correlación de CVE y últimas versiones | `evidencias/fase2/plugins-temas-2026-11-25.md` §2 |
| EV-48-03 | Eliminación en la imagen | `cms/docker/Dockerfile`, etapa `app` |
| EV-48-04 | WPScan del pipeline (umbral CVSS ≥ 7 superado) | Run `45750237868` de `security-ci.yml`, artefacto del job WPScan |
