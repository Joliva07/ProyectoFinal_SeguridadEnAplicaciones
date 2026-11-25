resource "google_kms_key_ring" "main" {
  project  = var.project_id
  name     = "${var.name_prefix}-${var.environment}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "sql" {
  name            = "${var.name_prefix}-${var.environment}-sql"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "storage" {
  name            = "${var.name_prefix}-${var.environment}-storage"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "secrets" {
  name            = "${var.name_prefix}-${var.environment}-secrets"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "logs" {
  name            = "${var.name_prefix}-${var.environment}-logs"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  environments = toset(["dev", "staging", "demo"])
  labels_by_environment = {
    for environment in local.environments : environment => merge(var.labels, { ambiente = environment })
  }
  app_secrets = merge([
    for environment in local.environments : {
      for suffix in ["auth-keys", "salts", "payment-sandbox"] :
      "${var.name_prefix}-${environment}-${suffix}" => environment
    }
  ]...)
}

resource "google_project_service_identity" "cloudsql" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "cloudsql" {
  crypto_key_id = google_kms_crypto_key.sql.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.cloudsql.email}"
}

resource "google_project_service_identity" "secretmanager" {
  provider = google-beta
  project  = var.project_id
  service  = "secretmanager.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "secretmanager" {
  crypto_key_id = google_kms_crypto_key.secrets.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager.email}"
}

resource "google_project_service_identity" "storage" {
  provider = google-beta
  project  = var.project_id
  service  = "storage.googleapis.com"
}

resource "google_project_service_identity" "artifact_registry" {
  provider = google-beta
  project  = var.project_id
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "storage" {
  crypto_key_id = google_kms_crypto_key.storage.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
  depends_on    = [google_project_service_identity.storage]
}

resource "google_kms_crypto_key_iam_member" "storage_logs" {
  crypto_key_id = google_kms_crypto_key.logs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
  depends_on    = [google_project_service_identity.storage]
}

resource "google_kms_crypto_key_iam_member" "artifact_registry" {
  crypto_key_id = google_kms_crypto_key.storage.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
  depends_on    = [google_project_service_identity.artifact_registry]
}

resource "google_project_service_identity" "bigquery" {
  provider = google-beta
  project  = var.project_id
  service  = "bigquery.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "bigquery_logs" {
  crypto_key_id = google_kms_crypto_key.logs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${var.project_number}@bigquery-encryption.iam.gserviceaccount.com"
}

# Bucket receptor de access logs. No se registra a sí mismo para evitar recursión.
#checkov:skip=CKV_GCP_62:Un bucket de logs no puede registrar su propio acceso sin recursión.
resource "google_storage_bucket" "access_logs" { # nosemgrep: terraform.gcp.security.gcp-cloud-storage-logging.gcp-cloud-storage-logging
  project                     = var.project_id
  name                        = "${var.name_prefix}-access-logs-${var.project_id}-${var.environment}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = var.labels

  versioning { enabled = true }

  lifecycle_rule {
    condition { age = 30 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "media" {
  for_each                    = local.environments
  project                     = var.project_id
  name                        = "${var.name_prefix}-media-${var.project_id}-${each.value}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels_by_environment[each.value]
  depends_on                  = [google_kms_crypto_key_iam_member.storage]

  versioning { enabled = true }

  logging {
    log_bucket = google_storage_bucket.access_logs.name
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage.id
  }
}

resource "google_storage_bucket" "backups" {
  for_each                    = local.environments
  project                     = var.project_id
  name                        = "${var.name_prefix}-backups-${var.project_id}-${each.value}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels_by_environment[each.value]
  depends_on                  = [google_kms_crypto_key_iam_member.storage]

  versioning { enabled = true }

  logging {
    log_bucket = google_storage_bucket.access_logs.name
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage.id
  }
}

resource "google_storage_bucket" "logs_archive" {
  project                     = var.project_id
  name                        = "${var.name_prefix}-logs-archive-${var.project_id}-${var.environment}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = var.labels
  depends_on                  = [google_kms_crypto_key_iam_member.storage_logs]

  versioning { enabled = true }

  logging {
    log_bucket = google_storage_bucket.access_logs.name
  }

  retention_policy {
    retention_period = 7776000
    is_locked        = false
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.logs.id
  }
}

# Cuenta de servicio documentada por Cloudflare para Logpush a GCS.
# Solo escribe en el bucket de archivo de logs, no en el resto del proyecto.
resource "google_storage_bucket_iam_member" "cloudflare_logpush" { #tfsec:ignore:AVD-GCP-0007:Cloudflare exige objectAdmin solo en el bucket de logs para el ownership challenge y la escritura.
  bucket = google_storage_bucket.logs_archive.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:logpush@cloudflare-data.iam.gserviceaccount.com"
}

resource "google_secret_manager_secret" "app" {
  for_each = local.app_secrets

  project    = var.project_id
  secret_id  = each.key
  labels     = local.labels_by_environment[each.value]
  depends_on = [google_kms_crypto_key_iam_member.secretmanager]

  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets.id
        }
      }
    }
  }
}

resource "google_sql_database_instance" "main" { #tfsec:ignore:AVD-GCP-0015:Cloud SQL Auth Proxy con IAM usa TLS sin certificado de cliente; ssl_mode=ENCRYPTED_ONLY exige cifrado.
  project             = var.project_id
  name                = "${var.name_prefix}-${var.environment}-mysql"
  region              = var.region
  database_version    = "MYSQL_8_0"
  root_password       = null
  encryption_key_name = google_kms_crypto_key.sql.id
  deletion_protection = true
  depends_on          = [google_kms_crypto_key_iam_member.cloudsql]

  settings {
    tier                  = var.database_tier
    availability_type     = "ZONAL"
    disk_type             = "PD_SSD"
    disk_size             = var.database_disk_gb
    disk_autoresize       = true
    disk_autoresize_limit = 50
    user_labels           = var.labels

    backup_configuration {
      enabled                        = true
      start_time                     = "07:00"
      binary_log_enabled             = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      allocated_ip_range                            = var.private_ip_range
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY" # nosemgrep: terraform.gcp.security.gcp-sql-database-ssl-insecure-value-postgres-mysql.gcp-sql-database-ssl-insecure-value-postgres-mysql
    }

    database_flags {
      name  = "cloudsql_iam_authentication"
      value = "on"
    }
  }
}

resource "google_sql_database" "wordpress" {
  for_each  = local.environments
  project   = var.project_id
  name      = "aurorashop_${each.value}"
  instance  = google_sql_database_instance.main.name
  charset   = "utf8mb4"
  collation = "utf8mb4_0900_ai_ci"
}

output "database_instance_name" {
  value = google_sql_database_instance.main.name
}

output "media_bucket_name" {
  value = google_storage_bucket.media["demo"].name
}

output "media_bucket_names" {
  value = { for environment, bucket in google_storage_bucket.media : environment => bucket.name }
}

output "backup_bucket_name" {
  value = google_storage_bucket.backups["demo"].name
}

output "logs_archive_bucket_name" {
  value = google_storage_bucket.logs_archive.name
}

output "database_private_ip" {
  value = one(google_sql_database_instance.main.ip_address[*].ip_address)
}

output "database_connection_name" {
  value = google_sql_database_instance.main.connection_name
}

output "database_name" {
  value = google_sql_database.wordpress["demo"].name
}

output "database_names" {
  value = { for environment, database in google_sql_database.wordpress : environment => database.name }
}

output "secret_ids" {
  value = {
    for name, secret in google_secret_manager_secret.app : name => {
      secret_id   = secret.secret_id
      environment = local.app_secrets[name]
    }
  }
}

output "sql_key_id" { value = google_kms_crypto_key.sql.id }
output "storage_key_id" { value = google_kms_crypto_key.storage.id }
output "secrets_key_id" { value = google_kms_crypto_key.secrets.id }
output "logs_key_id" { value = google_kms_crypto_key.logs.id }
