################################################################################
# environments/prod/outputs.tf
################################################################################

output "composer_airflow_uri" {
  description = "Airflow web UI — open this in your browser"
  value       = module.composer.airflow_uri
}

output "composer_dag_bucket" {
  description = "Upload your DAG files here"
  value       = module.composer.dag_gcs_bucket
}

output "composer_gke_cluster" {
  description = "GKE cluster backing the Composer environment"
  value       = module.composer.gke_cluster
}

output "composer_sa_email" {
  description = "Composer service account email"
  value       = module.iam.composer_sa_email
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "subnet_cidrs" {
  description = "Subnet CIDRs"
  value       = module.vpc.subnet_cidrs
}
