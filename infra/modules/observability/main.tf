resource "google_bigquery_dataset" "logs" {
  project                     = var.project_id
  dataset_id                  = "${replace(var.name_prefix, "-", "_")}_${var.environment}_security_logs"
  friendly_name               = "AuroraShop Security Logs"
  description                 = "Eventos de auditoría de GCP y cargas de trabajo para SIEM."
  location                    = var.region
  default_table_expiration_ms = 7776000000
  delete_contents_on_destroy  = false
  labels                      = var.labels

  default_encryption_configuration {
    kms_key_name = var.logs_key_id
  }
}

resource "google_logging_project_sink" "security" {
  project                = var.project_id
  name                   = "${var.name_prefix}-${var.environment}-security-to-bigquery"
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"
  unique_writer_identity = true
  description            = "Auditoría de GCP y logs del namespace aurorashop."
  filter                 = <<-EOT
    logName:"cloudaudit.googleapis.com/activity"
    OR logName:"cloudaudit.googleapis.com/system_event"
    OR (resource.type="k8s_container" AND resource.labels.namespace_name=("aurorashop" OR "dev" OR "staging"))
    OR resource.type="cloudsql_database"
  EOT
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.security.writer_identity
}
