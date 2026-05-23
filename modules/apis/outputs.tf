################################################################################
# modules/apis/outputs.tf
#
# These outputs exist so other modules can declare:
#   depends_on = [module.apis]
# ensuring APIs are active before any resource that needs them is created.
################################################################################

output "composer_apis_id" {
  description = "ID signal that Composer core APIs are enabled"
  value       = module.apis_composer_core
}

output "networking_apis_id" {
  description = "ID signal that networking APIs are enabled"
  value       = module.apis_networking
}

output "iam_security_apis_id" {
  description = "ID signal that IAM and security APIs are enabled"
  value       = module.apis_iam_security
}

output "observability_apis_id" {
  description = "ID signal that observability APIs are enabled"
  value       = module.apis_observability
}
