# Hardening de IaC y manifiestos

Dueño: **Josue** · Herramientas: Checkov, tfsec, Kubesec y Terraform validate.

> Estado: configuración de controles preparada; aún sin plan, aplicación ni resultados de scanners. No se presentan conteos before/after sin reporte.

## 1. Controles en Terraform

| Control | Implementación en `infra/` | Evidencia requerida |
|---|---|---|
| Datos privados | Cloud SQL sin IPv4 pública; VPC y Private Service Access | `terraform plan` y describe posterior |
| Cifrado | CMEK en Cloud SQL, buckets, logs y secretos; rotación 90 días | plan y configuración efectiva |
| Acceso de buckets | Uniform bucket-level access, PAP, versionado y sin IAM público | Checkov + IAM efectivo |
| Red | Subred privada, NAT, flow logs y rangos secundarios GKE | plan + revisión de firewall/egress |
| GKE | Autopilot privado, endpoint privado, Workload Identity, sin certificado cliente | plan y `gcloud describe` |
| Origen web | Cloud Armor filtra rangos oficiales Cloudflare y aplica SQLi/XSS administrado | regla activa + prueba desde Cloudflare/origen |
| IAM | GSA separada por ambiente; bucket/Secret Manager acotado por recurso | IAM policy + Connect Gateway |
| Auditoría | Sink a BigQuery y retención de 90 días | salida del sink y muestra redactada |
| Estado | Backend GCS remoto; fuera del repositorio | metadata/versionado del bucket |

Checkov aplica umbral HIGH/CRITICAL a Terraform y a los manifiestos **renderizados** de los tres overlays; escanear el YAML base sin renderizar produce falsos positivos de namespace y de probes. `terraform.yml` corre `fmt -check`, `init -backend=false` y `validate` sin acceso cloud en PR; el plan remoto usa WIF después de merge a `main`.

## 2. Controles Kubernetes

| Control | Manifiesto |
|---|---|
| PSA `restricted` | Labels en namespaces `dev`, `staging` y `aurorashop` |
| Proceso no root | UID/GID 10001 para app; proxy con UID 65532 |
| FS y privilegios | `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, sin capabilities |
| Seccomp | `RuntimeDefault` |
| Tokens | `automountServiceAccountToken: false`; Workload Identity vinculado durante bootstrap |
| Recursos | Requests/limits de CPU, memoria y almacenamiento efímero |
| Red | deny-all y allowlist DNS, Cloud SQL, APIs restringidas y metadata necesaria |
| Persistencia | GCS Fuse CSI con bucket distinto por ambiente |
| Secretos | Secret Manager CSI; sin valores dentro de Git ni RBAC CI para Secrets |
| CI RBAC | Role por namespace para Deployment, Service, HPA, PDB, NetworkPolicy, CSI e Ingress donde aplica |

Kubesec produce JSON sobre los manifiestos renderizados por `kubectl kustomize` (un archivo por overlay); Checkov escanea esos mismos archivos y el Terraform, no el YAML base sin renderizar. La validación en vivo de RBAC, NetworkPolicy, PSA y endpoints requiere el clúster.

## 3. Reglas de estado y evidencia

- El state no se commitea. `infra/backend.hcl` y `infra/terraform.tfvars` están ignorados; el state usa bucket GCS de Javier.
- Plan y apply corren en GitHub Actions con WIF. Apply manual de `main` requiere environment `infra-apply` configurado con aprobación.
- La salida del plan puede mostrar recursos y datos sensibles; debe guardarse con acceso controlado, sin subir `tfplan` binario a artifacts públicos.
- Las excepciones a Checkov incluyen ID de regla, justificación, owner y fecha de vencimiento. No se silencia para lograr un score.

### 3.2 Excepciones vigentes (inline Semgrep/tfsec)

| Herramienta | Regla | Justificación | Owner |
|---|---|---|---|
| Semgrep | `gcp-cloud-storage-logging` | El bucket sumidero de access logs no puede registrarse a sí mismo sin recursión; el resto de buckets sí registran | Josue |
| Semgrep | `gcp-sql-database-ssl-insecure-value-postgres-mysql` | Cloud SQL Auth Proxy con IAM usa TLS sin certificado de cliente; `ssl_mode=ENCRYPTED_ONLY` exige cifrado | Josue |
| tfsec | `AVD-GCP-0061` | Endpoint privado sin IP pública; authorized networks no aplica | Josue |
| tfsec | `AVD-GCP-0047` | Autopilot usa PSA/PodSecurity, no PSP | Josue |
| tfsec | `AVD-GCP-0048` | Autopilot administra el metadata server; Workload Identity está activo | Josue |
| tfsec | `AVD-GCP-0007` | Cloudflare exige `objectAdmin` solo en el bucket de logs para el ownership challenge | Josue |
| tfsec | `AVD-GCP-0015` | Mismo caso que la regla de Semgrep de SQL: proxy IAM + `ENCRYPTED_ONLY` | Josue |

Cada supresión está en la línea del recurso o atributo con `# nosemgrep:` o `#tfsec:ignore:<ID>:<motivo>`; no se usa un archivo global que oculte el resto de hallazgos.

### 3.3 Excepciones vigentes (`.checkov.yaml`)

| Regla | Justificación | Owner | Vence |
|---|---|---|---|
| `CKV_GCP_69` | Autopilot habilita el metadata server; no es configurable por el equipo | Josue | 2026-12-15 |
| `CKV_GCP_13` | Autopilot no emite certificados de cliente; el campo no es configurable | Josue | 2026-12-15 |
| `CKV_GCP_12` | Dataplane V2 de Autopilot aplica NetworkPolicy; los manifiestos la declaran explícita | Josue | 2026-12-15 |
| `CKV_GCP_20` | Endpoint privado sin IP pública; authorized networks no aplica | Josue | 2026-12-15 |
| `CKV_GCP_65` | RBAC con IAM + Connect Gateway; Google Groups no aplica | Josue | 2026-12-15 |
| `CKV_GCP_61` | Flow logs activos en la subred; intranode visibility no aplica a Dataplane V2 | Josue | 2026-12-15 |
| `CKV_GCP_6` | `ssl_mode = ENCRYPTED_ONLY`; el check no evalúa ese campo | Josue | 2026-12-15 |
| `CKV2_GCP_20` | MySQL habilita PITR con `binary_log_enabled`; el check busca el flag de PostgreSQL | Josue | 2026-12-15 |
| `CKV2_GCP_18` | VPC personalizada sin red default | Josue | 2026-12-15 |
| `CKV_GCP_66` | Binary Authorization exige política y aprobaciones; riesgo aceptado para el alcance del curso | Josue | 2026-12-15 |
| `CKV_GCP_62` | Todos los buckets registran acceso; el bucket sumidero no puede registrarse a sí mismo sin recursión | Josue | 2026-12-15 |
| `CKV_K8S_43` | CI sustituye el tag por digest antes de aplicar; el tag `local` es placeholder | Josue | 2026-12-15 |
| `CKV_K8S_15` | `IfNotPresent` es correcto con imagen fijada por digest | Josue | 2026-12-15 |

- `evidencias/fase3/iac/` recibe JSON/SARIF de la ejecución real, y tabla comparativa completada con los reportes.

## 4. Resultados

| Scanner | Antes | Después | Estado |
|---|---:|---:|---|
| Checkov | Pendiente | Pendiente | No ejecutado |
| tfsec | Pendiente | Pendiente | No ejecutado |
| Kubesec | Pendiente | Pendiente | No ejecutado |

La resolución solo se marca después de ejecutar los scanners contra el mismo commit antes y después del hardening.
