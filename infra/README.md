# Infraestructura como código

Responsable: **Josue** · Revisión: James

El directorio raíz despliega una VPC, un clúster GKE Autopilot privado, Cloud SQL MySQL, Artifact Registry, buckets privados con CMEK, Secret Manager, Cloud Armor y el sink de auditoría. El acceso al plano de control usa GKE Connect Gateway; el endpoint IP público de Kubernetes queda desactivado.

## Estructura

```text
infra/
  main.tf, variables.tf, versions.tf, backend.tf
  modules/{network,data,compute,observability}/
  k8s/{base,bootstrap,overlays/{dev,staging,demo}}/
```

## Requisitos previos

- Javier confirma que el proyecto `aurorashop-sec-umg`, APIs, bucket remoto de estado y proveedor WIF ya existen (tarea #30). El bucket debe tener versionado, acceso uniforme y prevención de acceso público.
- Terraform 1.11 o posterior; el provider Google se fija en `8.2.x` y el provider HTTP en `3.5.x`.
- Aplicar con una identidad autorizada desde GitHub Actions. La cuenta de CI del despliegue no requiere claves JSON.
- Antes de aplicar, revisar tier y costo estimado de Cloud SQL, presupuesto, cuotas de direcciones/IP y permisos del service agent de KMS. `deletion_protection` permanece activa en la base de datos y el clúster.

## Inicialización

`backend.hcl.example` documenta el prefijo remoto. La CI consume el nombre del bucket desde la variable de repositorio `TF_STATE_BUCKET`; no se requiere archivo de backend local.

El workflow `.github/workflows/terraform.yml` valida en PR sin credenciales, genera plan remoto con WIF después del merge y limita `apply` a despacho manual desde `main` y al environment `infra-apply`. El state usa el bucket `TF_STATE_BUCKET` y prefijo `terraform/aurorashop`; el archivo real de backend se mantiene fuera de Git. No correr `apply` desde una laptop. El primer bootstrap y la creación del bucket de estado pertenecen a Javier.

## Kubernetes y operación

- El workload usa el Secret Manager CSI add-on, Workload Identity, GCS Fuse para medios y Cloud SQL Auth Proxy con IAM DB Authentication.
- Terraform crea metadatos para los secretos, no sus valores. El bootstrap seguro debe publicar las versiones de auth keys, salts y credenciales sandbox antes de arrancar los Pods.
- Después de crear la instancia, ejecutar `sql/grant-runtime-role.sql.template` una sola vez con una cuenta administrativa protegida. El usuario runtime recibe CRUD por base; el primer `CREATE TABLE` de WordPress y las migraciones DDL aún necesitan un proceso temporal separado.
- El primer despliegue instala los namespaces, RBAC y `workload-serviceaccounts.yaml` una vez con la identidad inicial; las revisiones posteriores aplican el overlay correspondiente desde CI.
- Los Ingress de staging y demo requieren que James entregue el certificado de origen Cloudflare en ambos namespaces por un canal seguro. El certificado y su clave no se guardan en Terraform ni en Git.
- Cloud Armor consulta en cada `plan` la lista oficial de rangos de Cloudflare. Si el endpoint no responde o devuelve una lista vacía, el plan falla de forma cerrada.
- `terraform destroy` no es una operación ordinaria. Requiere plan revisado, ventana de teardown y preservación previa de evidencias y backups.

## Validación pendiente

En este equipo no están instalados Terraform, gcloud ni GitHub CLI. El código no se ha aplicado contra GCP; por ello no hay `terraform plan`, outputs de clúster, reportes de Checkov/tfsec ni evidencia de despliegue aún. Se registran en `evidencias/fase2/` y `evidencias/fase3/` después de ejecutar la CI con los accesos de Javier.
