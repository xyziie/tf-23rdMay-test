################################################################################
# environments/dev/backend.tf
#
# Remote state is stored in GCS with versioning enabled (bucket created by
# bootstrap/create_state_bucket.sh before first apply).
#
# bucket and prefix are injected at `terraform init` time via -backend-config
# flags passed from cloudbuild.yaml — nothing is hardcoded here.
################################################################################

terraform {
  backend "gcs" {
    # Injected by Cloud Build:
    # -backend-config=bucket=tf-state-<PROJECT_ID>-dev
    # -backend-config=prefix=terraform/state
  }
}
