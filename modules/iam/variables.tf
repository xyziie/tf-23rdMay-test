################################################################################
# modules/iam/variables.tf
################################################################################

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "env" {
  description = "Environment name (dev, prod). Appended to resource names."
  type        = string
}

variable "project_iam_bindings" {
  description = <<-EOT
    List of project-level IAM bindings for human users and groups.
    Example:
      [
        {
          role    = "roles/viewer"
          members = ["group:dev-team@example.com"]
        }
      ]
  EOT
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}
