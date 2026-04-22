<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# GitHub Actions OIDC Guide — Azure, AWS, GCP

> **Stop storing long-lived cloud credentials as GitHub secrets.** Use OpenID Connect (OIDC) to let GitHub Actions authenticate directly to your cloud provider with short-lived, auto-rotating tokens.

---

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Why OIDC?

| Aspect | Long-lived secrets | OIDC |
|---|---|---|
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Credential lifetime** | Until manually rotated | Minutes (auto-expires) |
| **Rotation** | Manual, easy to forget | Automatic, every workflow run |
| **Blast radius** | Leaked secret = persistent access | Leaked token expires in minutes |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Audit trail** | Who used it? Hard to tell | Each token tied to repo/branch/workflow |
| **Setup effort** | Create key, paste into GitHub | One-time trust policy setup |

**Bottom line:** OIDC is more secure and less operational burden once configured.

<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## How It Works (All Clouds)

```
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   GitHub      │  JWT    │   Cloud      │  Token  │   Cloud      │
│   Actions     │────────►│   Identity   │────────►│   Resources  │
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   Runner      │         │   Provider   │         │   (deploy)   │
└──────────────┘         └──────────────┘         └──────────────┘
                  1. GH mints a JWT     2. Cloud validates JWT
                     <!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
                     with claims           and issues short-lived
                     (repo, branch, etc.)  credentials
```

<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
1. GitHub Actions requests a JWT (JSON Web Token) from GitHub's OIDC provider
2. Your workflow sends the JWT to the cloud provider's token exchange endpoint
3. The cloud validates the JWT against a trust policy you configured
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
4. If valid, the cloud issues short-lived credentials scoped to a specific role
5. Your workflow uses those credentials to deploy

**The JWT contains claims** like `repository`, `ref`, `workflow`, `actor` — your trust policy can restrict which repos/branches are allowed.

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Azure — Workload Identity Federation

### Step 1: Create an Azure AD App Registration

<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
# Create the app registration
az ad app create --display-name "github-actions-deploy"

<!-- Note 13: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Note the appId (CLIENT_ID) from the output
APP_ID=$(az ad app list --display-name "github-actions-deploy" --query "[0].appId" -o tsv)

