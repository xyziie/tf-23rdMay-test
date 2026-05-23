################################################################################
# environments/prod/terraform.tfvars
#
# ⚠️  Replace project_id with your real GCP prod project ID.
# ⚠️  Do NOT commit real secrets here — use Secret Manager or GitHub Secrets.
################################################################################

project_id = "my-gcp-project-prod"   # ← replace
region     = "us-central1"
zone       = "us-central1-a"
env        = "prod"

project_iam_bindings = [
  {
    role    = "roles/viewer"
    members = ["group:prod-viewers@example.com"]
  },
  {
    role    = "roles/editor"
    members = ["group:prod-engineers@example.com"]
  },
]
