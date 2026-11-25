# Estado de Cloudflare — 2026-11-24

Zona: `ancordss.me.uk` (`d7ab4dfd85ce67a4e3273ae07d402e8b`), plan **Free**, cuenta `1b45d5e5a5b93bb6e781126413b2b567`.
Token con permisos de DNS, WAF/rulesets, Logpush y Access (lectura); sin Zone Settings ni Origin CA: Edit. No se registra el token.

## DNS

- 29 registros existentes; todos los servicios del VPS `144.217.164.56` y `blog` a GitHub Pages.
- 0 registros para `aurorashop`, `admin.aurorashop` o `staging.aurorashop`.
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

- 0 jobs.
- Bucket GCS pendiente de `terraform apply`; el IAM para `logpush@cloudflare-data.iam.gserviceaccount.com` ya está en el módulo `data`.

## Origen

- `GET /certificates?zone_id=…` funciona (0 certificados), pero `POST /certificates` devuelve `1016 User is not authorized`.
- Clave y CSR generados localmente en `~/.aurorashop-origin/` (permisos 600), con SANs de los tres hosts. El certificado se emite en el dashboard o con un token de Origin CA: Edit.

## Bloqueos

1. `terraform apply` (Javier/CI con WIF) para IPs del Ingress, buckets y Cloud Armor.
2. Token con Zone Settings: Edit para SSL Full (strict), TLS 1.2/1.3 y HSTS.
3. Token con Access: Apps and Policies: Edit y la organización Zero Trust para `admin.` y `staging.`.
4. Token con Origin CA: Edit para emitir el certificado sin pasar por el dashboard.
