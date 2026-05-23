# GCP Terraform — Cloud Composer Infrastructure

## Project structure

```
gcp-tf-v2/
├── .github/
│   └── workflows/
│       ├── terraform-dev.yml           DEV workflow  (plan on push/PR, apply on merge)
│       └── terraform-prod.yml          PROD workflow (plan on PR,       apply on merge)
├── bootstrap/
│   └── create_state_buckets.sh         Run once before first deploy
├── modules/
│   ├── apis/                           API enablement (CloudVLab source)
│   ├── iam/                            Service accounts + IAM bindings
│   ├── vpc/                            Custom VPC, subnets, Cloud NAT, firewall
│   └── composer/                       Cloud Composer 3 environment
└── environments/
    ├── dev/
    │   ├── backend.tf                  GCS backend (bucket injected at init)
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars            ← edit with your dev project ID
    │   ├── main.tf
    │   └── outputs.tf
    └── prod/
        └── (same structure as dev)
```

---


## Branch strategy & trigger map

```
feature/* ──► develop ──► main
```

| Event | Branch | Workflow | Action |
|---|---|---|---|
| Push | `develop` | terraform-dev | **Plan** dev |
| PR open/update | → `develop` | terraform-dev | **Plan** dev + comment on PR |
| PR merged | → `main` | terraform-dev | **Apply** dev |
| PR open/update | → `main` | terraform-prod | **Plan** prod + comment on PR |
| PR merged | → `main` | terraform-prod | **Apply** prod (requires approval) |

### Key rule
> Code pushed to `develop` → **plan only, never apply**.
> Only a merge into `main` triggers apply — and prod apply requires a manual approval gate.

---

## CI/CD flow diagram

```
Developer
  │
  ├─► push to feature/* ──────────────────────────────────► (no workflow runs)
  │
  ├─► push to develop ────────────────────────────────────► terraform-dev
  │     └── Plan dev (validate code is correct)                └── PLAN only
  │
  ├─► open PR: feature → develop ─────────────────────────► terraform-dev
  │     └── Plan dev + post result as PR comment               └── PLAN only
  │
  ├─► merge PR: develop → main ───────────────────────────► terraform-dev  +  terraform-prod
  │     │                                                       │                  │
  │     │                                                    APPLY dev          PLAN prod
  │     │                                                                       + PR comment
  │     │
  │     └─► open PR: develop → main ──────────────────────► terraform-prod
  │           └── Plan prod + post result as PR comment        └── PLAN only
  │
  └─► merge PR: * → main ─────────────────────────────────► terraform-prod
        └── Manual approval required (GitHub Environment)      └── APPLY prod
```

---

## GitHub setup (one-time)

### Step 1 — Enable APIs in your projects

```bash
for PROJECT in my-project-dev my-project-prod; do
  gcloud services enable \
    cloudresourcemanager.googleapis.com \
    serviceusage.googleapis.com \
    iam.googleapis.com \
    --project="${PROJECT}"
done
```

### Step 2 — Create GCS state buckets

```bash
chmod +x bootstrap/create_state_buckets.sh
./bootstrap/create_state_buckets.sh my-project-dev my-project-prod us-central1
```

Creates:
- `gs://tf-state-my-project-dev-dev`   — versioning ON
- `gs://tf-state-my-project-prod-prod` — versioning ON

### Step 3 — Set up Workload Identity Federation

Allows GitHub Actions to authenticate to GCP without SA key files.

```bash
DEV_PROJECT="my-project-dev"
REPO="your-org/your-repo"          # e.g. acme/infra-repo
PROJECT_NUMBER=$(gcloud projects describe ${DEV_PROJECT} --format='value(projectNumber)')

# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="${DEV_PROJECT}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create OIDC Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${DEV_PROJECT}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow the GitHub repo to impersonate the Terraform SA (dev)
gcloud iam service-accounts add-iam-policy-binding \
  "terraform-deploy-dev@${DEV_PROJECT}.iam.gserviceaccount.com" \
  --project="${DEV_PROJECT}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${REPO}"

# Repeat for prod SA in the prod project
```

### Step 4 — Add GitHub Secrets

Go to **repo → Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `GCP_PROJECT_ID_DEV` | `my-project-dev` |
| `GCP_PROJECT_ID_PROD` | `my-project-prod` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_SA_EMAIL_DEV` | `terraform-deploy-dev@my-project-dev.iam.gserviceaccount.com` |
| `GCP_SA_EMAIL_PROD` | `terraform-deploy-prod@my-project-prod.iam.gserviceaccount.com` |

### Step 5 — Create GitHub Environments with approval gates

Go to **repo → Settings → Environments**:

**Create `dev` environment:**
- Required reviewers: optional (dev can auto-apply)
- Deployment branches: `main` only

**Create `prod` environment:**
- Required reviewers: add at least one senior engineer ← critical
- Deployment branches: `main` only

This means even after a merge to main, the prod apply job pauses and waits
for a human to click **Approve** in the GitHub Actions UI before Terraform runs.

### Step 6 — Update terraform.tfvars

```bash
# Replace placeholder project IDs
sed -i 's/my-gcp-project-dev/YOUR_REAL_DEV_PROJECT/' environments/dev/terraform.tfvars
sed -i 's/my-gcp-project-prod/YOUR_REAL_PROD_PROJECT/' environments/prod/terraform.tfvars
```

---

## Day-to-day developer workflow

```bash
# 1. Create feature branch off develop
git checkout develop
git pull
git checkout -b feat/update-composer-worker-size

# 2. Make changes (e.g. edit environments/dev/main.tf)
vim environments/dev/main.tf

# 3. Push — triggers Plan on dev
git add .
git commit -m "feat: increase dev worker memory to 4GB"
git push origin feat/update-composer-worker-size

# 4. Open PR: feat/* → develop
#    GitHub Actions posts the terraform plan as a comment on the PR.
#    Team reviews the plan. No infrastructure has changed yet.

# 5. Merge PR into develop
#    → Plan runs again on develop (push trigger). Still no apply.

# 6. Open PR: develop → main
#    → Plan runs for BOTH dev and prod.
#    → Plan output posted as PR comments for both environments.
#    → Team reviews exactly what will change in prod.

# 7. Merge PR into main
#    → terraform-dev apply fires immediately (dev environment, no gate).
#    → terraform-prod apply pauses for manual approval.
#    → Reviewer clicks Approve in GitHub Actions UI.
#    → Prod apply runs.
```

---

## What each workflow file does

### `terraform-dev.yml`
- **Plan job** — triggered by push to `develop` OR PR into `develop`
- **Apply job** — triggered only when a PR is merged (`merged == true`) into `main`
- Both jobs authenticate with the **dev** SA via WIF

### `terraform-prod.yml`
- **Plan job** — triggered by PR opened/updated into `main`
- **Apply job** — triggered only when a PR is merged into `main`, and requires the `prod` GitHub Environment approval
- Both jobs authenticate with the **prod** SA via WIF

### Why two separate workflow files?
Each uses a different GCP service account (`GCP_SA_EMAIL_DEV` vs `GCP_SA_EMAIL_PROD`)
and targets a different state bucket and working directory. Keeping them separate
makes it easy to add environment-specific logic (e.g. Slack notifications only for prod)
without conditional spaghetti in a single file.
