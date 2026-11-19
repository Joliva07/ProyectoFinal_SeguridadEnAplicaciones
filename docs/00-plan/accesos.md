# Accesos y modelo de privilegios

## 1. GitHub

| Persona | Usuario | Rol | Estado |
|---|---|---|---|
| James | `Ancordss` | Admin | listo |
| Javier | `Joliva07` | Admin (owner del repo) | listo |
| Horacio | `Horacio935` | Write | listo |
| Josue | — | Write | **pendiente: falta usuario** |
| Arun | — | Write | **pendiente: falta usuario** |

Invitación (solo James o Javier):

```bash
gh api -X PUT repos/Joliva07/ProyectoFinal_SeguridadEnAplicaciones/collaborators/<usuario> -f permission=push
```

Protecciones mínimas de `main`: PR obligatorio, 1 revisión, sin force-push, checks de CI requeridos cuando el pipeline exista.

## 2. Google Cloud

Proyecto: `financiaweb-sec-umg` (o el que asigne la cuenta de la universidad). Región: `us-central1`.

### 2.1 Roles por persona (menor privilegio)

| Persona | Rol en el proyecto | Justificación |
|---|---|---|
| James | `roles/owner` (bootstrap) → luego `roles/resourcemanager.projectIamAdmin` + break-glass | Único con escritura manual y facturación |
| Javier | `roles/viewer`, `roles/bigquery.dataViewer`, `roles/cloudsql.viewer` | Consulta de datos para inventario y matriz |
| Josue | `roles/viewer`, `roles/logging.viewer`, `roles/monitoring.viewer` | Lee estado; **despliega solo por CI** con `sa-deployer` |
| Horacio | `roles/viewer`, `roles/artifactregistry.reader` | Descarga imágenes/APK para pruebas |
| Arun | `roles/viewer`, `roles/logging.viewer`, `roles/monitoring.viewer`, `roles/bigquery.dataViewer` | SIEM y dashboards |

Nadie recibe `roles/editor` ni claves JSON de cuenta de servicio. El pipeline usa Workload Identity Federation:

- `sa-gh-deployer@financiaweb-sec-umg.iam.gserviceaccount.com` — `roles/run.admin`, `roles/artifactregistry.writer`, `roles/iam.serviceAccountUser`, `roles/cloudsql.client`, `roles/storage.objectAdmin` (solo buckets de artefactos).
- Condición WIF: `assertion.repository == "Joliva07/ProyectoFinal_SeguridadEnAplicaciones"` y `assertion.ref == "refs/heads/main"`.

### 2.2 Checklist de bootstrap (James)

- [ ] Proyecto creado, facturación vinculada, alerta de presupuesto en 20 USD y 40 USD.
- [ ] APIs: `run`, `sqladmin`, `artifactregistry`, `secretmanager`, `cloudkms`, `iamcredentials`, `identitytoolkit`, `apigateway`, `compute`, `logging`, `monitoring`, `bigquery`, `securitycenter`, `cloudbuild` (solo si se usa).
- [ ] VPC `fw-vpc` + subred `fw-sub-us-central1` con Private Google Access; conector Serverless para Cloud Run → SQL privado.
- [ ] Cloud SQL PostgreSQL con IP privada, CMEK en Cloud KMS, backups y `max_connections` controlado.
- [ ] Secret Manager con `db-password`, `jwt-signing` (versiones gestionadas por CI).
- [ ] Buckets: `fw-logs-archive` (Logpush), `fw-artifacts`; uniform bucket-level access, sin acceso público.
- [ ] Presupuesto + alertas y etiquetas `proyecto=financiaweb,curso=seguridad-apps`.
- [ ] Invitaciones IAM a los 4 integrantes con los roles de la tabla.

### 2.3 Datos de cuentas demo (solo sintéticos)

| Usuario | Rol | Uso |
|---|---|---|
| `demo-cliente-01` / `-02` | cliente | pruebas IDOR/BOLA con dos sesiones |
| `demo-admin-01` | admin | pruebas de escalada vertical |
| `auditor-01` | lectura | demo de acceso mínimo |

## 3. Cloudflare

Única persona con acceso: **James**. Cuenta con 2FA. La zona `ancordss.me.uk` ya usa nameservers de Cloudflare.

### 3.1 Registros DNS a crear

| Tipo | Nombre | Contenido | Proxy |
|---|---|---|---|
| CNAME | `financiaweb` | servicio Cloud Run / LB de GCP | Proxied |
| CNAME | `api.financiaweb` | API Gateway / LB de GCP | Proxied |
| CNAME | `admin.financiaweb` | servicio admin | Proxied + Access |

### 3.2 Configuración base

- SSL/TLS: Full (strict) con Origin CA en GCP; mínimo TLS 1.2, TLS 1.3 activo; HSTS con `max-age=31536000; includeSubDomains; preload` (evaluar `preload` al cierre).
- WAF Managed Rules (Cloudflare OWASP Core Ruleset) en modo log la primera semana, block al cierre.
- Rate limiting: 100 req/min por IP en `api.*`; 10 req/min en `/auth/*`.
- Bot Fight Mode / Super Bot Fight Mode; Turnstile en login web.
- Cloudflare Access en `admin.financiaweb` (política por correo del grupo).
- Logpush → GCS `fw-logs-archive` (HTTP requests) para correlación en BigQuery.
- API Shield: schema de endpoints, JWT validation rules.

### 3.3 Tokens

Token API por función, no global: `dns-edit`, `waf-edit`, `logpush-edit`, con TTL de 30 días. Ningún token se guarda en el repo; si se requiere automatización, va en GitHub Secrets y lo configura James.

## 4. Regla de cambio en el borde

1. Se abre issue con etiqueta `cloudflare` usando la plantilla de solicitud de borde.
2. Arun (o quien la pida) entrega: host, path, expresión de la regla, acción, riesgo que mitiga y evidencia esperada.
3. James aplica, captura, comenta la issue y la cierra. SLA 24 h hábiles.
4. Todo cambio queda registrado en `docs/05-operaciones/waf-cloudflare.md` con fecha y resultado.

## 5. Claude

Todos usan su propia cuenta. Reglas: no pegar secretos, tokens ni datos de la cuenta GCP en el chat; generar código solo contra el alcance del proyecto; el código generado pasa por revisión y por el pipeline antes de mergear.