# Create a service principal for the app
<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
az ad sp create --id $APP_ID
```

### Step 2: Add Federated Credential

<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
# Create federated credential for main branch
az ad app federated-credential create --id $APP_ID --parameters '{
  <!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main",
  <!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions — main branch"
}'
<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

**Subject claim patterns:**

| Scope | Subject value |
<!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|---|---|
| Specific branch | `repo:org/repo:ref:refs/heads/main` |
| Any branch | `repo:org/repo:ref:refs/heads/*` |
<!-- Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Specific tag | `repo:org/repo:ref:refs/tags/v1.0.0` |
| Pull requests | `repo:org/repo:pull_request` |
| Specific environment | `repo:org/repo:environment:production` |

<!-- Note 21: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Step 3: Grant Azure Permissions

```bash
# Get the service principal object ID
<!-- Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# Assign Contributor role on subscription (or scope to resource group)
az role assignment create \
  <!-- Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --assignee-object-id $SP_OBJECT_ID \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  <!-- Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --scope "/subscriptions/YOUR-SUBSCRIPTION-ID"    # <-- CHANGE THIS

# For AKS deployments, also grant:
# az role assignment create --assignee-object-id $SP_OBJECT_ID \
<!-- Note 25: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#   --role "Azure Kubernetes Service Cluster User Role" \
#   --scope "/subscriptions/YOUR-SUB-ID/resourceGroups/YOUR-RG/providers/Microsoft.ContainerService/managedClusters/YOUR-AKS"
```

<!-- Note 26: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Step 4: Configure GitHub Secrets

Add these as **repository secrets** (Settings → Secrets → Actions):

| Secret name | Value |
<!-- Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|---|---|
| `AZURE_CLIENT_ID` | App registration `appId` |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
<!-- Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

### Step 5: Use in Workflow

```yaml
<!-- Note 29: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius. -->
jobs:
  deploy:
    runs-on: ubuntu-latest
    <!-- Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    permissions:
      id-token: write    # Required for OIDC
      contents: read

    <!-- Note 31: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius. -->
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        <!-- Note 32: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius. -->
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          <!-- Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      # Now you can use az cli, Terraform with ARM_* env vars, etc.
      <!-- Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      - run: az account show
```

### Azure Troubleshooting

<!-- Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Error | Cause | Fix |
|---|---|---|
| `AADSTS70021: No matching federated identity record found` | Subject claim mismatch | Check that the `subject` in the federated credential matches the workflow trigger (branch, environment, etc.) |
<!-- Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `AADSTS700016: Application not found` | Wrong `client-id` | Verify the `appId` matches your app registration |
| `AuthorizationFailed` | Missing role assignment | Grant the service principal the required role on the correct scope |

---

<!-- Note 37: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## AWS — IAM OIDC Provider + Role

### Step 1: Create the OIDC Provider in AWS

```bash
<!-- Note 38: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Get GitHub's OIDC thumbprint (changes rarely, but verify)
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

aws iam create-open-id-connect-provider \
  <!-- Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" \
  --thumbprint-list "$THUMBPRINT"
<!-- Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

> **Note:** You only create the OIDC provider **once per AWS account**, not per repository.

### Step 2: Create IAM Role with Trust Policy

<!-- Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
# Save this as trust-policy.json
cat > trust-policy.json << 'EOF'
<!-- Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
{
  "Version": "2012-10-17",
  "Statement": [
    <!-- Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    {
      "Effect": "Allow",
      "Principal": {
        <!-- Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
        "Federated": "arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      <!-- Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        <!-- Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        <!-- Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
        }
      }
    }
  <!-- Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  ]
}
EOF
<!-- Note 49: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# <-- CHANGE THIS: replace YOUR-ACCOUNT-ID and YOUR-ORG/YOUR-REPO

aws iam create-role \
  --role-name github-actions-deploy \
  <!-- Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --assume-role-policy-document file://trust-policy.json

# Attach policies the role needs (example: ECS deploy)
aws iam attach-role-policy \
  <!-- Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --role-name github-actions-deploy \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess    # <-- CHANGE THIS: use least privilege
```

<!-- Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Subject claim patterns for `Condition`:**

| Scope | `StringLike` value |
|---|---|
<!-- Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Any trigger in repo | `repo:org/repo:*` |
| Specific branch | `repo:org/repo:ref:refs/heads/main` |
| Specific environment | `repo:org/repo:environment:production` |
<!-- Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Pull requests | `repo:org/repo:pull_request` |

> **Security tip:** Always restrict `sub` to specific repos. Never use `*` as the subject — any GitHub repo could assume your role.

### Step 3: Configure GitHub Secrets

<!-- Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Secret name | Value |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | `arn:aws:iam::123456789012:role/github-actions-deploy` |

<!-- Note 56: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Step 4: Use in Workflow

```yaml
jobs:
  <!-- Note 57: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  deploy:
    runs-on: ubuntu-latest
    permissions:
      <!-- Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      id-token: write    # Required for OIDC
      contents: read

    steps:
      <!-- Note 59: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        <!-- Note 60: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: us-east-1    # <-- CHANGE THIS

      <!-- Note 61: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
      # Now you can use aws cli, Terraform with AWS_* env vars, etc.
      - run: aws sts get-caller-identity
```

<!-- Note 62: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### AWS Troubleshooting

| Error | Cause | Fix |
|---|---|---|
<!-- Note 63: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `Not authorized to perform: sts:AssumeRoleWithWebIdentity` | Subject condition mismatch | Check that the trust policy `sub` condition matches the workflow's repo/branch/environment |
| `InvalidIdentityToken` | OIDC provider not created or wrong thumbprint | Verify the OIDC provider exists in IAM → Identity Providers |
| `AccessDenied` | Role lacks required policies | Attach the necessary IAM policies to the role |
<!-- Note 64: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `Audience not allowed` | Wrong `aud` claim | Ensure trust policy has `sts.amazonaws.com` as the audience |

---

## GCP — Workload Identity Federation

<!-- Note 65: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Step 1: Create Workload Identity Pool

```bash
PROJECT_ID="your-project-id"           # <-- CHANGE THIS
<!-- Note 66: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-actions-provider"

# Enable required API
<!-- Note 67: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
gcloud services enable iamcredentials.googleapis.com --project $PROJECT_ID

# Create Workload Identity Pool
gcloud iam workload-identity-pools create "$POOL_NAME" \
  <!-- Note 68: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  <!-- Note 69: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --description="OIDC pool for GitHub Actions"
```

### Step 2: Create OIDC Provider in the Pool

<!-- Note 70: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
  --project="$PROJECT_ID" \
  <!-- Note 71: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --location="global" \
  --workload-identity-pool="$POOL_NAME" \
  --display-name="GitHub Actions Provider" \
  <!-- Note 72: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == 'YOUR-ORG'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
<!-- Note 73: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# <-- CHANGE THIS: replace YOUR-ORG with your GitHub org
```

> **attribute-condition** is critical — it restricts which GitHub orgs can authenticate. Without it, **any** GitHub repository could request tokens.

<!-- Note 74: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Step 3: Create a Service Account and Grant Access

```bash
SA_NAME="github-actions-deploy"
<!-- Note 75: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create service account
gcloud iam service-accounts create "$SA_NAME" \
  <!-- Note 76: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --project="$PROJECT_ID" \
  --display-name="GitHub Actions Deploy SA"

# Grant roles to the service account (example: GKE deploy)
<!-- Note 77: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer"               # <-- CHANGE THIS: use least privilege

<!-- Note 78: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Allow the Workload Identity Pool to impersonate this SA
POOL_ID=$(gcloud iam workload-identity-pools describe "$POOL_NAME" \
  --project="$PROJECT_ID" --location="global" --format="value(name)")

<!-- Note 79: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  <!-- Note 80: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/YOUR-ORG/YOUR-REPO"
# <-- CHANGE THIS: replace YOUR-ORG/YOUR-REPO
```

<!-- Note 81: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Principal patterns for `--member`:**

| Scope | Member value |
|---|---|
<!-- Note 82: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Specific repo | `principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/org/repo` |
| Entire org | `principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository_owner/org` |
| Specific subject | `principal://iam.googleapis.com/${POOL_ID}/subject/repo:org/repo:ref:refs/heads/main` |

<!-- Note 83: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Step 4: Get the Provider Resource Name

```bash
# You'll need this for the GitHub Actions workflow
<!-- Note 84: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
  --project="$PROJECT_ID" \
  --location="global" \
  <!-- Note 85: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  --workload-identity-pool="$POOL_NAME" \
  --format="value(name)"

# Output looks like:
<!-- Note 86: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider
```

### Step 5: Configure GitHub Secrets

<!-- Note 87: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Secret name | Value |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full provider resource name from Step 4 |
<!-- Note 88: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `GCP_SERVICE_ACCOUNT` | `github-actions-deploy@your-project-id.iam.gserviceaccount.com` |

### Step 6: Use in Workflow

```yaml
<!-- Note 89: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius. -->
jobs:
  deploy:
    runs-on: ubuntu-latest
    <!-- Note 90: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    permissions:
      id-token: write    # Required for OIDC
      contents: read

    <!-- Note 91: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius. -->
    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to Google Cloud (OIDC)
        <!-- Note 92: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius. -->
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          <!-- Note 93: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Set up gcloud CLI
        uses: google-github-actions/setup-gcloud@v2

      <!-- Note 94: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
      # Now you can use gcloud, Terraform with GOOGLE_* env vars, etc.
      - run: gcloud auth list
```

<!-- Note 95: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### GCP Troubleshooting

| Error | Cause | Fix |
|---|---|---|
<!-- Note 96: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `PERMISSION_DENIED: caller does not have permission` | SA lacks required roles | Grant the correct role to the service account |
| `INVALID_ARGUMENT: unable to parse the subject` | Wrong `attribute-mapping` config | Verify provider attribute mapping matches the claims |
| `The caller does not have permission to use this identity pool` | `attribute-condition` rejects the org | Check the `assertion.repository_owner` matches your GitHub org exactly |
<!-- Note 97: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `Could not generate access token` | WorkloadIdentityUser binding missing | Ensure the pool principal is bound to the SA with `roles/iam.workloadIdentityUser` |

---

## Cross-Cloud Comparison

<!-- Note 98: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Step | Azure | AWS | GCP |
|---|---|---|---|
| **Identity entity** | App Registration + Federated Credential | IAM OIDC Provider + IAM Role | Workload Identity Pool + Provider |
<!-- Note 99: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Auth action** | `azure/login@v2` | `aws-actions/configure-aws-credentials@v4` | `google-github-actions/auth@v2` |
| **Permission** | `id-token: write` | `id-token: write` | `id-token: write` |
| **Scope control** | `subject` on federated credential | `Condition` on trust policy | `attribute-condition` + `--member` |
<!-- Note 100: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Token lifetime** | ~1 hour | ~1 hour (configurable) | ~1 hour |
| **One-time setup** | Per app registration | OIDC Provider once per account, role per repo | Pool once per project, SA per repo |
| **Terraform support** | `ARM_USE_OIDC = true` | Auto (env vars set by action) | Auto (`GOOGLE_CREDENTIALS` set by action) |

<!-- Note 101: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Security Best Practices

1. **Always restrict the subject/condition** — never allow `*` or leave conditions empty
<!-- Note 102: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. **Use environment-scoped credentials** — different roles for dev/staging/prod
3. **Apply least privilege** — grant only the permissions the workflow actually needs
4. **Use GitHub Environments** — enforce approval gates on production deployments
<!-- Note 103: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
5. **Audit regularly** — review who/what has assumed the OIDC roles
6. **Pin action versions** — use commit SHAs for auth actions in high-security repos

### Example: Environment-Scoped OIDC (Recommended for Production)

<!-- Note 104: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```yaml
jobs:
  deploy-prod:
    <!-- Note 105: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    runs-on: ubuntu-latest
    environment: production        # Requires approval + uses environment secrets
    permissions:
      <!-- Note 106: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      id-token: write
      contents: read

    steps:
      <!-- Note 107: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      - uses: actions/checkout@v4

      - name: Auth to Cloud (OIDC)
        # The federated credential / trust policy should restrict to:
        <!-- Note 108: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
        # subject: "repo:org/repo:environment:production"
        uses: azure/login@v2       # or aws/gcp equivalent
        with:
          <!-- Note 109: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
          client-id: ${{ secrets.AZURE_CLIENT_ID }}     # Environment-specific secret
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## Related Files

- **CI pipelines using OIDC:** [`ci/github-actions/`](../../ci/github-actions/) — all deploy workflows use OIDC auth
- **CD targets:** [`cd/targets/`](../../cd/targets/) — cloud-specific deployment workflows with OIDC configured
- **Terraform pipelines:** [`ci/github-actions/terraform/plan-apply.yml`](../../ci/github-actions/terraform/plan-apply.yml) — OIDC sections for all three clouds
- **Secrets management guide:** [`docs/guides/secrets-management.md`](secrets-management.md) — broader secrets strategy
