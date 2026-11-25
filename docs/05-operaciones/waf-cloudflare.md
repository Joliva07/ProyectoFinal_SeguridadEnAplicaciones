# WAF y controles de borde

Especifica: **Arun** · Aplica: **James** (único con Cloudflare) · Componente de rúbrica 4

> Integración con GKE (DNS, Origin CA, Access, Logpush, IP real): [`integracion-cloudflare-gke.md`](integracion-cloudflare-gke.md).

## 1. Capas

| Capa | Producto | Función | Estado |
|---|---|---|---|
| 1 | Cloudflare Managed Free Ruleset | Payloads conocidos | **Activo** (2026-11-25) |
| 2 | Reglas custom Cloudflare | Lógica de WordPress/WooCommerce | **5 reglas activas** |
| 3 | Rate limiting | Fuerza bruta, card testing, scraping | **Activo**: 1 regla Free (login 2/10s) |
| 4 | Bot management / Turnstile | Automatización en login y checkout | Pendiente: configurar en dashboard |
| 5 | Cloud Armor | Segunda línea en el LB | **Activo**: 403 a origen directo |
| 6 | Cloudflare Access | Admin y staging fuera de Internet | Pendiente: token sin acceso a la organización Zero Trust |

### 1.1 Estado aplicado el 2026-11-25

La zona `ancordss.me.uk` (plan Free) tenía WAF apagado. El 2026-11-25 se habilitaron el entrypoint custom y el Managed Free Ruleset, acotados por `http.host` a los tres nombres de AuroraShop:

| Objeto | ID | Estado |
|---|---|---|
| Ruleset custom | `f9b9aafd842f45da8159d31757d5e3df` | W-01/W-11, W-03, W-04, W-05, W-06 `enabled=true` |
| Ruleset managed | `94b1cdbe2d234721aa23e13be15d359e` | Cloudflare Managed Free Ruleset `enabled=true` |
| Rate limit | `f571996e3b77469c8547cefa9f305cb1` | W-02 login 2 req/10 s por IP; bloqueo 10 s (límite Free) |

Pruebas: `/` 200 (backend temporal), `/xmlrpc.php` 403, `/wp-json/wp/v2/users` 403, `/.env` 403, uploads `.php` 403, editor de plugins 403; login 3.º request → 429; TRACE → 405. Evidencia en `evidencias/fase5/waf-2026-11-24/edge-tests.md`.

## 2. Reglas custom

| ID | Nombre | Expresión | Acción | Riesgo |
|---|---|---|---|---|
| W-01 | Bloquear XML-RPC y métodos no usados | `path eq "/xmlrpc.php" or method in {"TRACE" "TRACK" "CONNECT"}` | block | R-06/R-18 |
| W-02 | Proteger login | rate limit 2 req/10 s por IP | block 10 s | R-06 |
| W-03 | Bloquear enumeración REST | `http.request.uri.path contains "/wp-json/wp/v2/users"` | block | R-07 |
| W-04 | Bloquear archivos sensibles | `path contains "/.env" or "/.git" or ".sql" or "wp-config.php." or "debug.log"` | block | R-09 |
| W-05 | Sin PHP en uploads | `http.request.uri.path contains "/wp-content/uploads/" and http.request.uri.path contains ".php"` | block | R-08 |
| W-06 | Editor y mods de plugins | `path contains "/wp-admin/plugin-editor.php" or path contains "/wp-admin/theme-editor.php"` | block | R-04 |
| W-07 | Proteger checkout | `http.request.uri.path contains "/checkout" and rate(1m) > 5` | managed_challenge | R-16 |
| W-08 | Cuerpo grande en API | requiere `http.request.body.size` | no disponible en Free | R-15 |
| W-09 | Admin solo via Access | política de Cloudflare Access en `admin-aurorashop`; no expresable en WAF | block en Access | R-20 |
| W-10 | Scraping de catálogo | rate limit global | no implementado: 1 sola regla Free | R-16 |
| W-11 | Métodos no usados | incluida en W-01 | block | R-18 |
| W-12 | Exploits de plugins conocidos | reglas CRS + firmas de CVE en la ventana | block | R-01 |

En Free no existe la acción `log`; las reglas se validaron con un backend temporal y se activaron en `block`. El cambio queda registrado con fecha y resultado.

> Plan Free: **5 reglas custom**, sin acción `log`, sin regex, y **1 regla de rate limiting** con periodo y mitigación máximos de 10 s. W-04/W-06 usan `contains`; W-01 y W-11 comparten regla; W-02 usa la única regla de rate limit; W-08 requiere plan Advanced (`http.request.body.size`); W-07/W-10 no caben en la cuota; W-09 se resuelve con Access; W-12 usa el Managed Free Ruleset. El smoke test se hizo con un backend temporal `edge-smoke` (eliminado).

## 3. Rate limiting

| Ruta | Límite objetivo | Ventana | Acción | Estado |
|---|---|---|---|---|
| `/wp-login.php` | 10 | 1 min por IP | block 10 min | Implementado 2/10 s + block 10 s (límite Free) |
| `/xmlrpc.php` | 2 | 1 min | block | Cubierto por W-01 (block total) |
| `/checkout/*` | 5 | 1 min por IP | challenge + block | No implementado: 1 sola regla Free |
| `/wp-json/*` | 60 | 1 min por IP | challenge | No implementado: 1 sola regla Free |
| `/*` | 150 | 1 min por IP | challenge | No implementado: 1 sola regla Free |

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
