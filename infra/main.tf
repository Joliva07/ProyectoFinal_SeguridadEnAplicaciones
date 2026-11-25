data "google_project" "current" {
  project_id = var.project_id
}

data "http" "cloudflare_ip_ranges" {
  url                = "https://api.cloudflare.com/client/v4/ips"
  request_timeout_ms = 10000
}

locals {
  cloudflare_response = try(jsondecode(data.http.cloudflare_ip_ranges.response_body), {})
  cloudflare_cidrs = try(concat(
    local.cloudflare_response.result.ipv4_cidrs,
    local.cloudflare_response.result.ipv6_cidrs,
  ), [])

  common_labels = {
    proyecto = "aurorashop"
    ambiente = var.environment
    curso    = "seguridad-apps"
  }
}

resource "google_project_service" "required" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "gkeconnect.googleapis.com",
    "connectgateway.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "network" {
  source = "./modules/network"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  labels      = local.common_labels
  depends_on  = [google_project_service.required]
}

module "data" {
  source = "./modules/data"

  project_id       = var.project_id
  project_number   = data.google_project.current.number
  region           = var.region
  environment      = var.environment
  name_prefix      = var.name_prefix
  network_id       = module.network.network_id
  private_ip_range = module.network.private_service_range
  labels           = local.common_labels
  database_tier    = var.database_tier
  database_disk_gb = var.database_disk_gb
  depends_on       = [google_project_service.required, module.network]
}

module "compute" {
  source = "./modules/compute"

  project_id                = var.project_id
  region                    = var.region
  environment               = var.environment
  name_prefix               = var.name_prefix
  network_id                = module.network.network_id
  subnetwork_id             = module.network.subnetwork_id
  cluster_pods_range        = module.network.pods_range_name
  cluster_services_range    = module.network.services_range_name
  cloudflare_cidrs          = local.cloudflare_cidrs
  workload_account_id       = "sa-gke-workload"
  media_buckets             = module.data.media_bucket_names
  secret_ids                = module.data.secret_ids
  database_instance_name    = module.data.database_instance_name
  artifact_registry_kms_key = module.data.storage_key_id
  labels                    = local.common_labels
  depends_on                = [google_project_service.required, module.network, module.data]
}

module "observability" {
  source = "./modules/observability"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  name_prefix = var.name_prefix
  logs_key_id = module.data.logs_key_id
  labels      = local.common_labels
  depends_on  = [google_project_service.required, module.data]
}
