# Pruebas de borde — 2026-11-25

Hosts definitivos (Cloudflare Free no emite edge cert para dos niveles):

- `aurorashop.ancordss.me.uk` → `34.8.197.115`
- `admin-aurorashop.ancordss.me.uk` → `34.8.197.115`
- `staging-aurorashop.ancordss.me.uk` → `136.68.90.143`

Certificado Origin CA con SANs de los tres hosts, válido hasta 2041, instalado como `aurorashop-origin-tls` en `aurorashop` y `staging`.

## Resultados

| Prueba | Comando | Resultado |
|---|---|---|
| Edge storefront | `curl https://aurorashop.ancordss.me.uk/` | 200 |
| Edge admin | `curl https://admin-aurorashop.ancordss.me.uk/` | 200 |
| Origen directo demo | `curl -k --resolve ...:443:34.8.197.115` | 403 Cloud Armor |
| Origen directo staging | `curl -k --resolve ...:443:136.68.90.143` | 403 Cloud Armor |
| XML-RPC | `curl .../xmlrpc.php` | 403 WAF |
| Enumeración REST | `curl .../wp-json/wp/v2/users` | 403 WAF |
| Archivo sensible | `curl .../.env` | 403 WAF |
| PHP en uploads | `curl .../wp-content/uploads/x.php` | 403 WAF |
| Editor de plugins | `curl .../wp-admin/plugin-editor.php` | 403 WAF |
| Rate limit login | 3 GET a `/wp-login.php` en <10 s | 502, 502, **429** |
| Método TRACE | `curl -X TRACE .../` | 405 (bloqueado por el edge) |
| Staging XML-RPC | `curl https://staging-aurorashop.../xmlrpc.php` | 403 WAF (sin backend) |

WAF custom (5 reglas) y Cloudflare Managed Free Ruleset habilitados el 2026-11-25, acotados por `http.host` a los tres nombres.

El 200 se obtuvo con un Deployment temporal `edge-smoke` (nginx, `/healthz` 200) porque la imagen real del CMS aún no existe (#40). Se retiró después de las pruebas; sin backend, el origen devuelve 502.
