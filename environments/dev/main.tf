################################################################################
# environments/dev/main.tf
#
# Wires the four modules in correct dependency order:
#   apis → iam → vpc → composer
#
# Dev uses small Composer resources (matching your snippet's defaults exactly).
################################################################################

# ── 1. APIs ───────────────────────────────────────────────────────────────────
# Must be first. All other modules depend on these APIs being active.
module "apis" {
  source = "../../modules/apis"

  gcp_project_id = var.project_id
  gcp_region     = var.region
  gcp_zone       = var.zone
}

# ── 2. IAM ────────────────────────────────────────────────────────────────────
# Creates the Composer SA and grants roles/composer.worker (your snippet pattern).
# Also creates the Terraform deployment SA.
module "iam" {
  source = "../../modules/iam"

  project_id = var.project_id
  env        = var.env

  project_iam_bindings = var.project_iam_bindings

  depends_on = [module.apis]
}

# ── 3. VPC ────────────────────────────────────────────────────────────────────
# Custom VPC with secondary ranges required by the GKE cluster Composer runs on.
module "vpc" {
  source = "../../modules/vpc"

  project_id       = var.project_id
  env              = var.env
  region           = var.region
  routing_mode     = "REGIONAL"
  enable_flow_logs = true

  subnets = [
    {
      name   = "dev-composer-subnet"
      region = var.region
      cidr   = "10.10.0.0/20"
      secondary_ranges = [
        # GKE requires two secondary ranges — one for Pods, one for Services.
        { range_name = "pods",     cidr = "10.20.0.0/16" },
        { range_name = "services", cidr = "10.30.0.0/20" },
      ]
    }
  ]

  depends_on = [module.apis]
}

# ── 4. Composer ───────────────────────────────────────────────────────────────
# Built from your code snippet. Dev uses the snippet's default resource values.
# SA email and network wired from IAM and VPC module outputs — no hardcoding.
module "composer" {
  source = "../../modules/composer"

  project_id = var.project_id
  env        = var.env
  region     = var.region

  # Snippet default: "composer-3-airflow-2"
  image_version    = "composer-3-airflow-2"
  environment_size = "ENVIRONMENT_SIZE_SMALL"

  # ── Workload config — matching your snippet's values exactly ──────────────
  scheduler = {
    cpu        = 0.5
    memory_gb  = 2
    storage_gb = 1
    count      = 1
  }

  triggerer = {
    cpu       = 0.5
    memory_gb = 1
    count     = 1
  }

  dag_processor = {
    cpu        = 1
    memory_gb  = 2
    storage_gb = 1
    count      = 1
  }

  web_server = {
    cpu        = 0.5
    memory_gb  = 2
    storage_gb = 1
  }

  worker = {
    cpu        = 0.5
    memory_gb  = 2
    storage_gb = 1
    min_count  = 1
    max_count  = 3
  }

  # ── Wired from module outputs — no magic strings ──────────────────────────
  composer_sa_email    = module.iam.composer_sa_email
  network_self_link    = module.vpc.network_self_link
  subnetwork_self_link = module.vpc.subnet_self_links["dev-composer-subnet"]

  pods_ip_range_name     = "pods"
  services_ip_range_name = "services"

  labels = {
    team = "platform"
  }

  maintenance_window = {
    start_time = "2024-01-01T02:00:00Z"
    end_time   = "2024-01-01T06:00:00Z"
    recurrence = "FREQ=WEEKLY;BYDAY=SU"
  }

  depends_on = [module.iam, module.vpc]
}
