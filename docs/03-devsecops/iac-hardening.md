# Hardening de Infraestructura como Código

Dueño: **Josue** · Herramientas: Checkov + tfsec · Componente de rúbrica 2 y fase 5

## 1. Controles mínimos que deben pasar

| Control | Regla típica | Configuración esperada |
|---|---|---|
| Sin buckets públicos | CKV_GCP_29 / CKV_GCP_114 | `uniform_bucket_level_access = true`, IAM sin `allUsers` |
| Sin firewall 0.0.0.0/0 en 22/3389 | CKV_GCP_2 | reglas solo desde el conector/IAP |
| Cloud SQL sin IP pública | CKV_GCP_6 / tfsec `google-sql-no-public-access` | `ipv4_enabled = false` + `private_network` |
| Cifrado con CMEK | CKV_GCP_83 | `encryption_key_name` en SQL y buckets |
| Backups habilitados | CKV_GCP_27 | `backup_configuration.enabled = true` |
| Cloud Run sin `allUsers` | CKV_GCP_105 | invoker = LB/API Gateway solamente |
| Sin `roles/owner`/`editor` a SA | CKV_GCP_49 | roles específicos |
| Etiquetas de proyecto | política propia | `proyecto`, `ambiente`, `curso` |

## 2. Evidencia antes/después

1. Correr Checkov y tfsec sobre el estado inicial del repositorio y guardar `evidencias/fase5/iac-antes/`.
2. Corregir el código Terraform (no silenciar reglas).
3. Correr de nuevo y guardar `evidencias/fase5/iac-despues/`.
4. Tabla comparativa obligatoria para el informe:

| Regla | Severidad | Antes | Después | Cambio aplicado |
|---|---|---|---|---|
| CKV_GCP_29 | HIGH | 3 fallos | 0 | `uniform_bucket_level_access` |
| CKV_GCP_6 | HIGH | 1 fallo | 0 | IP privada + conector |

## 3. Contenedores

| Aspecto | Requisito |
|---|---|
| Imagen base | Distroless o Alpine mínima, digest fijado |
| Usuario | no root, `USER 10001` |
| Filesystem | read-only cuando sea posible |
| Puertos | solo el del servicio; sin SSH |
| Trivy | sin CRITICAL con fix; reporte archivado |
| Firma | `cosign` (opcional, suma puntos) y procedencia desde Actions |

## 4. Dockerfile endurecido — criterios de revisión

- Multi-stage build; sin compiladores ni tests en la imagen final.
- Sin `ARG` con secretos; uso de BuildKit `--secret` si hace falta.
- `HEALTHCHECK` o probe de Cloud Run.
- Sin `apt upgrade` que rompa la reproducibilidad; versiones fijadas.
- `.dockerignore` que excluya `.git`, evidencia y secretos.

## 5. Flujo de trabajo

Terraform se aplica **solo** desde el pipeline (WIF). Para el bootstrap inicial, James aplica con sus credenciales una vez y documenta la salida; después nadie aplica a mano. El estado remoto vive en un bucket versionado con bloqueo, y no se sube al repo.
