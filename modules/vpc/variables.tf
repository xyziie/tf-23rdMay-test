################################################################################
# modules/vpc/variables.tf
################################################################################

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "env" {
  description = "Environment name (dev, prod). Used as a prefix in resource names."
  type        = string
}

variable "region" {
  description = "Primary GCP region for Cloud Router and NAT"
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode. REGIONAL keeps routing within region; GLOBAL shares routes across regions."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  description = "List of subnets to create inside the VPC."
  type = list(object({
    name   = string
    region = string
    cidr   = string
    secondary_ranges = optional(list(object({
      range_name = string
      cidr       = string
    })), [])
  }))
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs on all subnets. Recommended true for prod."
  type        = bool
  default     = true
}
