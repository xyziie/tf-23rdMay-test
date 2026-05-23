################################################################################
# modules/iam/main.tf
#
# Manages IAM for the environment:
#   1. Creates the Composer service account (matches your code snippet pattern)
#   2. Grants roles/composer.worker to that SA  (from your snippet)
#   3. Grants additional roles needed for Composer to function
#   4. Manages broader project-level IAM bindings (human users/groups)
#   5. Optionally creates extra service accounts for other workloads
################################################################################

# ── Composer Service Account ──────────────────────────────────────────────────
# Mirrors exactly the google_service_account.test block in your code snippet.
resource "google_service_account" "composer_sa" {
  project      = var.project_id
  account_id   = "composer-env-account-${var.env}"
  display_name = "Composer Environment SA (${var.env})"
  description  = "Service account used by Cloud Composer worker nodes"
}

# ── Composer Worker Role ──────────────────────────────────────────────────────
# Mirrors exactly google_project_iam_member.composer-worker in your snippet.
resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

# ── Additional Roles Required by Composer ────────────────────────────────────
# The composer.worker role alone is not sufficient. These additional bindings
# are required for the environment to create and manage its GKE cluster,
# pull images, write logs, and access secrets.
locals {
  composer_required_roles = [
    "roles/container.developer",         # Manage GKE workloads
    "roles/artifactregistry.reader",     # Pull Airflow worker images
    "roles/storage.objectAdmin",         # Read/write DAGs and logs in GCS
    "roles/logging.logWriter",           # Write logs to Cloud Logging
    "roles/monitoring.metricWriter",     # Push metrics to Cloud Monitoring
    "roles/bigquery.dataEditor",         # BigQuery access from DAGs
    "roles/secretmanager.secretAccessor",# Access secrets from DAGs
  ]
}

resource "google_project_iam_member" "composer_additional_roles" {
  for_each = toset(local.composer_required_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

# ── Cloud Build / Terraform Service Account ───────────────────────────────────
# Used by Cloud Build to run Terraform apply.
resource "google_service_account" "terraform_sa" {
  project      = var.project_id
  account_id   = "terraform-deploy-${var.env}"
  display_name = "Terraform Deployment SA (${var.env})"
  description  = "Used by Cloud Build to deploy infrastructure via Terraform"
}

resource "google_project_iam_member" "terraform_sa_roles" {
  for_each = toset([
    "roles/editor",
    "roles/iam.securityAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/storage.admin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# ── Human / Group Project-Level Bindings ──────────────────────────────────────
# Flattened from the var.project_iam_bindings list so each role/member pair
# gets its own resource (avoids authoritative binding conflicts).
locals {
  flat_bindings = flatten([
    for b in var.project_iam_bindings : [
      for m in b.members : {
        role   = b.role
        member = m
      }
    ]
  ])
}

resource "google_project_iam_member" "human_bindings" {
  for_each = {
    for b in local.flat_bindings : "${b.role}__${b.member}" => b
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}
