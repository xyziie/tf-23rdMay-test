################################################################################
# modules/apis/variables.tf
################################################################################

variable "gcp_project_id" {
  description = "GCP Project ID in which to enable the APIs"
  type        = string
}

variable "gcp_region" {
  description = "GCP region (passed through to the CloudVLab api_service module)"
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone (passed through to the CloudVLab api_service module)"
  type        = string
}
