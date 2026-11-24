output "cluster_name" { value = google_container_cluster.main.name }
output "cluster_membership" { value = google_gke_hub_membership.main.membership_id }
output "artifact_registry_repository" { value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}" }
output "ingress_ip" { value = google_compute_global_address.ingress.address }
output "staging_ingress_ip" { value = google_compute_global_address.staging_ingress.address }
output "workload_service_account" { value = google_service_account.workload.email }
output "cloud_armor_policy_name" { value = google_compute_security_policy.edge.name }
