################################################################################
# environments/prod/main.tf
#
# Production environment. Key differences from dev:
#   - Composer: MEDIUM size, higher CPU/memory, 2 schedulers (HA), more workers
#   - VPC: GLOBAL routing, two subnets (primary + secondary region), flow logs
#   - Composer: maintenance window on Saturday night (low-traffic window)
################################################################################

# ── 1. APIs ───────────────────────────────────────────────────────────────────
module "apis" {
  source = "../../modules/apis"

  gcp_project_id = var.project_id
  gcp_region     = var.region
  gcp_zone       = var.zone
}

# ── 2. IAM ────────────────────────────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  project_id = var.project_id
  env        = var.env

  project_iam_bindings = var.project_iam_bindings

  depends_on = [module.apis]
}

# ── 3. VPC ────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_id       = var.project_id
  env              = var.env
  region           = var.region
  routing_mode     = "GLOBAL"    # prod routes across regions
  enable_flow_logs = true

  subnets = [
    {
      name   = "prod-composer-subnet"
      region = var.region
      cidr   = "10.100.0.0/20"
      secondary_ranges = [
        { range_name = "pods",     cidr = "10.200.0.0/16" },
        { range_name = "services", cidr = "10.210.0.0/20" },
      ]
    },
    # Secondary subnet in a different zone for resilience
    {
      name             = "prod-composer-subnet-secondary"
      region           = var.region
      cidr             = "10.110.0.0/20"
      secondary_ranges = []
    }
  ]

  depends_on = [module.apis]
}

# ── 4. Composer ───────────────────────────────────────────────────────────────
# Production: MEDIUM size, 2 schedulers for HA, larger workers, more replicas.
module "composer" {
  source = "../../modules/composer"

  project_id = var.project_id
  env        = var.env
  region     = var.region

  image_version    = "composer-3-airflow-2"
  environment_size = "ENVIRONMENT_SIZE_MEDIUM"

  # ── Scheduler: 2 replicas for high availability ───────────────────────────
  scheduler = {
    cpu        = 2
    memory_gb  = 7.5
    storage_gb = 10
    count      = 2    # HA — one scheduler can fail without downtime
  }

  # ── Triggerer: handles async operators (e.g. BigQueryInsertJobOperator) ───
  triggerer = {
    cpu       = 1
    memory_gb = 2
    count     = 2
  }

  # ── DAG processor: parses and schedules DAGs ──────────────────────────────
  dag_processor = {
    cpu        = 2
    memory_gb  = 4
    storage_gb = 5
    count      = 2
  }

  # ── Web server: Airflow UI ─────────────────────────────────────────────────
  web_server = {
    cpu        = 1
    memory_gb  = 4
    storage_gb = 5
  }

  # ── Workers: auto-scale 3–10 based on task queue depth ────────────────────
  worker = {
    cpu        = 2
    memory_gb  = 7.5
    storage_gb = 10
    min_count  = 3
    max_count  = 10
  }

  # ── Wired from module outputs ─────────────────────────────────────────────
  composer_sa_email    = module.iam.composer_sa_email
  network_self_link    = module.vpc.network_self_link
  subnetwork_self_link = module.vpc.subnet_self_links["prod-composer-subnet"]

  pods_ip_range_name     = "pods"
  services_ip_range_name = "services"

  labels = {
    team        = "platform"
    criticality = "high"
  }

  # Saturday night maintenance window (minimal traffic)
  maintenance_window = {
    start_time = "2024-01-01T03:00:00Z"
    end_time   = "2024-01-01T07:00:00Z"
    recurrence = "FREQ=WEEKLY;BYDAY=SA"
  }

  depends_on = [module.iam, module.vpc]
}
