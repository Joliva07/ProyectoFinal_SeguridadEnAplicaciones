# Triaje SAST/SCA/WPScan — 2026-11-26

Responsable: **Arun** · Issue #50 · Insumo: run `45940623596` de `security-ci.yml` (push a `main`, commit `2f98a53`, 2026-11-27 04:33 UTC), los 9 jobs en `success`.

Artefactos descargados con `gh run download 45940623596` y resumidos con un script local. No se suben los reportes crudos: siguen disponibles como artefactos del run.

## 1. Resumen por herramienta

| Herramienta | Versión | Alcance | Resultados | Supresiones |
|---|---|---|---|---|
| Semgrep OSS | 1.186.0 | `p/php`, `p/owasp-top-ten`, `p/secrets` sobre el repo | 3 (nivel `warning`) | 3, todas `inSource` (`nosemgrep`) |
| gitleaks | SARIF del job *Secret scan* | historial del repo | 0 | — |
| Checkov | 3.3.27 | `infra/` + manifiestos renderizados | 0 fallos | 13 checks en `.checkov.yaml` + 1 `checkov:skip` en línea |
| kubesec | job *IaC and Kubernetes scan* | `Deployment/aurorashop` en `dev`, `staging`, `demo` | score 18, sin críticos | — |
| Trivy | job *Container scan* | `aurorashop-php:ci` y `aurorashop-nginx:ci` (Alpine 3.24.4) | 0 vulnerabilidades, 0 secretos, 0 misconfig en SO, `node-pkg` y `composer-vendor` (dependencias de WooCommerce) | — |
| composer audit | Composer 2.11.3 | `cms/composer.lock` | `{"advisories":[],"packages":0}` | — |
| npm audit | — | no hay `package.json` | no aplica | — |
| WPScan | `wpscanteam/wpscan:v4.1.0`, API plan free | `https://aurorashop.ancordss.me.uk/`, `--enumerate vp,vt` | tema `twentytwentyfive` 1.5; plugin `woocommerce` **sin versión detectada** con 57 vulnerabilidades históricas | — |

## 2. Detalle de Semgrep

| Regla | Archivo:línea | Justificación en el código |
|---|---|---|
| `generic.nginx.security.request-host-used` | `cms/docker/nginx/nginx.conf:42` | Sí: *"solo se registra (escape=json), no se usa para enrutar ni redirigir"* |
| `terraform.gcp.security.gcp-cloud-storage-logging` | `infra/modules/data/main.tf:135` | Sí, en el `checkov:skip=CKV_GCP_62` de la línea 134 (recursión del bucket de logs) |
| `terraform.gcp.security.gcp-sql-database-ssl-insecure-value-postgres-mysql` | `infra/modules/data/main.tf:289` | **No**: el `nosemgrep` no trae motivo |

## 3. Detalle de WPScan

```text
plugins.woocommerce.found_by   = "Urls In Homepage (Passive Detection)"
plugins.woocommerce.version    = null        # la versión está oculta (P-04)
plugins.woocommerce.latest     = 11.3.1
vulnerabilidades listadas      = 57
mayor fixed_in                 = 11.3.0      # CVE-2026-125801
entradas sin fixed_in          = 0
entradas con campo "cvss"      = 0 de 57     # claves: title, uuid, fixed_in, references
versión instalada (Dockerfile) = ARG WOOCOMMERCE_VERSION=11.3.1
```

Conclusiones:

1. Las 57 entradas ya están corregidas en la versión instalada (11.3.1 > 11.3.0), así que todas son falsos positivos de versión.
2. La API free de WPScan **no devuelve CVSS**. `.github/scripts/wpscan-threshold.py` busca `cvss`/`cvss_score` para comparar con 7.0, no lo encuentra y termina en verde. Un plugin con un CVE crítico sin corregir también pasaría: el gate **falla abierto** (S-04).

## 4. Verificación en vivo del borde (2026-11-26 22:45 GMT-6)

Peticiones pasivas, sin carga, dentro de la ventana aprobada.

```text
curl -sI https://aurorashop.ancordss.me.uk/          → 200, sin Strict-Transport-Security
openssl s_client -tls1   (aurorashop)                → handshake OK: Protocol TLSv1
openssl s_client -tls1_1 (aurorashop)                → handshake OK: Protocol TLSv1.1
curl -H "Origin: https://evil.test" .../wp-json/     → access-control-allow-origin: https://evil.test
                                                       access-control-allow-credentials: true
curl https://staging-aurorashop.ancordss.me.uk/      → 502
curl https://admin-aurorashop.ancordss.me.uk/        → 200 (sin Cloudflare Access)
curl .../wp-cron.php                                 → 200
25 × GET /shop/ seguidos                             → 25 × 200, sin 429 ni challenge
```

| ID | Lo que dice el documento | Lo observado hoy | Consecuencia |
|---|---|---|---|
| P-07 | `pentest-caja-negra.md`: "corregido" | TLS 1.0 y 1.1 **aceptados** | Se reabre. `superficie-ataque.md` (abierto) es el estado correcto |
| P-08 | abierto | sin HSTS | sigue abierto |
| P-09 / H-08 | parcial | `admin-` responde 200 sin Access | sigue parcial |
| P-10 | abierto | 502 | sigue abierto |
| P-12 | aceptado temporal | 200 | sigue igual |
| H-11 | abierto | CORS refleja el origen con credenciales | sigue abierto |
| H-12 | abierto | sin límite en `/shop/` | sigue abierto |
