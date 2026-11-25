# Terraform apply — 2026-11-24

Cuenta: `hmaradiagal@miumg.edu.gt` (`roles/owner` tras aceptar la invitación de owner externo).
Proyecto: `aurorashop-sec-umg` · Región: `us-central1`.
State: `gs://aurorashop-tf-state-aurorashop-sec-umg`, workspace `demo`, backend GCS.
Commit de infraestructura: rama `fix/k8s-cloudflare` (PR #62).

## Resultado

```text
terraform apply
Apply complete! 0 to add, 0 to change, 0 to destroy (post-verificación)
```

El primer apply falló y dejó 49 recursos; los reintentos corrigieron y completaron el resto. `terraform plan` final: **No changes**.

## Outputs

| Salida | Valor |
|---|---|
| `cluster_name` | `aurorashop-gke` |
| `cluster_membership` | `aurorashop-demo` |
| `ingress_ip` | `34.8.197.115` |
| `staging_ingress_ip` | `136.68.90.143` |
| `database_private_ip` | `10.40.0.3` |
| `database_connection_name` | `aurorashop-sec-umg:us-central1:aurorashop-demo-mysql` |
| `media_buckets` | 3 buckets por ambiente |
| `logs_archive_bucket` | `aurorashop-logs-archive-aurorashop-sec-umg-demo` |
| `logs_dataset` | `aurorashop_demo_security_logs` |
| `cloud_armor_policy_name` | `aurorashop-demo-edge` |

## Verificación

| Control | Comando | Resultado |
|---|---|---|
| Autopilot | `gcloud container clusters describe` | `autopilot.enabled=true` |
| Endpoint privado | idem | `enablePrivateEndpoint=true`, endpoint privado `172.16.0.2` |
| Workload Identity | idem | pool `aurorashop-sec-umg.svc.id.goog` |
| Secret Manager CSI | `kubectl get csidrivers` | `secrets-store-gke.csi.k8s.io` |
| GCS Fuse CSI | idem | `gcsfuse.csi.storage.gke.io` |
| Cloud SQL | `gcloud sql instances describe` | `RUNNABLE`, IP privada `10.40.0.3`, `sslMode=ENCRYPTED_ONLY`, binary log activo |
| Secretos | `gcloud secrets list` | 9 secretos (`auth-keys`, `salts`, `payment-sandbox` por ambiente) |
| Cloud Armor | `gcloud compute security-policies describe` | 7 reglas (SQLi, XSS, cve-canary, 3 allowlist, deny) |
| Namespaces PSA | `kubectl get ns --show-labels` | `restricted` en `dev`, `staging`, `aurorashop` |
| RBAC CI | `kubectl auth can-i` | deployments sí; Secrets/Nodes/RBAC no |
| Connect Gateway | `kubectl get ns` | funciona sin endpoint público |

## Defectos encontrados durante el apply (corregidos)

1. `secret_id = each.value` creaba secretos llamados `demo`/`dev`/`staging`; cambiado a `each.key`.
2. Faltaban los service agents de GCS y Artifact Registry; se crean con `google_project_service_identity` antes de los bindings KMS.
3. BigQuery usa `bq-<project_number>@bigquery-encryption.iam.gserviceaccount.com`, no `gcp-sa-bigquery`; corregido.
4. `sa-gh-deployer` no existía; ahora lo crea el módulo `compute`.
5. El binding de Workload Identity se aplicaba antes de que existiera el pool; se agregó `depends_on` al clúster.
6. GKE Autopilot rechazaba `master_auth`, `logging_config`, `monitoring_config` y `secret_manager_config` en el create; el clúster quedó mínimo y el add-on de Secret Manager se habilitó con `gcloud` y se declaró en Terraform.
7. Con endpoint privado, GKE exige `master_authorized_networks_config`; se agregó vacío.

## Pendiente

- Certificado Origin CA e Ingress/TLS (token de Cloudflare sin Origin CA: Edit).
- Versiones de los 9 secretos (los valores los entrega el responsable del ambiente).
- Imágenes del CMS (#40) para que el Deployment arranque.
