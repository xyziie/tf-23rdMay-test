################################################################################
# environments/dev/terraform.tfvars
#
# ⚠️  Replace project_id with your real GCP dev project ID.
# ⚠️  Do NOT commit real secrets here — use Secret Manager or GitHub Secrets.
################################################################################

project_id = "my-gcp-project-dev"   # ← replace
region     = "us-central1"
zone       = "us-central1-a"
env        = "dev"

project_iam_bindings = [
  {
    role    = "roles/viewer"
    members = ["group:dev-viewers@example.com"]
  },
  {
    role    = "roles/editor"
    members = ["group:dev-engineers@example.com"]
  },
]
