#!/usr/bin/env bash
################################################################################
# bootstrap/create_state_buckets.sh
#
# Run ONCE manually before the first Terraform apply.
# Creates a dedicated GCS bucket per environment for remote state,
# with versioning enabled so you can roll back to any previous state.
#
# Usage:
#   chmod +x bootstrap/create_state_buckets.sh
#   ./bootstrap/create_state_buckets.sh <DEV_PROJECT_ID> <PROD_PROJECT_ID> [REGION]
#
# Example:
#   ./bootstrap/create_state_buckets.sh my-project-dev my-project-prod us-central1
################################################################################

set -euo pipefail

DEV_PROJECT="${1:?ERROR: Provide dev project ID as first argument}"
PROD_PROJECT="${2:?ERROR: Provide prod project ID as second argument}"
REGION="${3:-us-central1}"

create_bucket() {
  local PROJECT="$1"
  local ENV="$2"
  local BUCKET="tf-state-${PROJECT}-${ENV}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Environment : ${ENV}"
  echo "  Project     : ${PROJECT}"
  echo "  Bucket      : gs://${BUCKET}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Create bucket if it doesn't already exist
  if gsutil ls -b "gs://${BUCKET}" &>/dev/null; then
    echo "  ✓ Bucket already exists — skipping creation."
  else
    gsutil mb \
      -p "${PROJECT}" \
      -l "${REGION}" \
      -b on \
      "gs://${BUCKET}"
    echo "  ✓ Bucket created."
  fi

  # Enable versioning — allows rollback to any previous .tfstate
  gsutil versioning set on "gs://${BUCKET}"
  echo "  ✓ Object versioning enabled."

  # Uniform bucket-level access — simpler, more secure than ACLs
  gsutil uniformbucketlevelaccess set on "gs://${BUCKET}"
  echo "  ✓ Uniform bucket-level access enabled."

  # Block all public access
  gsutil pap set enforced "gs://${BUCKET}"
  echo "  ✓ Public access prevention enforced."

  echo ""
  echo "  Bucket ready: gs://${BUCKET}"
}

create_bucket "${DEV_PROJECT}"  "dev"
create_bucket "${PROD_PROJECT}" "prod"

echo ""
echo "✅  Both state buckets are ready."
echo ""
echo "    Cloud Build will pass these bucket names via -backend-config:"
echo "    Dev:  tf-state-${DEV_PROJECT}-dev"
echo "    Prod: tf-state-${PROD_PROJECT}-prod"
echo ""
echo "    Next steps:"
echo "    1. Set up Workload Identity Federation (see README.md)"
echo "    2. Add GitHub Secrets (GCP_PROJECT_ID_DEV, GCP_PROJECT_ID_PROD,"
echo "       GCP_WORKLOAD_IDENTITY_PROVIDER, GCP_SA_EMAIL)"
echo "    3. Push to the 'develop' branch to trigger the dev deployment"
