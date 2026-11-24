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
}

resource "google_kms_crypto_key" "storage" {
  name            = "${var.name_prefix}-${var.environment}-storage"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key" "secrets" {
  name            = "${var.name_prefix}-${var.environment}-secrets"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key" "logs" {
  name            = "${var.name_prefix}-${var.environment}-logs"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"
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
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "cloudsql" {
  crypto_key_id = google_kms_crypto_key.sql.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.cloudsql.email}"
}

resource "google_project_service_identity" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "secretmanager" {
  crypto_key_id = google_kms_crypto_key.secrets.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager.email}"
}

resource "google_kms_crypto_key_iam_member" "storage" {
  crypto_key_id = google_kms_crypto_key.storage.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "storage_logs" {
  crypto_key_id = google_kms_crypto_key.logs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_project_service_identity" "bigquery" {
  project = var.project_id
  service = "bigquery.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "bigquery_logs" {
  crypto_key_id = google_kms_crypto_key.logs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.bigquery.email}"
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

  versioning { enabled = true }

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

  versioning { enabled = true }

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

  versioning { enabled = true }

  retention_policy {
    retention_period = 7776000
    is_locked        = false
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.logs.id
  }
}

resource "google_secret_manager_secret" "app" {
  for_each = local.app_secrets

  project   = var.project_id
  secret_id = each.value
  labels    = local.labels_by_environment[each.value]

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

resource "google_sql_database_instance" "main" {
  project             = var.project_id
  name                = "${var.name_prefix}-${var.environment}-mysql"
  region              = var.region
  database_version    = "MYSQL_8_0"
  root_password       = null
  encryption_key_name = google_kms_crypto_key.sql.id
  deletion_protection = true
  depends_on          = [google_service_networking_connection.private_services, google_kms_crypto_key_iam_member.cloudsql]

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
      point_in_time_recovery_enabled = true
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
      ssl_mode                                      = "ENCRYPTED_ONLY"
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
