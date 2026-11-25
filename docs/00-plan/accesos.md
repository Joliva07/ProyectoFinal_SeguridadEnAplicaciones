# Accesos y modelo de privilegios

## 1. GitHub

| Persona | Usuario | Rol | Estado |
|---|---|---|---|
| Josue | `Joliva07` | **Owner del repositorio** (lo creó) | listo |
| James | `Ancordss` | Write (borde, SIEM, informe) | listo |
| Horacio | `Horacio935` | Write | listo |
| Javier | — | Write | **pendiente: falta usuario** |
| Arun | — | Write | **pendiente: falta usuario** |

Invitación (solo Josue, owner del repo):

```bash
gh api -X PUT repos/Joliva07/ProyectoFinal_SeguridadEnAplicaciones/collaborators/<usuario> -f permission=push
```

Protección de `main`: PR obligatorio, 1 revisión, sin force-push, checks de CI requeridos cuando el pipeline exista.

## 2. Google Cloud

Proyecto: `aurorashop-sec-umg`. Región: `us-central1` (GKE Autopilot zonal/regional) y Cloud SQL MySQL 8.

### 2.1 Roles por persona (menor privilegio)

| Persona | Rol en el proyecto | Justificación |
|---|---|---|
| Javier | `roles/billing.admin` (cuenta) + `roles/owner` (proyecto) | **Dueño de la cuenta GCP y la facturación**; único que otorga accesos |
| James | `roles/viewer` + break-glass temporal bajo solicitud a Javier | Opera Cloudflare; no necesita escritura permanente en GCP |
| Josue | `roles/viewer`, `roles/logging.viewer`, `roles/monitoring.viewer` | Owner del repo; despliega **solo por CI** con `sa-gh-deployer` |
| Horacio | `roles/viewer`, `roles/artifactregistry.reader` | Descarga imágenes para pruebas locales |
| Arun | `roles/viewer`, `roles/logging.viewer`, `roles/monitoring.viewer`, `roles/bigquery.dataViewer` | SIEM, Falco y dashboards |

Nadie recibe `roles/editor` ni claves JSON. Pipeline con Workload Identity Federation:

- `sa-gh-deployer@aurorashop-sec-umg.iam.gserviceaccount.com` — `roles/container.developer`, `roles/artifactregistry.writer`, `roles/iam.serviceAccountUser`, `roles/cloudsql.client`, `roles/storage.objectAdmin` (solo buckets de artefactos).
- Condición WIF: `assertion.repository == "Joliva07/ProyectoFinal_SeguridadEnAplicaciones"` y `assertion.ref == "refs/heads/main"`.
- `sa-gke-workload` con `roles/cloudsql.client`, `roles/storage.objectViewer` (bucket media) y `roles/secretmanager.secretAccessor` (secretos `aurorashop-*`).

### 2.2 Checklist de bootstrap (Javier, con James para el borde)

- [ ] Proyecto, facturación, alertas en 20 y 40 USD.
- [ ] APIs: `container`, `sqladmin`, `artifactregistry`, `secretmanager`, `cloudkms`, `iamcredentials`, `compute`, `logging`, `monitoring`, `bigquery`, `securitycenter`, `cloudresourcemanager`.
- [ ] VPC `aurorashop-vpc`, subred con IP secundarias para pods y servicios, Private Google Access, Cloud NAT para egreso controlado.
- [ ] GKE Autopilot **privado** (sin endpoint público) + authorized networks; namespaces `aurorashop`, `dev`, `staging`.
- [ ] Cloud SQL MySQL con IP privada, CMEK, backups, usuario `app` de mínimo privilegio (sin `GRANT ALL`).
- [ ] Secret Manager: `db-password`, `auth-keys`, `salts`, `payment-sandbox`.
- [ ] Buckets: `aurorashop-media` (privado, CMEK), `aurorashop-backups`, `aurorashop-logs-archive`; uniform access, sin `allUsers`.
- [ ] Etiquetas `proyecto=aurorashop`, `ambiente`, `curso=seguridad-apps`.
- [ ] Invitaciones IAM a los 4 integrantes (incluida la cuenta de facturación si aplica).
- [ ] Escritura permanente solo para Javier; break-glass temporal documentado si otro necesita aplicar algo.

### 2.3 Cuentas demo

| Usuario WP | Rol | Uso |
|---|---|---|
| `demo-cliente-01..03` | customer | IDOR de pedidos con dos sesiones |
| `demo-admin-01` | administrator | escalada vertical |
| `demo-editor-01` | editor | capacidades y acceso a medios |
| `demo-shopmanager` | shop_manager | pedidos y cupones |

## 3. Cloudflare

Única persona con acceso: **James**. Cuenta con 2FA. La zona `ancordss.me.uk` ya usa nameservers de Cloudflare.

### 3.1 Registros DNS a crear

| Tipo | Nombre | Contenido | Proxy |
|---|---|---|---|
| A | `aurorashop` | `terraform output -raw ingress_ip` | Proxied |
| A | `admin.aurorashop` | misma IP del Ingress demo | Proxied + Access |
| A | `staging.aurorashop` | `terraform output -raw staging_ingress_ip` | Proxied + Access |

Son registros **A**: el contenido de un CNAME debe ser un hostname, no una IP. Detalle y verificación en [`integracion-cloudflare-gke.md`](../05-operaciones/integracion-cloudflare-gke.md).

### 3.2 Configuración base

- SSL/TLS Full (strict) con Origin CA en GCP; mínimo TLS 1.2, 1.3 activo; HSTS (`max-age=31536000; includeSubDomains`).
- WAF Managed Rules (OWASP Core Ruleset, paranoia 2) en modo log la primera semana, luego block.
- Rate limiting: 100 req/min por IP en el storefront; 10 req/min en `/wp-login.php` y `/xmlrpc.php`; 5 req/min en checkout.
- Bot Fight Mode / Super Bot Fight Mode; Turnstile en login y checkout.
- Cloudflare Access en `admin.` y `staging.` (política por correo del grupo).
- Logpush → GCS `aurorashop-logs-archive-aurorashop-sec-umg-demo` (HTTP requests) para correlación en BigQuery. Terraform otorga `roles/storage.objectAdmin` a la cuenta documentada `logpush@cloudflare-data.iam.gserviceaccount.com`; no se usan claves JSON.
- Certificado Origin CA único con SANs `aurorashop`, `admin.aurorashop` y `staging.aurorashop`, instalado como Secret `aurorashop-origin-tls` en los namespaces `aurorashop` y `staging` por un humano; CI no puede leer ni escribir Secrets.
- Cache rules: no cachear `wp-admin`, `wp-json`, `cart`, `checkout`, `my-account`.

### 3.3 Tokens

Token API por función (`dns-edit`, `waf-edit`, `logpush-edit`) con TTL 30 días. Ningún token en el repo; si se automatiza, va en GitHub Secrets y lo configura James.

## 4. Regla de cambio en el borde

1. Issue con etiqueta `cloudflare` usando la plantilla de borde.
2. Quien la pide entrega: host, path, expresión, acción, riesgo que mitiga, evidencia esperada.
3. James aplica, captura, comenta y cierra. SLA 24 h hábiles.
4. Todo cambio se registra en `docs/05-operaciones/waf-cloudflare.md` con fecha y resultado.

## 5. Claude

Cada integrante con su cuenta. Reglas: no pegar secretos, tokens ni datos de la cuenta GCP; el código generado pasa por revisión y pipeline; las reglas de seguridad se validan contra la documentación oficial, no solo contra la respuesta del modelo.
