variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "network_id" { type = string }
variable "subnetwork_id" { type = string }
variable "cluster_pods_range" { type = string }
variable "cluster_services_range" { type = string }
variable "cloudflare_cidrs" {
  type        = list(string)
  description = "Lista leída en tiempo de plan desde la API pública de Cloudflare."

  validation {
    condition     = length(var.cloudflare_cidrs) >= 10
    error_message = "No se obtuvo una lista de rangos Cloudflare válida; se cancela para no exponer el origen."
  }
}
variable "workload_account_id" { type = string }
variable "media_buckets" { type = map(string) }
variable "secret_ids" { type = map(object({ secret_id = string, environment = string })) }
variable "database_instance_name" { type = string }
variable "artifact_registry_kms_key" {
  type        = string
  description = "Clave CMEK del repositorio de imágenes."
}
variable "labels" { type = map(string) }
