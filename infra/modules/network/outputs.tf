output "network_id" { value = google_compute_network.main.id }
output "subnetwork_id" { value = google_compute_subnetwork.main.id }
output "private_service_range" { value = google_compute_global_address.private_services.name }
output "pods_range_name" { value = "${var.name_prefix}-pods" }
output "services_range_name" { value = "${var.name_prefix}-services" }
