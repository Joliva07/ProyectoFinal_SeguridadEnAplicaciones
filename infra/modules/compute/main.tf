locals {
  environments = {
    dev     = "dev"
    staging = "staging"
    demo    = "aurorashop"
  }
  workload_pool = "${var.project_id}.svc.id.goog"
}

resource "google_service_account" "workload" {
  for_each     = local.environments
  project      = var.project_id
  account_id   = "${var.workload_account_id}-${each.key}"
  display_name = "AuroraShop GKE workload ${each.key}"
  description  = "Identidad de Workload Identity para el ambiente ${each.key}."
}

resource "google_project_iam_member" "workload_sql_client" {
  for_each = google_service_account.workload
  project  = var.project_id
  role     = "roles/cloudsql.client"
  member   = "serviceAccount:${each.value.email}"
}

resource "google_project_iam_member" "workload_sql_login" {
  for_each = google_service_account.workload
  project  = var.project_id
  role     = "roles/cloudsql.instanceUser"
  member   = "serviceAccount:${each.value.email}"
}

resource "google_service_account_iam_member" "workload_identity" {
  for_each           = google_service_account.workload
  service_account_id = each.value.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.workload_pool}[${local.environments[each.key]}/aurorashop-app]"
}

resource "google_storage_bucket_iam_member" "media_writer" {
  for_each = var.media_buckets
  bucket   = each.value
  role     = "roles/storage.objectUser"
  member   = "serviceAccount:${google_service_account.workload[each.key].email}"
}

resource "google_secret_manager_secret_iam_member" "workload_secret_reader" {
  for_each  = var.secret_ids
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.workload[each.value.environment].email}"
}

resource "google_sql_user" "workload_iam_user" {
  for_each = google_service_account.workload
  project  = var.project_id
  name     = each.value.email
  instance = var.database_instance_name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = var.name_prefix
  description   = "Imágenes verificadas de AuroraShop."
  format        = "DOCKER"
  labels        = var.labels
}

resource "google_compute_global_address" "ingress" {
  project      = var.project_id
  name         = "${var.name_prefix}-demo-ingress-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  network_tier = "PREMIUM"
}

resource "google_compute_global_address" "staging_ingress" {
  project      = var.project_id
  name         = "${var.name_prefix}-staging-ingress-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  network_tier = "PREMIUM"
}

resource "google_compute_security_policy" "edge" {
  project     = var.project_id
  name        = "${var.name_prefix}-${var.environment}-edge"
  description = "Cloud Armor: solo acepta rangos de Cloudflare y aplica reglas administradas OWASP."
  type        = "CLOUD_ARMOR"

  rule {
    action      = "deny(403)"
    priority    = 100
    description = "Reglas WAF administradas contra SQLi."
    preview     = false

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 110
    description = "Reglas WAF administradas contra XSS."
    preview     = false

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  dynamic "rule" {
    for_each = { for index, cidrs in chunklist(var.cloudflare_cidrs, 10) : index => cidrs }
    content {
      action      = "allow"
      priority    = 1000 + tonumber(rule.key)
      description = "Permite tráfico de Cloudflare (grupo ${tonumber(rule.key) + 1})."
      preview     = false

      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = rule.value
        }
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 2147483647
    description = "Deniega tráfico fuera de Cloudflare."
    preview     = false

    match {
      versioned_expr = "SRC_IPS_V1"
      config { src_ip_ranges = ["*"] }
    }
  }
}

resource "google_container_cluster" "main" {
  project             = var.project_id
  name                = "${var.name_prefix}-gke"
  location            = var.region
  enable_autopilot    = true
  network             = var.network_id
  subnetwork          = var.subnetwork_id
  deletion_protection = true
  enable_legacy_abac  = false
  networking_mode     = "VPC_NATIVE"
  release_channel { channel = "REGULAR" }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_pods_range
    services_secondary_range_name = var.cluster_services_range
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    master_global_access_config { enabled = false }
  }

  master_auth {
    client_certificate_config { issue_client_certificate = false }
  }

  workload_identity_config {
    workload_pool = local.workload_pool
  }

  secret_manager_config {
    enabled = true
    rotation_config {
      enabled           = true
      rotation_interval = "120s"
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  resource_labels = var.labels

}

resource "google_gke_hub_membership" "main" {
  project       = var.project_id
  membership_id = "${var.name_prefix}-${var.environment}"
  location      = "global"

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.main.id}"
    }
  }
}

resource "google_project_iam_member" "deployer_cluster_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${var.deployer_service_account_email}"
}

resource "google_project_iam_member" "deployer_gateway_viewer" {
  project = var.project_id
  role    = "roles/gkehub.viewer"
  member  = "serviceAccount:${var.deployer_service_account_email}"
}

resource "google_project_iam_member" "deployer_gateway_editor" {
  project = var.project_id
  role    = "roles/gkehub.gatewayEditor"
  member  = "serviceAccount:${var.deployer_service_account_email}"
}

resource "google_project_iam_member" "deployer_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.deployer_service_account_email}"
}
