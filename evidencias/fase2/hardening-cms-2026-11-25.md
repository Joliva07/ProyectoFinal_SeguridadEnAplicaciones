# Hardening del CMS (issue #44) — 2026-11-25

Rama `fase2/horacio-hardening-cms`. "Antes" se midió desde internet contra `https://aurorashop.ancordss.me.uk`
(imagen del #40). "Después" se midió en local (`cms/docker/compose.yaml`) con la imagen nueva, misma
configuración que en GKE. Sin contraseñas ni secretos en este documento.

## Antes y después

| Control | Comando | Antes (demo) | Después |
|---|---|---|---|
| Versión en HTML | `curl -s / \| grep generator` | `WordPress 7.1.5`, `WooCommerce 11.3.1` | Sin `<meta generator>` |
| Versión en assets | `curl -s / \| grep -o '?ver=...'` | `?ver=7.1.5`, `?ver=11.3.1` | Token opaco (`?ver=17d65cfe6b`) |
| Versión en el feed | `curl -s /feed/ \| grep generator` | `wordpress.org/?v=7.1.5` | Sin versión |
| Enumeración por autor | `curl -I /?author=1` | `301 → /author/horacio-admin/` | `404` |
| Sitemap de usuarios | `curl -I /wp-sitemap-users-1.xml` | `200` | `404` |
| REST de usuarios | `curl -I /wp-json/wp/v2/users` | `403` (solo por el WAF) | `401` |
| REST por ruta alterna | `curl -I '/?rest_route=/wp/v2/users'` | **`200` (evade el WAF)** | `401` |
| oEmbed | `curl -s /wp-json/oembed/1.0/embed?url=/` | Incluye `author_name` | Sin autor |
| Mensaje de login | `POST /wp-login.php` con usuario inexistente / existente | "The username noexiste is not registered" / "The password for horacio-admin is incorrect" | "usuario o contraseña incorrectos" en ambos casos |
| Olvido de contraseña | `POST /wp-login.php?action=lostpassword` | Distinto si la cuenta existe | `302 → ?checkemail=confirm` siempre |
| Bloqueo por intentos | 5 fallos y luego la contraseña correcta | Sin bloqueo en WordPress (solo rate limit de Nginx) | Rechaza incluso la contraseña correcta durante 15 min (usuario + IP) |
| 2FA en personal | Login de administrador sin 2FA | Entra directo | Solo puede abrir su perfil hasta activar TOTP |
| 2FA en el login | Usuario con TOTP: usuario + clave | — | Pide código; sin cookie de sesión hasta validarlo; código incorrecto rechazado |
| Instalar plugins | `GET /wp-admin/plugin-install.php` (admin con 2FA) | Bloqueado (`DISALLOW_FILE_MODS`) | "Sorry, you are not allowed to access this page" |
| XML-RPC | `curl -I /xmlrpc.php` | `403` | `403` + `xmlrpc_enabled=false` + sin `X-Pingback` |
| Rutas inexistentes en plugins | `curl -I /wp-content/plugins/no-existe/` | `404` generado por WordPress (PHP + BD) | `404` de Nginx, sin PHP |
| Assets reales | `curl -I /wp-content/plugins/woocommerce/assets/css/woocommerce.css` | `200` | `200` |
| Tienda | `curl -I /shop/` | `200` | `200` |

## Qué se implementó

| Archivo | Control |
|---|---|
| `cms/docker/Dockerfile` | Two Factor 0.17.0 (plugin oficial) descargado con SHA-256 fijado e instalado como must-use |
| `cms/docker/wordpress/mu-plugins/00-aurora-two-factor.php` | Carga Two Factor; no se puede desactivar desde wp-admin |
| `cms/docker/wordpress/mu-plugins/aurora-hardening.php` | 2FA obligatorio (TOTP + códigos de respaldo) para `manage_options`/`manage_woocommerce`, también en REST; sin contraseñas de aplicación; login genérico y bloqueo 5 fallos/15 min; sin enumeración de usuarios; versiones ocultas; roles `author`/`contributor` eliminados; uploads limitados a JPG, PNG, GIF, WebP, PDF y CSV |
| `cms/docker/wordpress/wp-config.aurora.php` | `DISALLOW_UNFILTERED_HTML`: nadie guarda HTML/JS sin filtrar (XSS almacenado) |
| `cms/docker/nginx/aurora.conf` | `404` directo para rutas inexistentes en `plugins/`, `themes/` y `mu-plugins/` |

## Revisiones del pipeline (local, mismas versiones que `security-ci.yml`)

- Trivy `0.76.2`, `--severity CRITICAL --ignore-unfixed`: exit 0.
- Semgrep `1.186.0` (`p/php`, `p/owasp-top-ten`, `p/secrets`): 0 hallazgos.
- Tamaño: `cms-php` 388 MB, `cms-nginx` 336 MB.

## Hallazgo para el WAF (James)

`/?rest_route=/wp/v2/users` devolvía `200` con la lista de usuarios mientras `/wp-json/wp/v2/users` daba `403`:
la regla del WAF filtra la ruta, no el parámetro. Ya queda cerrado en WordPress, pero conviene que la regla
de Cloudflare también cubra `rest_route=/wp/v2/users`.

## Pendiente

- `wp-cron` por sistema: hoy corre el cron de WordPress en las visitas. Pasarlo a un `CronJob` de Kubernetes
  requiere reglas de NetworkPolicy para que el job alcance al Service (infra de Josue).
- Bajar a "Gestor de la tienda" la cuenta de Javier al terminar la carga del #36.
