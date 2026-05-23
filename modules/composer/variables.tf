################################################################################
# modules/composer/variables.tf
################################################################################

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "env" {
  description = "Environment name. Prefixed onto the Composer environment name."
  type        = string
}

variable "region" {
  description = "GCP region for the Composer environment"
  type        = string
}

variable "image_version" {
  description = "Composer image version. From your snippet: 'composer-3-airflow-2'"
  type        = string
  default     = "composer-3-airflow-2"
}

variable "environment_size" {
  description = "Composer environment size: ENVIRONMENT_SIZE_SMALL / MEDIUM / LARGE"
  type        = string
  default     = "ENVIRONMENT_SIZE_SMALL"

  validation {
    condition = contains([
      "ENVIRONMENT_SIZE_SMALL",
      "ENVIRONMENT_SIZE_MEDIUM",
      "ENVIRONMENT_SIZE_LARGE"
    ], var.environment_size)
    error_message = "environment_size must be ENVIRONMENT_SIZE_SMALL, MEDIUM, or LARGE."
  }
}

variable "labels" {
  description = "Additional labels to merge onto the Composer environment"
  type        = map(string)
  default     = {}
}

# ── Workload component objects (matching your code snippet exactly) ────────────

variable "scheduler" {
  description = "Scheduler workload config. Matches scheduler {} block in your snippet."
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
    count      = number
  })
  default = {
    cpu        = 0.5
    memory_gb  = 2
    storage_gb = 1
    count      = 1
  }
}

variable "triggerer" {
  description = "Triggerer workload config. Matches triggerer {} block in your snippet."
  type = object({
    cpu       = number
    memory_gb = number
    count     = number
  })
  default = {
    cpu       = 0.5
    memory_gb = 1
    count     = 1
  }
}

variable "dag_processor" {
  description = "DAG processor config. Matches dag_processor {} block in your snippet."
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
    count      = number
  })
  default = {
    cpu        = 1
    memory_gb  = 2
    storage_gb = 1
    count      = 1
  }
}

variable "web_server" {
  description = "Web server config. Matches web_server {} block in your snippet."
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
  })
  default = {
    cpu        = 0.5
    memory_gb  = 2
    storage_gb = 1
  }
}

variable "worker" {
  description = "Worker config. Matches worker {} block in your snippet."
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
    min_count  = number
    max_count  = number
  })
  default = {
    cpu        = 0.5
    memory_gb  = 2
    storage_gb = 1
    min_count  = 1
    max_count  = 3
  }
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "composer_sa_email" {
  description = "Service account email for Composer nodes. Output from the IAM module."
  type        = string
}

variable "network_self_link" {
  description = "VPC network self-link. Output from the VPC module."
  type        = string
}

variable "subnetwork_self_link" {
  description = "Subnetwork self-link for Composer nodes. Output from the VPC module."
  type        = string
}

variable "pods_ip_range_name" {
  description = "Secondary IP range name for GKE pods (defined in the subnet)"
  type        = string
  default     = "pods"
}

variable "services_ip_range_name" {
  description = "Secondary IP range name for GKE services (defined in the subnet)"
  type        = string
  default     = "services"
}

# ── Maintenance Window ─────────────────────────────────────────────────────────

variable "maintenance_window" {
  description = "Optional maintenance window. Null disables the block entirely."
  type = object({
    start_time = string   # RFC3339 e.g. "2024-01-01T02:00:00Z"
    end_time   = string
    recurrence = string   # RRULE e.g. "FREQ=WEEKLY;BYDAY=SU"
  })
  default = null
}
