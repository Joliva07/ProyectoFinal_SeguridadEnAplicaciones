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

Checkov aplica umbral HIGH/CRITICAL a Terraform y Kubernetes. tfsec conserva cobertura de reglas Terraform; está en mantenimiento limitado, por lo que su salida se complementa con Checkov y la actualización del código. `terraform.yml` corre `fmt -check`, `init -backend=false` y `validate` sin acceso cloud en PR; el plan remoto usa WIF después de merge a `main`.

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

Kubesec produce JSON sobre manifiestos renderizados por `kubectl kustomize`; el resultado queda como artifact. Checkov revisa también el YAML declarado. La validación en vivo de RBAC, NetworkPolicy, PSA y endpoints requiere el clúster.

## 3. Reglas de estado y evidencia

- El state no se commitea. `infra/backend.hcl` y `infra/terraform.tfvars` están ignorados; el state usa bucket GCS de Javier.
- Plan y apply corren en GitHub Actions con WIF. Apply manual de `main` requiere environment `infra-apply` configurado con aprobación.
- La salida del plan puede mostrar recursos y datos sensibles; debe guardarse con acceso controlado, sin subir `tfplan` binario a artifacts públicos.
- Las excepciones a Checkov incluyen ID de regla, justificación, owner y fecha de vencimiento. No se silencia para lograr un score.
- `evidencias/fase3/iac/` recibe JSON/SARIF de la ejecución real, y tabla comparativa completada con los reportes.

## 4. Resultados

| Scanner | Antes | Después | Estado |
|---|---:|---:|---|
| Checkov | Pendiente | Pendiente | No ejecutado |
| tfsec | Pendiente | Pendiente | No ejecutado |
| Kubesec | Pendiente | Pendiente | No ejecutado |

La resolución solo se marca después de ejecutar los scanners contra el mismo commit antes y después del hardening.
