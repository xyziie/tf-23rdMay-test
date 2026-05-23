################################################################################
# modules/composer/main.tf
#
# Cloud Composer 3 environment — built from your provided code snippet.
# The snippet's hardcoded values are replaced with variables so dev and prod
# can share this module with different resource sizes and settings.
#
# Original snippet resources preserved exactly:
#   google_composer_environment   → parameterised
#   google_service_account        → moved to the IAM module (cleaner separation)
#   google_project_iam_member     → moved to the IAM module
#
# The service account EMAIL is received as an input from the IAM module output.
################################################################################

resource "google_composer_environment" "this" {
  project = var.project_id
  name    = "${var.env}-composer-env"
  region  = var.region

  labels = merge(
    {
      env     = var.env
      managed = "terraform"
    },
    var.labels
  )

  config {
    # ── Software config (from your snippet) ────────────────────────────────
    software_config {
      image_version = var.image_version   # "composer-3-airflow-2" from snippet
    }

    # ── Workloads config (from your snippet — all 5 components) ────────────
    workloads_config {

      scheduler {
        cpu        = var.scheduler.cpu
        memory_gb  = var.scheduler.memory_gb
        storage_gb = var.scheduler.storage_gb
        count      = var.scheduler.count
      }

      triggerer {
        cpu       = var.triggerer.cpu
        memory_gb = var.triggerer.memory_gb
        count     = var.triggerer.count
      }

      dag_processor {
        cpu        = var.dag_processor.cpu
        memory_gb  = var.dag_processor.memory_gb
        storage_gb = var.dag_processor.storage_gb
        count      = var.dag_processor.count
      }

      web_server {
        cpu        = var.web_server.cpu
        memory_gb  = var.web_server.memory_gb
        storage_gb = var.web_server.storage_gb
      }

      worker {
        cpu        = var.worker.cpu
        memory_gb  = var.worker.memory_gb
        storage_gb = var.worker.storage_gb
        min_count  = var.worker.min_count
        max_count  = var.worker.max_count
      }
    }

    environment_size = var.environment_size

    # ── Node config (from your snippet) ────────────────────────────────────
    # service_account wired from IAM module output — no hardcoding.
    node_config {
      service_account = var.composer_sa_email
      network         = var.network_self_link
      subnetwork      = var.subnetwork_self_link

      # Required for VPC-native GKE cluster (Composer 2/3 default)
      ip_allocation_policy {
        cluster_secondary_range_name  = var.pods_ip_range_name
        services_secondary_range_name = var.services_ip_range_name
      }
    }

    # ── Maintenance window ──────────────────────────────────────────────────
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        start_time = maintenance_window.value.start_time
        end_time   = maintenance_window.value.end_time
        recurrence = maintenance_window.value.recurrence
      }
    }
  }

  timeouts {
    create = "90m"
    update = "60m"
    delete = "60m"
  }
}
