# Evidencias fase 2 · Josue

Estado al 2026-11-24: pendiente de ejecución. Aquí se guardan únicamente resultados reales, redactados y asociados al commit/ejecución que los produjo.

| Artefacto | Fuente prevista | Estado |
|---|---|---|
| Diagrama C4, IAM/RBAC y cifrado | Mermaid + Terraform | Fuentes editables en `docs/02-arquitectura/`; export/evidencia de GCP pendiente |
| `terraform plan` | workflow `Terraform infrastructure` con WIF | Pendiente del bucket `TF_STATE_BUCKET` y credenciales de Javier |
| Namespaces, cluster y servicios | `kubectl` por Connect Gateway | Pendiente de apply y acceso al clúster |
| IPs de Ingress y política Cloud Armor | outputs Terraform + Cloud Armor | Pendiente de apply y validación con Cloudflare |

No se incluye un plan local, salida ficticia ni datos sensibles.
