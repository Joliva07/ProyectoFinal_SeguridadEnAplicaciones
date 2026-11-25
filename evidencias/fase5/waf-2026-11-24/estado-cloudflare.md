# Estado de Cloudflare — 2026-11-24

Zona: `ancordss.me.uk` (`d7ab4dfd85ce67a4e3273ae07d402e8b`), plan **Free**, cuenta `1b45d5e5a5b93bb6e781126413b2b567`.
Token con permisos de DNS, WAF/rulesets, Logpush y Access (lectura); sin Zone Settings ni Origin CA: Edit. No se registra el token.

## DNS

- 32 registros: los 29 previos más los tres de AuroraShop, proxied a las IPs del LB (`34.8.197.115` demo/admin, `136.68.90.143` staging).
- Permiso de escritura verificado con `PATCH` a un ID inexistente: `81044 Record does not exist` (no `9109`), es decir, el token puede crear registros.

## WAF

La zona no tenía entrypoint de WAF. Se dejó preparado y **deshabilitado**:

| Objeto | ID | Detalle |
|---|---|---|
| Ruleset custom | `f9b9aafd842f45da8159d31757d5e3df` | W-01 `42ac529e…`, W-03 `2f15df51…`, W-04 `2123f018…`, W-05 `ca9cd268…`, W-06 `87b0d648…`; todas `enabled=false` |
| Ruleset managed | `94b1cdbe2d234721aa23e13be15d359e` | Cloudflare Managed Free Ruleset `77454fe2…`; `enabled=false` |

Ambas expresiones están limitadas a los tres hosts de AuroraShop para no tocar los otros 28 nombres de la zona.

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

`terraform apply` completó GKE/Cloud SQL/buckets/Cloud Armor y el DNS ya resuelve a Cloudflare. Las peticiones a `aurorashop.ancordss.me.uk` devuelven 525 porque el LB aún no tiene Ingress ni certificado; `admin`/`staging` no completan TLS por la misma causa.
