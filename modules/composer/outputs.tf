################################################################################
# modules/composer/outputs.tf
################################################################################

output "composer_env_name" {
  description = "Name of the Cloud Composer environment"
  value       = google_composer_environment.this.name
}

output "composer_env_id" {
  description = "Full resource ID of the Composer environment"
  value       = google_composer_environment.this.id
}

output "airflow_uri" {
  description = "Airflow web UI URI"
  value       = google_composer_environment.this.config[0].airflow_uri
}

output "dag_gcs_bucket" {
  description = "GCS bucket prefix where DAGs should be uploaded"
  value       = google_composer_environment.this.config[0].dag_gcs_prefix
}

output "gke_cluster" {
  description = "GKE cluster backing the Composer environment"
  value       = google_composer_environment.this.config[0].gke_cluster
}
