# WAF y controles de borde

Especifica: **Arun** · Aplica: **James** (único con acceso a Cloudflare) · Componente de rúbrica 4

## 1. Capas de protección

| Capa | Producto | Función | Estado |
|---|---|---|---|
| 1 | Cloudflare WAF + Managed Rules (OWASP Core) | Bloqueo de payloads conocidos | por aplicar |
| 2 | Reglas custom Cloudflare | Lógica propia del negocio | por aplicar |
| 3 | Rate limiting | Fuerza bruta y abuso | por aplicar |
| 4 | Bot management / Turnstile | Automatización | por aplicar |
| 5 | Cloud Armor (GCP) | Segunda línea y geo/rate por backend | por aplicar |
| 6 | Cloudflare Access | Admin fuera de Internet | por aplicar |

## 2. Reglas custom propuestas

| ID | Nombre | Expresión | Acción | Riesgo que mitiga |
|---|---|---|---|---|
| W-01 | Bloquear métodos no usados | `http.request.method in {"TRACE" "TRACK" "CONNECT"}` | block | R-06, fingerprinting |
| W-02 | Bloquear paths de archivos | `http.request.uri.path matches "(?i)(\\.env|\\.git|\\.htaccess|\\.bak|\\.sql)$"` | block | R-08 |
| W-03 | Login sin UA | `http.request.uri.path eq "/v1/auth/login" and not http.user_agent contains "FinanciaWeb"` | managed_challenge | AC-02 |
| W-04 | Forcejeo de auth | `http.request.uri.path contains "/v1/auth/" and rate(1m) > 10` | block por 10 min | AC-02 |
| W-05 | Paginación abusiva | `http.request.uri.query contains "limit=" and http.request.uri.query matches "(?i)limit=(1[0-9]{2,}|[5-9][0-9])"` | block | AC-01 |
| W-06 | Escaneo de rutas admin desde clientes | `http.request.uri.path contains "/v1/admin/" and ip.geoip.country ne "GT"` | block | AC-08 (ajustar a realidad) |
| W-07 | Cuerpo grande en API | `http.request.body.size > 1048576 and http.request.uri.path contains "/v1/"` | block | R-07 |
| W-08 | SQLi/XSS gestionadas | OWASP Core Ruleset, paranoia 2 | managed_challenge | R-01, R-06 |
| W-09 | Proteger `admin` | Access + `not cf.access` | block | R-16 |
| W-10 | Bloqueo de ASN de hosting | lista editable | managed_challenge | AC-02 |

Toda regla se activa primero en **log** 24 h, se revisan falsos positivos, y luego pasa a **block**. La tabla de cambios registra fecha, quien aplicó y resultado.

## 3. Rate limiting

| Ruta | Límite | Ventana | Acción al exceder |
|---|---|---|---|
| `api.*/v1/auth/*` | 10 req | 1 min por IP | block 10 min |
| `api.*/v1/transfers` | 5 req | 1 min por usuario | block 1 min + alerta |
| `api.*/*` | 100 req | 1 min por IP | managed_challenge |
| `financiaweb.*` | 300 req | 1 min por IP | managed_challenge |

## 4. Cabeceras y TLS

- HSTS: `max-age=31536000; includeSubDomains` (preload al cierre).
- TLS mínimo 1.2, 1.3 activo, cifrados modernos, OCSP stapling.
- `Server` y `X-Powered-By` eliminados en origen.
- CSP en el portal: `default-src 'self'; frame-ancestors 'none'`.
- CORS: origen exacto `https://financiaweb.ancordss.me.uk`; nunca `*` con credenciales.
- Authenticated Origin Pull / restricción a rangos de Cloudflare en el LB.

## 5. Prueba de efectividad (obligatoria)

| Prueba | Comando / técnica | Antes | Después |
|---|---|---|---|
| SQLi básica | `curl ".../v1/accounts?id=1' OR '1'='1"` | 200 con error | 403 de Cloudflare |
| XSS reflejado | `?q=<script>alert(1)</script>` | reflejado | 403 |
| Path traversal | `/../../.env` | 200/500 | 403 |
| Fuerza bruta | 30 intentos de login | 30 × 401 | 429/403 desde el intento 11 |
| Paginación | `?limit=5000` | 5000 registros | 403 |
| Origen directo | `curl https://*.run.app` | 200 | 403 |

Cada fila se captura con `curl -i` y fecha; va a `evidencias/fase5/waf-<fecha>/`.

## 6. Limitaciones declaradas

Cloudflare Free/Pro no incluye algunas reglas avanzadas (p. ej. ciertas de bot management y API Shield completas). Se documenta qué control es gratuito y cuál es propuesta de nivel pago, sin presentar como implementado lo que no lo está.
