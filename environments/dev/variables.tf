################################################################################
# environments/dev/variables.tf
################################################################################

variable "project_id" {
  description = "GCP Project ID for the dev environment"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Primary GCP zone (used by the APIs module)"
  type        = string
  default     = "us-central1-a"
}

variable "env" {
  description = "Environment name — used as a prefix on all resource names"
  type        = string
  default     = "dev"
}

variable "project_iam_bindings" {
  description = "Project-level IAM bindings for human users and groups"
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}
