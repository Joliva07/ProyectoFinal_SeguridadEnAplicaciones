variable "project_id" {
  description = "ID del proyecto GCP ya creado por Javier."
  type        = string
  default     = "aurorashop-sec-umg"
}

variable "region" {
  description = "Región común para GKE, Cloud SQL, KMS, Artifact Registry y BigQuery."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Ambiente al que pertenece este despliegue de infraestructura."
  type        = string
  default     = "demo"

  validation {
    condition     = contains(["dev", "staging", "demo"], var.environment)
    error_message = "environment debe ser dev, staging o demo."
  }
}

variable "name_prefix" {
  description = "Prefijo estable para recursos de AuroraShop."
  type        = string
  default     = "aurorashop"
}

variable "database_tier" {
  description = "Tier de Cloud SQL; seleccionar después de revisar presupuesto/cuota."
  type        = string
  default     = "db-custom-1-3840"
}

variable "database_disk_gb" {
  description = "Disco inicial pequeño para el dataset sintético."
  type        = number
  default     = 10

  validation {
    condition     = var.database_disk_gb >= 10 && var.database_disk_gb <= 100
    error_message = "database_disk_gb debe estar entre 10 y 100 GB para la demo."
  }
}
