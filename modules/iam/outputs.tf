################################################################################
# modules/iam/outputs.tf
################################################################################

output "composer_sa_email" {
  description = "Email of the Composer service account — passed to Composer node_config"
  value       = google_service_account.composer_sa.email
}

output "composer_sa_name" {
  description = "Name (account ID) of the Composer service account"
  value       = google_service_account.composer_sa.name
}

output "terraform_sa_email" {
  description = "Email of the Terraform deployment service account"
  value       = google_service_account.terraform_sa.email
}
