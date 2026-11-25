# Estado de Cloudflare — 2026-11-25

Zona: `ancordss.me.uk` (`d7ab4dfd85ce67a4e3273ae07d402e8b`), plan **Free**, cuenta `1b45d5e5a5b93bb6e781126413b2b567`.
Token con permisos de DNS, WAF/rulesets, Logpush y Origin CA; sin Zone Settings ni administración de Zero Trust. No se registra el token.

## DNS

- 32 registros; los tres de AuroraShop son proxied: `aurorashop` y `admin-aurorashop` → `34.8.197.115`; `staging-aurorashop` → `136.68.90.143`.
- Los nombres anidados `admin.aurorashop` y `staging.aurorashop` se retiraron: Universal SSL de Free no cubre dos niveles.

## WAF

Entrypoint custom y Managed Free Ruleset **habilitados** el 2026-11-25:

| Objeto | ID | Detalle |
|---|---|---|
| Ruleset custom | `f9b9aafd842f45da8159d31757d5e3df` | W-01/W-03/W-04/W-05/W-06 `enabled=true` |
| Ruleset managed | `94b1cdbe2d234721aa23e13be15d359e` | Cloudflare Managed Free Ruleset `77454fe2…`; `enabled=true` |

Pruebas: `/` 200, `/xmlrpc.php` 403, `/wp-json/wp/v2/users` 403, `/.env` 403, uploads `.php` 403, editor de plugins 403. Detalle en `edge-tests.md`.

Limitaciones del plan Free: 5 reglas custom, sin acción `log`, sin regex. W-04/W-06 usan `contains`; W-02/W-07/W-10 dependen de rate limiting; W-09 se resuelve con Access; W-11/W-12 quedan fuera de la cuota o del ruleset gratuito.

## Access

- 0 aplicaciones.
- `GET /accounts/<id>/access/organizations`: `10000 Authentication error`; el token no administra Zero Trust.

## Logpush

- Ownership challenge validado (`result.valid=true`) sobre el bucket ya creado.
- `POST /logpush/jobs` devuelve `1004 logpush is not enabled for this account`: el plan Free no incluye Logpush. Bucket e IAM quedan listos; se declara limitación.

## Origen

- `GET /certificates?zone_id=…` funciona (0 certificados), pero `POST /certificates` devuelve `1016 User is not authorized`.
- Clave y CSR generados localmente en `~/.aurorashop-origin/` (permisos 600), con SANs de los tres hosts. El certificado se emite en el dashboard o con un token de Origin CA: Edit.
- Certbot 5.10 + plugin DNS de Cloudflare: `--dry-run` contra Let's Encrypt staging **exitoso** (DNS-01 resuelve y limpia TXT). La emisión real devuelve HTTP 503 `urn:ietf:params:acme:error:rateLimited` ("Service busy; retry later") en `/acme/authz/...`; hay que esperar la ventana de rate limit y reintentar.

## Bloqueos

1. Certificado Origin CA: se emite en el dashboard o con un token `Origin CA: Edit`. Sin él, Cloudflare responde 525/526.
2. Token con Zone Settings: Edit para SSL Full (strict), TLS 1.2/1.3 y HSTS.
3. Token con Access: Apps and Policies: Edit y la organización Zero Trust para `admin.` y `staging.`.
4. Logpush: requiere plan con Logs (el Free devuelve `1004`).

## Estado del origen

`terraform apply` completó GKE/Cloud SQL/buckets/Cloud Armor. Con el cert Origin CA y los Ingress nuevos, el borde responde: `/` 200 con el backend temporal, WAF 403 en las rutas bloqueadas y 403 de Cloud Armor al origen directo. Los Deployments reales vuelven a estar aplicados pero no arrancan hasta que existan las imágenes de #40 y versiones en Secret Manager.
