output "logs_dataset_id" { value = google_bigquery_dataset.logs.dataset_id }
output "sink_writer_identity" { value = google_logging_project_sink.security.writer_identity }
