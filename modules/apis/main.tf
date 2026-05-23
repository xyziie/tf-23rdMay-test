################################################################################
# modules/apis/main.tf
#
# Enables all Google Cloud APIs required for Cloud Composer and supporting
# infrastructure. Split into logical batches using the CloudVLab module.
#
# IMPORTANT: This module must be applied before all other modules.
#            All environment main.tf files wire depends_on = [module.apis].
################################################################################

# ── Batch 1: Composer Core APIs ───────────────────────────────────────────────
# These are the mandatory APIs for Cloud Composer 2/3 to function.
module "apis_composer_core" {
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/api_service/dev"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  api_services = [
    "composer.googleapis.com",       # Cloud Composer itself
    "container.googleapis.com",      # GKE — Composer environments run on GKE
    "bigquery.googleapis.com",       # GKE + Airflow backend dependency
    "storage.googleapis.com",        # DAG sync and log files via GCS
    "sqladmin.googleapis.com",       # Airflow metadata database (Cloud SQL)
    "artifactregistry.googleapis.com", # Airflow worker Docker images
    "cloudbuild.googleapis.com",     # Custom image builds and env updates
    "pubsub.googleapis.com",         # Internal messaging and env sync
  ]
}

# ── Batch 2: Networking APIs ──────────────────────────────────────────────────
module "apis_networking" {
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/api_service/dev"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  api_services = [
    "compute.googleapis.com",            # VPC, subnets, firewall, Cloud NAT
    "servicenetworking.googleapis.com",  # Private Service Connect / VPC peering
    "dns.googleapis.com",                # Cloud DNS for private zones
    "networkmanagement.googleapis.com",  # Network Intelligence Center
  ]
}

# ── Batch 3: IAM & Security APIs ─────────────────────────────────────────────
module "apis_iam_security" {
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/api_service/dev"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  api_services = [
    "iam.googleapis.com",                    # Identity and Access Management
    "iamcredentials.googleapis.com",         # SA key / Workload Identity Federation
    "cloudresourcemanager.googleapis.com",   # Project/folder/org management
    "secretmanager.googleapis.com",          # Store secrets (DB passwords, keys)
    "cloudkms.googleapis.com",               # Customer-managed encryption keys
  ]
}

# ── Batch 4: Observability APIs ───────────────────────────────────────────────
module "apis_observability" {
  source = "github.com/CloudVLab/terraform-lab-foundation//basics/api_service/dev"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  api_services = [
    "logging.googleapis.com",             # Cloud Logging
    "monitoring.googleapis.com",          # Cloud Monitoring and alerting
    "cloudtrace.googleapis.com",          # Distributed tracing
    "clouderrorreporting.googleapis.com", # Error Reporting
    "serviceusage.googleapis.com",        # Required to enable other APIs
  ]
}
