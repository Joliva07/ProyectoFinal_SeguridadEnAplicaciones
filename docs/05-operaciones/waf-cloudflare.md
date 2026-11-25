# WAF y controles de borde

Especifica: **Arun** · Aplica: **James** (único con Cloudflare) · Componente de rúbrica 4

> Integración con GKE (DNS, Origin CA, Access, Logpush, IP real): [`integracion-cloudflare-gke.md`](integracion-cloudflare-gke.md).

## 1. Capas

| Capa | Producto | Función | Estado |
|---|---|---|---|
| 1 | Cloudflare Managed Free Ruleset | Payloads conocidos | **Staged, disabled** (2026-11-24) |
| 2 | Reglas custom Cloudflare | Lógica de WordPress/WooCommerce | **5 reglas staged, disabled** |
| 3 | Rate limiting | Fuerza bruta, card testing, scraping | Pendiente: token sin scope de rate limits |
| 4 | Bot management / Turnstile | Automatización en login y checkout | Pendiente: configurar en dashboard |
| 5 | Cloud Armor | Segunda línea en el LB | Pendiente: `terraform apply` |
| 6 | Cloudflare Access | Admin y staging fuera de Internet | Pendiente: token sin acceso a la organización Zero Trust |

### 1.1 Estado aplicado el 2026-11-24

La zona `ancordss.me.uk` (plan Free) tenía WAF apagado: sin entrypoint en `http_request_firewall_custom` ni `http_request_firewall_managed`. Se dejó preparado, **deshabilitado**, para no bloquear tráfico antes de que exista el origen y se validen falsos positivos:

| Objeto | ID | Reglas |
|---|---|---|
| Ruleset custom | `f9b9aafd842f45da8159d31757d5e3df` | W-01, W-03, W-04, W-05, W-06 (todas `enabled=false`) |
| Ruleset managed | `94b1cdbe2d234721aa23e13be15d359e` | Cloudflare Managed Free Ruleset (`enabled=false`) |

Ambos están limitados por expresión a `aurorashop.ancordss.me.uk`, `admin.aurorashop.ancordss.me.uk` y `staging.aurorashop.ancordss.me.uk`, para no afectar los otros 28 hosts de la zona. Al existir el Ingress y pasar el smoke test, se habilitan con `PATCH` del ruleset; no se activan antes.

## 2. Reglas custom

| ID | Nombre | Expresión | Acción | Riesgo |
|---|---|---|---|---|
| W-01 | Bloquear XML-RPC | `http.request.uri.path eq "/xmlrpc.php"` | block | R-06 |
| W-02 | Proteger login | `http.request.uri.path eq "/wp-login.php" and rate(1m) > 10` | block 10 min | R-06 |
| W-03 | Bloquear enumeración REST | `http.request.uri.path contains "/wp-json/wp/v2/users"` | block | R-07 |
| W-04 | Bloquear archivos sensibles | `path contains "/.env" or "/.git" or ".sql" or "wp-config.php." or "debug.log"` | block | R-09 |
| W-05 | Sin PHP en uploads | `http.request.uri.path contains "/wp-content/uploads/" and http.request.uri.path contains ".php"` | block | R-08 |
| W-06 | Editor y mods de plugins | `path contains "/wp-admin/plugin-editor.php" or path contains "/wp-admin/theme-editor.php"` | block | R-04 |
| W-07 | Proteger checkout | `http.request.uri.path contains "/checkout" and rate(1m) > 5` | managed_challenge | R-16 |
| W-08 | Cuerpo grande en API | `http.request.body.size > 1048576 and http.request.uri.path contains "/wp-json/"` | block | R-15 |
| W-09 | Admin solo via Access | política de Cloudflare Access en `admin.`; no expresable en WAF | block en Access | R-20 |
| W-10 | Scraping de catálogo | `rate(1m) > 120` | managed_challenge | R-16 |
| W-11 | Métodos no usados | `http.request.method in {"TRACE" "TRACK" "CONNECT"}` | block | R-18 |
| W-12 | Exploits de plugins conocidos | reglas CRS + firmas de CVE en la ventana | block | R-01 |

Toda regla arranca en **log** 24 h, se revisan falsos positivos y luego pasa a **block**. El cambio se registra con fecha y resultado.

> Plan Free: el límite es **5 reglas custom**, sin acción `log` y sin regex. W-04/W-06 se implementaron con `contains`; W-02/W-07/W-10 dependen de rate limiting (no staged); W-09 se resuelve con Access; W-11/W-12 quedan fuera de la cuota y del ruleset gratuito. Las reglas desplegadas se activan solo después del smoke test del origen.

## 3. Rate limiting

| Ruta | Límite | Ventana | Acción |
|---|---|---|---|
| `/wp-login.php` | 10 | 1 min por IP | block 10 min |
| `/xmlrpc.php` | 2 | 1 min | block |
| `/checkout/*` | 5 | 1 min por IP | challenge + block |
| `/wp-json/*` | 60 | 1 min por IP | challenge |
| `/*` | 150 | 1 min por IP | challenge |

## 4. Cabeceras y TLS

- HSTS `max-age=31536000; includeSubDomains` (preload al cierre).
- TLS mínimo 1.2, 1.3 activo, OCSP stapling; Full (strict).
- CSP del storefront: `default-src 'self'; frame-ancestors 'none'` (ajustar inline de WooCommerce o usar nonce).
- CORS: origen exacto; nunca `*` con credenciales.
- Eliminar `Server`, `X-Powered-By`, `X-Pingback`, `Link: <...wp-json...>`.
- Cloudflare Authenticated Origin Pull (mTLS) hacia el LB.

## 5. Pruebas de efectividad (obligatorias)

| Prueba | Comando / técnica | Antes | Después |
|---|---|---|---|
| XML-RPC | `curl -X POST .../xmlrpc.php -d '<methodCall/>'` | 200 | 403 |
| Fuerza bruta | 30 POST a `wp-login` | 30 × 200 | 429 desde el intento 11 |
| Enumeración | `GET /wp-json/wp/v2/users` | 200 con lista | 403 |
| Archivo sensible | `GET /.env`, `/wp-config.php.bak` | 200/500 | 403 |
| PHP en uploads | `GET /wp-content/uploads/x.php` | 200 | 403 |
| SQLi CRS | `?s=1' OR '1'='1` | 200 | 403 |
| Origen directo | `curl` al LB sin Host | 200 | 403 |
| Scraping | 200 GET a `/shop` | 200 todas | challenge/429 |

Cada fila con `curl -i` y fecha en `evidencias/fase5/waf-<fecha>/`.

## 6. Limitaciones declaradas

Cloudflare Free/Pro no incluye todas las reglas de bot management ni API Shield completo. Se documenta qué control es gratuito, cuál es propuesta de plan pago y cuál se compensa con Cloud Armor o lógica de aplicación. La caché se excluye de `wp-admin`, `wp-json`, `cart`, `checkout` y `my-account` para no servir datos de otro usuario.
