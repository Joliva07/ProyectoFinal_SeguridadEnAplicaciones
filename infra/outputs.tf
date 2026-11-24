output "cluster_name" {
  value       = module.compute.cluster_name
  description = "Nombre del clúster GKE Autopilot."
}

output "cluster_membership" {
  value       = module.compute.cluster_membership
  description = "Nombre del registro de flota usado por Connect Gateway."
}

output "artifact_registry_repository" {
  value       = module.compute.artifact_registry_repository
  description = "URL regional del repositorio Docker."
}

output "ingress_ip" {
  value       = module.compute.ingress_ip
  description = "IP estática del balanceador HTTP(S) de GKE."
}

output "staging_ingress_ip" {
  value       = module.compute.staging_ingress_ip
  description = "IP estática para staging, protegido por Access en Cloudflare."
}

output "database_private_ip" {
  value       = module.data.database_private_ip
  description = "Dirección privada de Cloud SQL; no es una credencial."
}

output "database_connection_name" {
  value       = module.data.database_connection_name
  description = "Identificador para Cloud SQL Auth Proxy."
}

output "media_bucket" {
  value       = module.data.media_bucket_name
  description = "Bucket privado de medios."
}

output "media_buckets" {
  value       = module.data.media_bucket_names
  description = "Buckets privados de medios por ambiente."
}

output "database_names" {
  value       = module.data.database_names
  description = "Bases MySQL separadas por ambiente."
}

output "logs_archive_bucket" {
  value       = module.data.logs_archive_bucket_name
  description = "Bucket de archivo de logs con retención de 90 días."
}

output "cloud_armor_policy_name" {
  value       = module.compute.cloud_armor_policy_name
  description = "Política Cloud Armor de allowlist Cloudflare y reglas WAF."
}

output "logs_dataset" {
  value       = module.observability.logs_dataset_id
  description = "Dataset regional al que exporta el sink de auditoría."
}
