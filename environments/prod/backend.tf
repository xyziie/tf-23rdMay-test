################################################################################
# environments/prod/backend.tf
#
# Remote state stored in a separate GCS bucket from dev — complete isolation.
# bucket and prefix injected at `terraform init` via -backend-config in
# cloudbuild.yaml.
################################################################################

terraform {
  backend "gcs" {
    # Injected by Cloud Build:
    # -backend-config=bucket=tf-state-<PROJECT_ID>-prod
    # -backend-config=prefix=terraform/state
  }
}
