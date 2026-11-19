# Hardening de Infraestructura como Código y manifiestos

Dueño: **Josue** · Herramientas: Checkov + tfsec + kubesec · Componente de rúbrica 2 y fase 5

## 1. Controles mínimos (Terraform)

| Control | Regla típica | Configuración esperada |
|---|---|---|
| Bucket sin acceso público | CKV_GCP_29 / CKV_GCP_114 | `uniform_bucket_level_access = true`, sin `allUsers` |
| Cloud SQL sin IP pública | CKV_GCP_6 | `ipv4_enabled = false` + `private_network` |
| Cifrado con CMEK | CKV_GCP_83 | `encryption_key_name` en SQL y buckets |
| Backups habilitados | CKV_GCP_27 | `backup_configuration.enabled = true` |
| GKE sin endpoint público | CKV_GCP_25 / GKE private cluster | `enable_private_endpoint = true` + `master_authorized_networks` |
| Sin SA con roles amplios | CKV_GCP_49 | roles específicos, sin `owner`/`editor` |
| Logging de auditoría | CKV_GCP_2 / audit config | `audit_config` en servicios críticos |
| Etiquetas | política propia | `proyecto`, `ambiente`, `curso` |

## 2. Controles mínimos (Kubernetes)

| Control | Regla | Configuración esperada |
|---|---|---|
| Pod Security | CKV_K8S_* / PSA | namespace con `pod-security.kubernetes.io/enforce: restricted` |
| Non-root | CKV_K8S_6 / K8S_23 | `runAsNonRoot: true`, `runAsUser: 10001` |
| Root FS de solo lectura | CKV_K8S_22 | `readOnlyRootFilesystem: true` + `emptyDir` para lo volátil |
| Sin privilegios | CKV_K8S_16 / K8S_1 | `allowPrivilegeEscalation: false`, `privileged: false`, `drop: ["ALL"]` |
| Seccomp | K8S_20 | `seccompProfile: RuntimeDefault` |
| Sin `hostPath`/`hostNetwork` | CKV_K8S_28 | prohibido en el namespace |
| Token de SA no montado si no se usa | K8S_36 | `automountServiceAccountToken: false` salvo necesidad |
| Límites de recursos | CKV_K8S_11/12/13 | requests y limits definidos |
| Imagen por digest | política | `image@sha256:...`, no `:latest` |
| NetworkPolicy | política | deny-all + allow a MySQL/GCS/DNS |

## 3. Evidencia antes/después

1. Correr Checkov + tfsec + kubesec sobre el estado inicial y guardar `evidencias/fase5/iac-antes/`.
2. Corregir el código (no silenciar reglas).
3. Correr de nuevo y guardar `evidencias/fase5/iac-despues/`.
4. Tabla comparativa obligatoria:

| Regla | Severidad | Antes | Después | Cambio aplicado |
|---|---|---|---|---|
| CKV_GCP_6 | HIGH | 1 | 0 | IP privada + conector |
| CKV_K8S_22 | MEDIUM | 2 | 0 | `readOnlyRootFilesystem` |
| CKV_K8S_16 | HIGH | 2 | 0 | `allowPrivilegeEscalation: false` |

## 4. Reglas de trabajo

- El estado de Terraform vive en GCS versionado con bloqueo; nunca en el repo.
- `terraform apply` solo desde el pipeline (WIF). El bootstrap inicial lo aplica James una vez y documenta la salida.
- Los manifiestos se generan/validan con `kustomize build` o `helm template` antes del apply; lo que no está en el repo no existe en el clúster.
- `kubectl apply` manual queda prohibido; el break-glass se registra como incidente en `tratamiento-riesgo.md`.
- Las excepciones a una regla de Checkov se documentan con `#checkov:skip=<ID>:<razón>` y fecha de revisión.
