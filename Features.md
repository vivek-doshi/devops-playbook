# DevOps Playbook — GitHub Copilot Instructions

## Model Configuration

- **Primary model:** `claude-sonnet-4-6`
- **Backup model:** `gpt-4.5`
- **Agent mode:** enabled for all implementation prompts below

---

## Repo Context

This repository is a copy-paste-ready DevOps template library. Every file it produces must follow these non-negotiable conventions:

- All resources tagged with `Project`, `Environment`, `ManagedBy = "terraform"` (Terraform files)
- Lines that require customisation marked `# <-- CHANGE THIS`
- File headers follow the standard block:
  ```
  # TEMPLATE: <title>
  # WHEN TO USE: <scenario>
  # PREREQUISITES: <what must exist first>
  # SECRETS NEEDED: <secret names>
  # WHAT TO CHANGE: <summary>
  # RELATED FILES: <comma-separated paths>
  # MATURITY: Stable | Beta | Experimental
  ```
- Kubernetes manifests use Note-style comments (`# Note N:`) aligned with the educational commenting pattern already in the repo
- Shell scripts begin with `set -euo pipefail` and print meaningful error messages before `exit 1`
- No hardcoded secrets, no `latest` tags in production contexts
- Every new directory gets a `README.md`

---

## Feature 1 — Secret Rotation Templates

**Prompt file:** `.github/prompts/SecretRotation.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate secret rotation workflows and ExternalSecret/SecretProviderClass bridge templates for AWS, Azure, and GCP.'
---

# Secret Rotation and External Secret Bridge Generator

You are a senior platform security engineer. Generate secret rotation templates and the Kubernetes ExternalSecret bridge so teams can consume cloud-native secret stores without ever writing a raw Kubernetes Secret manifest.

## Context

Read these files first:
- `docs/guides/secrets-management.md` — existing secrets guidance
- `terraform/azure-aks/main.tf` — Azure resource patterns
- `terraform/aws-eks/main.tf` — AWS resource patterns
- `terraform/gcp-gke/main.tf` — GCP resource patterns
- `cd/kubernetes/_base/deployment.yaml` — how secrets are consumed today

## Your deliverables

### 1. `secrets/external-secrets/README.md`

Explain:
- The External Secrets Operator (ESO) pattern: why teams should never write raw `kind: Secret` manifests
- The three supported backends in this repo: AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
- Installation: `helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace`
- How to verify ESO is running: `kubectl get pods -n external-secrets`
- How `SecretStore` (namespaced) vs `ClusterSecretStore` (cluster-wide) differ and when to use each

### 2. `secrets/external-secrets/aws-secret-store.yaml`

A `ClusterSecretStore` that authenticates to AWS Secrets Manager via IRSA (IAM Roles for Service Accounts). Include:
- Annotation for the IRSA service account: `# <-- CHANGE THIS`
- Region field: `# <-- CHANGE THIS`
- A commented-out alternative showing static credential auth (for non-EKS clusters) with a warning comment explaining why IRSA is preferred

### 3. `secrets/external-secrets/azure-secret-store.yaml`

A `ClusterSecretStore` for Azure Key Vault using Workload Identity. Include:
- `tenantId`, `vaultUrl`, `clientId` fields all marked `# <-- CHANGE THIS`
- A comment explaining the Azure Workload Identity prerequisite (federated credential on the managed identity)

### 4. `secrets/external-secrets/gcp-secret-store.yaml`

A `ClusterSecretStore` for GCP Secret Manager using Workload Identity. Include:
- `projectID` marked `# <-- CHANGE THIS`
- Comment explaining that the Kubernetes service account must be annotated with `iam.gke.io/gcp-service-account`

### 5. `secrets/external-secrets/example-external-secret.yaml`

A commented `ExternalSecret` manifest that:
- References the `ClusterSecretStore` from item 2
- Pulls two keys from a cloud secret and maps them to Kubernetes secret keys
- Has `refreshInterval: 1h` with a comment explaining the tradeoff between freshness and API call cost
- Shows how to reference the resulting secret in a Deployment `envFrom` block (as a comment)

### 6. `secrets/rotation/aws-rotation.yml`

A GitHub Actions workflow that:
- Triggers on `workflow_dispatch` with inputs: `secret_name` (required), `dry_run` (boolean, default true)
- Uses OIDC to authenticate to AWS
- Calls `aws secretsmanager rotate-secret` against the named secret
- Posts a summary to `$GITHUB_STEP_SUMMARY` showing the secret ARN, rotation status, and next rotation date
- Has a `dry_run` guard that prints what it would do without executing when `dry_run: true`
- Follows the standard file header

### 7. `secrets/rotation/azure-rotation.yml`

A GitHub Actions workflow that:
- Triggers on schedule (`0 2 * * 0` — weekly Sunday 02:00 UTC) and `workflow_dispatch`
- Uses Azure OIDC login
- Rotates a Key Vault secret by generating a new random value with `openssl rand -base64 32`
- Updates the secret version and posts the new version ID to the job summary
- Marks the old version as `Disabled` rather than deleting it (safer rollback)
- Includes `# <-- CHANGE THIS` on vault name and secret name

### 8. `secrets/rotation/gcp-rotation.yml`

A GitHub Actions workflow that:
- Triggers on `workflow_dispatch` with `secret_id` input
- Uses GCP Workload Identity Federation
- Creates a new secret version with `gcloud secrets versions add`
- Disables the previous version after a configurable delay (`RETIRE_AFTER_MINUTES`, default 60)
- Posts version number and create time to the job summary

## Style rules

- Every YAML comment must explain the "why", not just the "what"
- Rotation workflows must be idempotent — running twice must not break anything
- Each workflow must have a `# IMPORTANT:` comment explaining that rotation only updates the secret store value; applications must be restarted or use dynamic secret injection to pick up new values
- Pin all action versions to explicit tags
```

---

## Feature 2 — Database Migration Patterns

**Prompt file:** `.github/prompts/DatabaseMigrations.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate safe database migration patterns as Kubernetes init containers and Jobs, with rollback guidance.'
---

# Database Migration Pattern Generator

You are a senior platform engineer and database reliability specialist. Generate production-safe database migration patterns for Kubernetes workloads.

## Context

Read these files first:
- `cd/kubernetes/_base/deployment.yaml` — current Deployment pattern (init containers section)
- `cd/kubernetes/_patterns/init-containers.yaml` — existing init container examples
- `cd/helm/webapp/templates/deployment.yaml` — Helm deployment pattern

## Your deliverables

### 1. `cd/kubernetes/_patterns/db-migration-init-container.yaml`

A Deployment with an init container that runs database migrations before the main app starts. Include:
- Two init containers in sequence: `wait-for-db` (uses `nc` to poll the DB port) and `db-migrate`
- Comments on each init container explaining the ordering guarantee Kubernetes provides
- `activeDeadlineSeconds` on the migration init container: `# <-- CHANGE THIS` with a comment explaining why a deadline prevents stuck migrations from blocking rollout indefinitely
- Secret reference for the DB connection string (referencing `app-secrets`)
- A `# IMPORTANT:` comment block explaining the tradeoff: init containers block pod start, so migrations that take >10 minutes should use a Job instead (see pattern 2)
- The `readOnlyRootFilesystem: true` and non-root user security context on the migration container

### 2. `cd/kubernetes/_patterns/db-migration-job.yaml`

A Kubernetes `Job` for long-running migrations (schema changes, backfills). Include:
- `backoffLimit: 0` with a comment explaining why retrying a partially-applied migration is dangerous without idempotency checks
- `activeDeadlineSeconds: 1800` (30 minutes) marked `# <-- CHANGE THIS`
- `ttlSecondsAfterFinished: 3600` so completed jobs clean themselves up
- `restartPolicy: Never`
- A commented section showing how to run this Job from a GitHub Actions deployment step before the Deployment rollout begins
- Security context matching the base deployment pattern

### 3. `cd/kubernetes/_patterns/db-migration-hook.yaml`

A Helm pre-upgrade hook Job that runs migrations before the chart upgrade proceeds. Include:
- `helm.sh/hook: pre-upgrade,pre-install` annotation
- `helm.sh/hook-weight: "-5"` with a comment explaining hook weight ordering
- `helm.sh/hook-delete-policy: before-hook-creation` to avoid accumulating old Job objects
- A note explaining that this hook blocks `helm upgrade` until the Job completes or fails

### 4. `docs/guides/database-migrations.md`

A decision guide covering:
- **Decision tree**: when to use init container vs Job vs Helm hook
- **The golden rules**: migrations must be backwards-compatible with the previous app version (expand/contract pattern), never drop a column in the same release that removes the code using it
- **Rollback procedure**: step-by-step for each pattern
- **Testing migrations locally**: using the Kind cluster from `local-dev/kind/`
- **Monitoring**: how to tail migration logs with `stern` and what a healthy vs stuck migration looks like
- Link to `local-dev/kind/setup.sh` for local testing

## Style rules

- Every init container and Job must include resource requests and limits matching the base deployment pattern
- Migration containers must never run as root
- Comments must explain failure modes, not just happy paths
- `# <-- CHANGE THIS` on image references, timeout values, and connection string secret names
```

---

## Feature 3 — cert-manager Bootstrap

**Prompt file:** `.github/prompts/CertManager.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate cert-manager installation and ClusterIssuer templates for Let'\''s Encrypt and self-signed certificates.'
---

# cert-manager Bootstrap Generator

You are a senior platform engineer. Generate cert-manager installation templates and ClusterIssuer configurations so teams can enable the TLS annotations already present in this repo's Kubernetes manifests.

## Context

Read these files first:
- `cd/kubernetes/_base/ingress.yaml` — already references `cert-manager.io/cluster-issuer: letsencrypt-prod`
- `cd/helm/webapp/values.yaml` — TLS is enabled by default
- `local-dev/kind/setup.sh` — understand the local cluster pattern

## Your deliverables

### 1. `cd/kubernetes/cert-manager/README.md`

Cover:
- Why cert-manager: replaces manual TLS certificate management with automatic issuance and renewal
- Installation command (Helm, pinned chart version)
- How to verify: `kubectl get pods -n cert-manager` and `kubectl get clusterissuers`
- How the `cert-manager.io/cluster-issuer` annotation in `cd/kubernetes/_base/ingress.yaml` works
- Common failure modes: ACME HTTP-01 challenge failing (ingress not reachable), rate limiting, wrong email address
- How to check certificate status: `kubectl describe certificate`, `kubectl describe certificaterequest`, `kubectl describe order`

### 2. `cd/kubernetes/cert-manager/namespace.yaml`

The `cert-manager` namespace manifest with standard labels including `environment: shared`.

### 3. `cd/kubernetes/cert-manager/cluster-issuer-staging.yaml`

A `ClusterIssuer` for Let's Encrypt staging (for testing — does not consume rate limit quota). Include:
- `# IMPORTANT:` comment: always test with staging first; staging certificates are not trusted by browsers but the issuance flow is identical to production
- `email` field: `# <-- CHANGE THIS`
- HTTP-01 solver using nginx ingress class
- A commented-out DNS-01 solver block for wildcard certificates (Route53 example) with `# <-- CHANGE THIS` on the hosted zone ID and region

### 4. `cd/kubernetes/cert-manager/cluster-issuer-prod.yaml`

Same structure as staging but pointing to the production ACME endpoint. Include:
- A `# WARNING:` comment about rate limits (5 certificates per registered domain per week)
- Instruction to only switch to this issuer after staging issuance succeeds

### 5. `cd/kubernetes/cert-manager/cluster-issuer-selfsigned.yaml`

A self-signed `ClusterIssuer` for local development and internal services. Include:
- Comment explaining that self-signed certs trigger browser warnings and are suitable only for internal services or local clusters

### 6. `cd/kubernetes/cert-manager/kustomization.yaml`

Kustomize file that includes all the above resources so teams can apply with `kubectl apply -k cd/kubernetes/cert-manager/`.

## Style rules

- Pin the cert-manager Helm chart version with a `# <-- CHANGE THIS` comment pointing to the releases page
- All ACME solver configurations must have comments explaining the HTTP-01 vs DNS-01 tradeoff (HTTP-01 is simpler but requires public ingress; DNS-01 supports wildcards and works behind firewalls)
```

---

## Feature 4 — Backup and Disaster Recovery

**Prompt file:** `.github/prompts/BackupDR.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Velero cluster backup configuration and cloud-managed database backup policies in Terraform.'
---

# Backup and Disaster Recovery Generator

You are a senior SRE and infrastructure engineer. Generate backup and DR templates for Kubernetes workloads and cloud-managed databases.

## Context

Read these files first:
- `terraform/aws-eks/main.tf`, `terraform/azure-aks/main.tf`, `terraform/gcp-gke/main.tf` — cluster patterns
- `terraform/aws-ecs/main.tf` — ECS pattern (no Velero needed, different DR approach)
- `cd/kubernetes/_base/` — what resources exist in the cluster

## Your deliverables

### 1. `backup/velero/README.md`

Cover:
- What Velero backs up: Kubernetes object definitions and PersistentVolume snapshots
- What Velero does NOT back up: in-memory state, database contents (use DB-native backups for this)
- Installation per cloud: S3 (AWS), Azure Blob (Azure), GCS (GCP)
- How to trigger a manual backup: `velero backup create`
- How to restore: `velero restore create`
- How to verify a backup is valid: `velero backup describe --details`
- Recovery Time Objective (RTO) expectations: comment that typical cluster restore from Velero is 15-45 minutes depending on PV size

### 2. `backup/velero/aws-install.sh`

A bash script that:
- Checks prerequisites: `velero`, `aws`, `kubectl`
- Creates the S3 bucket and IAM policy for Velero using AWS CLI (not Terraform, since this is a one-time bootstrap)
- Runs `velero install` with the S3 backend and IRSA annotation
- All bucket names and region marked `# <-- CHANGE THIS`
- Follows `set -euo pipefail` and prints meaningful step output

### 3. `backup/velero/schedule.yaml`

A Velero `Schedule` resource that:
- Backs up all namespaces except `kube-system`, `kube-public`, `cert-manager`, `velero` (infrastructure namespaces that are better rebuilt than restored)
- Runs daily at 02:00 UTC
- Retains 30 backups
- Includes volume snapshots: `snapshotVolumes: true` with a comment that this requires the cloud provider plugin
- Has `# <-- CHANGE THIS` on the schedule cron and retention count

### 4. `backup/velero/namespace-backup.yaml`

A Velero `Schedule` for backing up a single application namespace. A team's starting point for per-app backup policies. All namespace references marked `# <-- CHANGE THIS`.

### 5. `backup/terraform/aws-rds-backup.tf`

Terraform resource blocks (no full module, just the backup-relevant attributes) showing:
- `backup_retention_period = 30` with a comment on the cost implication
- `backup_window = "02:00-03:00"` with a comment on choosing a low-traffic window
- `maintenance_window` offset from backup window
- `deletion_protection = true` with a `# IMPORTANT:` comment: this prevents accidental `terraform destroy` from deleting production data
- `copy_tags_to_snapshot = true`
- A commented block for cross-region snapshot copy (for DR to a second region)

### 6. `backup/terraform/azure-postgres-backup.tf`

Equivalent blocks for `azurerm_postgresql_flexible_server`:
- `backup_retention_days = 35` (Azure maximum)
- `geo_redundant_backup_enabled = true` with a comment that this doubles storage cost but enables restore to a paired region
- `high_availability` block with `mode = "ZoneRedundant"`

### 7. `backup/terraform/gcp-cloudsql-backup.tf`

Equivalent blocks for `google_sql_database_instance`:
- `backup_configuration` with `enabled = true`, `point_in_time_recovery_enabled = true`
- `transaction_log_retention_days = 7`
- `backup_retention_settings` with `retained_backups = 30`
- A comment on enabling cross-region replicas for DR

### 8. `docs/guides/disaster-recovery.md`

A runbook-style guide covering:
- **RTO/RPO targets table**: example values teams should fill in for their services
- **Kubernetes cluster loss**: step-by-step Velero restore procedure
- **Database loss**: per-cloud restore procedure with exact CLI commands
- **Partial namespace loss**: targeted Velero restore
- **DR testing checklist**: quarterly test procedure, what to verify, how to document results
- Links to `backup/velero/` and `backup/terraform/`

## Style rules

- Every backup resource must have a comment explaining the retention rationale
- Terraform blocks must follow the tagging convention from existing modules
- Shell scripts must be idempotent — safe to run twice
- DR guide must include realistic time estimates for each procedure
```

---

## Feature 5 — NetworkPolicy Templates

**Prompt file:** `.github/prompts/NetworkPolicies.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Kubernetes NetworkPolicy templates implementing default-deny with explicit allow patterns.'
---

# NetworkPolicy Generator

You are a senior Kubernetes security engineer. Generate NetworkPolicy templates that implement a default-deny posture with explicit allow rules.

## Context

Read these files first:
- `cd/kubernetes/_base/deployment.yaml` — pod labels (`app: app`)
- `cd/kubernetes/_base/service.yaml` — service selector
- `policy/kyverno/require-labels.yaml` — label requirements policies depend on
- `cd/kubernetes/_overlays/dev/kustomization.yaml` and `prod/` — namespace structure

## Your deliverables

### 1. `cd/kubernetes/_base/network-policies/README.md`

Explain:
- Default-deny: why you should deny all traffic and explicitly allow only what is needed
- How NetworkPolicy interacts with the CNI plugin (requires a CNI that supports NetworkPolicy — Calico, Cilium, or Azure CNI with policy)
- The label dependency: policies in this repo rely on the `app` label enforced by `policy/kyverno/require-labels.yaml`
- How to test: `kubectl exec` into a pod and `nc` to another pod's ClusterIP
- How to debug: `kubectl describe networkpolicy` and CNI-specific logging

### 2. `cd/kubernetes/_base/network-policies/default-deny.yaml`

Two `NetworkPolicy` resources:
- `deny-all-ingress`: denies all ingress to all pods in the namespace
- `deny-all-egress`: denies all egress from all pods in the namespace

Each must have a `# NOTE:` comment explaining that this policy only takes effect when a CNI supporting NetworkPolicy is installed. Include a `# WARNING:` that applying this without the allow policies below will immediately break the application.

### 3. `cd/kubernetes/_base/network-policies/allow-ingress-from-ingress-controller.yaml`

Allows ingress from the nginx ingress controller namespace to the `app` pods on port 8080. Include:
- `namespaceSelector` matching `kubernetes.io/metadata.name: ingress-nginx`
- Comment explaining why namespace selector is used instead of IP range (ingress controller pods can scale and change IPs)
- `# <-- CHANGE THIS` on the port number

### 4. `cd/kubernetes/_base/network-policies/allow-egress-to-dns.yaml`

Allows egress to kube-dns on port 53 (both TCP and UDP). Include a comment explaining that without this policy, pods cannot resolve any service names.

### 5. `cd/kubernetes/_base/network-policies/allow-egress-to-database.yaml`

Template for allowing egress from the app to a database pod. Use `podSelector` with a `role: database` label. Include:
- `# <-- CHANGE THIS` on port and label values
- Comment explaining the alternative: if the database is external (RDS, Cloud SQL), use an egress rule to a CIDR block or use a `ServiceEntry` if Istio is present

### 6. `cd/kubernetes/_base/network-policies/allow-prometheus-scrape.yaml`

Allows ingress from the Prometheus namespace (`monitoring`) to the `app` pods on the metrics port (8088). Includes `# <-- CHANGE THIS` on the metrics port.

### 7. `cd/kubernetes/_base/network-policies/kustomization.yaml`

Kustomize file including all network policies. Comment that teams should add this to their overlay's `resources:` list rather than including it directly in `_base` until they have validated all allow rules.

## Style rules

- Every policy must have a comment explaining what breaks if this policy is removed
- Port numbers always have `# <-- CHANGE THIS` comments
- Label selectors always explain which Kyverno policy enforces those labels
```

---

## Feature 6 — RBAC Templates

**Prompt file:** `.github/prompts/RBACTemplates.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Kubernetes RBAC Role, ClusterRole, and RoleBinding templates for common platform personas.'
---

# RBAC Template Generator

You are a senior platform engineer. Generate least-privilege RBAC templates for the personas that interact with clusters managed using this repo's patterns.

## Context

Read these files first:
- `cd/kubernetes/_base/` — resources that exist in the cluster
- `cd/kubernetes/_overlays/prod/kustomization.yaml` — production namespace structure
- `policy/kyverno/require-labels.yaml` — label requirements

## Your deliverables

Create all files under `cd/kubernetes/_base/rbac/`.

### 1. `cd/kubernetes/_base/rbac/README.md`

Explain:
- The four personas in this repo: read-only developer, application deployer (CI), namespace admin, cluster admin
- Role (namespaced) vs ClusterRole (cluster-wide) and when to use each
- How RoleBinding grants a ClusterRole within a namespace (the common pattern for namespace-scoped access)
- How to audit what a service account can do: `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa>`

### 2. `cd/kubernetes/_base/rbac/readonly-developer.yaml`

A `ClusterRole` named `devops-playbook:readonly-developer` that allows:
- `get`, `list`, `watch` on: pods, services, deployments, replicasets, statefulsets, daemonsets, ingresses, configmaps, events, horizontalpodautoscalers
- `get`, `list`, `watch` on: namespaces, nodes (cluster-level, read-only)
- Explicitly NO access to: secrets (comment explaining why — even list access exposes secret names, and describe exposes data)

Include a `RoleBinding` example (commented out) showing how to bind this ClusterRole in a specific namespace for a user.

### 3. `cd/kubernetes/_base/rbac/ci-deployer.yaml`

A `ServiceAccount`, `ClusterRole`, and `RoleBinding` for the CI/CD pipeline service account. The ClusterRole grants:
- Full CRUD on: deployments, replicasets, statefulsets, services, configmaps, ingresses, horizontalpodautoscalers
- `create`, `patch` on: secrets (to push image pull secrets)
- `get`, `list` on: pods, events (to verify rollout status)
- Explicitly NO cluster-level permissions (comment: CI should never be able to modify namespaces, RBAC, or CRDs)

### 4. `cd/kubernetes/_base/rbac/namespace-admin.yaml`

A `ClusterRole` that grants full access to all resources within a namespace except:
- No access to modify `ResourceQuota` or `LimitRange` (those are set by platform team)
- No access to create `ClusterRole`, `ClusterRoleBinding`
- Comment explaining this is the appropriate role for a team lead who owns an application namespace

### 5. `cd/kubernetes/_base/rbac/kustomization.yaml`

Kustomize file including the RBAC resources with a comment: these are cluster-scoped ClusterRoles; apply with `kubectl apply -k` at the cluster level, not per-namespace.

## Style rules

- Every ClusterRole must have a comment on each `rules` entry explaining the business reason for the permission
- ServiceAccount names must match the pattern `<project>-<role>` with `# <-- CHANGE THIS`
- Namespace references marked `# <-- CHANGE THIS`
- Each file must include a `# SECURITY NOTE:` comment on what damage an attacker could do if this role were compromised — forces teams to think about blast radius
```

---

## Feature 7 — Terraform Drift Detection and Cost Estimation

**Prompt file:** `.github/prompts/TerraformOps.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Terraform drift detection workflow, Infracost integration, and Terratest examples.'
---

# Terraform Operational Tooling Generator

You are a senior DevOps engineer. Generate three operational capabilities for the Terraform modules in this repo: drift detection, cost estimation, and module testing.

## Context

Read these files first:
- `ci/github-actions/terraform/plan-apply.yml` — existing plan/apply pattern to extend
- `terraform/azure-aks/main.tf`, `terraform/aws-eks/main.tf` — module structure
- `.github/workflows/dependabot-automerge.yml` — existing workflow style

## Your deliverables

### 1. `ci/github-actions/terraform/drift-detection.yml`

A GitHub Actions workflow that:
- Runs on a weekly schedule (Monday 06:00 UTC) and `workflow_dispatch`
- Uses a matrix over all Terraform directories: `azure-aks`, `aws-eks`, `gcp-gke`, `aws-ecs`, `aws-lambda`, `azure-app-service`
- For each: runs `terraform init` then `terraform plan -detailed-exitcode`
- Exit code 0 = no drift, 1 = error, 2 = drift detected
- On exit code 2: opens a GitHub Issue titled `[Drift Detected] terraform/<module>` using `actions/github-script`
- Issue body includes: which module, timestamp, a link to the workflow run, and the first 50 lines of plan output
- Skips issue creation if an open issue with the same title already exists (idempotent)
- Cloud authentication sections for all three clouds (commented out, with `# <-- CHANGE THIS`)
- `concurrency` group per module to prevent parallel drift checks on the same state
- Follows the standard file header with `MATURITY: Stable`

### 2. `ci/github-actions/terraform/cost-estimation.yml`

A GitHub Actions workflow that:
- Triggers on pull_request when `terraform/**` changes
- Runs Infracost via `infracost/actions/setup` and `infracost breakdown`
- Posts a cost diff comment to the PR showing monthly cost change (increase/decrease)
- Uses `INFRACOST_API_KEY` secret with a comment pointing to `https://www.infracost.io/docs/` for setup
- `soft_fail: true` so missing API key does not block PRs
- Comment includes a table: resource name, quantity, monthly cost, diff
- Marks the `# <-- CHANGE THIS` on the Terraform directory paths

### 3. `terraform/tests/README.md`

Explain:
- `terraform test` (native, available since Terraform 1.6) vs Terratest (Go-based)
- When to use `terraform test`: fast unit/integration tests that validate module outputs and resource attributes without applying to a real cloud
- When to use Terratest: end-to-end tests that provision real infrastructure and verify it works
- How to run: `terraform test` in any module directory
- The test file naming convention: `*.tftest.hcl`

### 4. `terraform/tests/azure-aks.tftest.hcl`

A `terraform test` file for the `azure-aks` module that:
- Uses a `mock_provider "azurerm"` block to avoid real cloud calls
- Tests that `resource_group_name` output matches the expected naming pattern
- Tests that `kubernetes_version` is set to a supported value
- Tests that `node_vm_size` is not the Free tier (`Standard_B1s`)
- Uses `assert` blocks with descriptive error messages

### 5. `terraform/tests/aws-eks.tftest.hcl`

Equivalent test file for the `aws-eks` module testing:
- Cluster name follows `eks-<project>-<environment>` pattern
- `node_min_count` is at least 2 (for HA)
- `kubernetes_version` is a recent version (not ancient)

## Style rules

- Drift detection workflow must have `permissions: issues: write` and `contents: read`
- Cost estimation must handle the case where Infracost is not configured gracefully (soft fail with an explanatory comment on the PR)
- Test files must have comments explaining what each `assert` is checking and why it matters
```

---

## Feature 8 — Observability: Tempo

**Prompt file:** `.github/prompts/TempoStack.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Tempo distributed tracing Helm values to complete the observability stack alongside Prometheus and Loki.'
---

# Tempo Distributed Tracing Stack Generator

You are a senior SRE. Generate Helm values for Grafana Tempo that complete the three-pillar observability stack in this repository.

## Context

Read these files first:
- `observability/prometheus/values.yaml` — match Grafana configuration style
- `observability/loki/values.yaml` — match chart values structure and comment density
- `observability/opentelemetry/collector-config.yaml` — Tempo is the OTLP trace backend here; the endpoint is `${TEMPO_ENDPOINT}`
- `observability/README.md` — installation order context

## Your deliverables

### 1. `observability/tempo/values.yaml`

Helm values for `grafana/tempo-distributed` (or `grafana/tempo` monolithic for smaller clusters) chart that configure:

**Storage:**
- Backend: `local` filesystem for simplicity with a large `# <-- CHANGE THIS` comment pointing to S3/GCS/Azure object store for production
- Retention: 72 hours (traces are high-volume; comment explains this is intentionally shorter than metrics/logs retention)
- `# <-- CHANGE THIS` on retention with a note on storage sizing: rough estimate is 1-5 GB/day per 1000 req/s at 10% sampling

**Receivers:**
- OTLP gRPC on port 4317
- OTLP HTTP on port 4318
- Zipkin on port 9411 (for legacy services)

**Query:**
- `max_search_duration: 336h` (14 days, to allow querying across the 72h retention window with some buffer)
- `default_result_limit: 20`

**Grafana datasource ConfigMap:**
- Same sidecar label pattern as `observability/loki/grafana-datasource.yaml` (`grafana_datasource: "1"`)
- Datasource name: `Tempo`
- Enable `tracesToLogs` linking pointing to the Loki datasource (by UID)
- Enable `serviceMap` feature using Prometheus as the metrics datasource

**Resources:**
- Sized for a small-to-medium cluster (requests: 500m CPU, 1Gi memory; limits: 2 CPU, 4Gi)

### 2. `observability/tempo/grafana-datasource.yaml`

A ConfigMap that:
- Registers Tempo as a Grafana datasource
- Configures derived fields to link `trace_id` in Loki logs to Tempo traces (mirror the placeholder from `observability/loki/grafana-datasource.yaml` but in the opposite direction)
- Enables the service graph panel using Prometheus metrics

### 3. `observability/tempo/README.md`

Cover:
- Installation command (pinned chart version)
- How traces flow: App → OTel Collector Sidecar → Tempo → Grafana
- How to view a trace in Grafana: Explore → Tempo datasource → search by service name or trace ID
- How to jump from a Loki log line to the correlated Tempo trace (requires `trace_id` label in Loki, which the Promtail pipeline in `observability/loki/values.yaml` already extracts)
- How to jump from a Tempo trace to Loki logs (configure in the datasource — already done in item 2)
- Sampling strategy: reference `observability/opentelemetry/env-vars/` for per-language sampling configuration
- Common issues: traces not appearing (check OTel collector logs), service graph empty (requires `spanmetrics` processor in OTel collector)
- Update `observability/README.md` to add Tempo to the stack description

## Style rules

- Match the comment density and style of `observability/loki/values.yaml` exactly
- Storage sizing rationale must be commented inline
- Every non-obvious Tempo configuration key must have a comment explaining its effect on query performance or storage cost
```

---

## Feature 9 — SLO Recording Rules

**Prompt file:** `.github/prompts/SLOAlerts.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Prometheus SLO recording rules and multi-window burn rate alerts following the Google SRE approach.'
---

# SLO Recording Rules and Burn Rate Alert Generator

You are a senior SRE. Generate SLO recording rules and multi-window multi-burn-rate alerts for the workloads in this repo.

## Context

Read these files first:
- `observability/prometheus/alerts/pod-alerts.yaml` — existing alert style
- `observability/prometheus/alerts/deployment-alerts.yaml` — existing PrometheusRule structure
- `observability/prometheus/values.yaml` — Alertmanager routing (critical → PagerDuty, warning → Slack)

## Your deliverables

### 1. `observability/prometheus/slos/README.md`

Explain:
- What an SLO is and why it matters for on-call quality
- The error budget concept: if 99.9% availability SLO = 43.8 minutes downtime budget per month
- Multi-window burn rate: why you need both fast burn (1h/5h windows) and slow burn (6h/3d windows) alerts
- How to set the SLO target: start with what you currently achieve, not what you wish for
- Link to Google's SRE workbook chapter on alerting on SLOs

### 2. `observability/prometheus/slos/availability-slo.yaml`

A PrometheusRule with:

**Recording rules** (these power the alerting rules below and Grafana dashboards):
```
# 5-minute error rate
slo:service_errors:ratio_rate5m
# 30-minute error rate  
slo:service_errors:ratio_rate30m
# 1-hour error rate
slo:service_errors:ratio_rate1h
# 6-hour error rate
slo:service_errors:ratio_rate6h
# 1-day error rate
slo:service_errors:ratio_rate1d
# 3-day error rate
slo:service_errors:ratio_rate3d
```

Each recording rule uses a PromQL expression based on `http_requests_total` (with `status` label) with a comment explaining which metric to use for non-HTTP services (gRPC uses `grpc_server_handled_total`).

**Alerting rules** (multi-window multi-burn-rate):
- `SLOFastBurnCritical`: 14x burn rate sustained for 1h AND 5h — severity: critical (pages)
- `SLOFastBurnWarning`: 6x burn rate sustained for 1h AND 5h — severity: warning (Slack)
- `SLOSlowBurnWarning`: 3x burn rate sustained for 6h AND 3d — severity: warning (Slack)

Each alert has:
- `summary`: one sentence
- `description`: includes service name, current error rate, burn rate, estimated time to budget exhaustion
- `runbook_url`: `# <-- CHANGE THIS`
- A comment above each alert explaining the burn rate multiple and its meaning

**Variables** at the top of the file:
```yaml
# SLO_TARGET: 0.999  # 99.9% availability  # <-- CHANGE THIS
# SERVICE_LABEL: app  # label used to identify the service  # <-- CHANGE THIS
```

### 3. `observability/prometheus/slos/latency-slo.yaml`

Equivalent rules for latency SLO:
- Recording rules for P99 latency using `histogram_quantile` and `rate` over the same windows
- A single alert: `LatencySLOBreach` firing when P99 exceeds the SLO threshold for 5 minutes
- `LATENCY_THRESHOLD_SECONDS: 0.5` variable marked `# <-- CHANGE THIS`

## Style rules

- Every PromQL expression must have an inline comment explaining its logic
- Recording rule names must follow the `slo:<metric>:<aggregation>` naming convention
- Alert annotations must use label templating (`{{ $labels.app }}`) to identify which service is breaching
- Include a `# CALIBRATION NOTE:` comment on each alert explaining how to tune the burn rate multiple for different SLO targets
```

---

## Feature 10 — Missing Documentation Files

**Prompt file:** `.github/prompts/MissingDocs.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate the missing referenced documentation files: github-actions-oidc.md, environment-strategy.md, onboarding.md, and ADR templates.'
---

# Missing Documentation Generator

You are a senior platform engineer and technical writer. Generate the documentation files that are referenced throughout this repo but do not yet exist.

## Context

Search the entire codebase for references to these files and understand what they should contain:
- `docs/guides/github-actions-oidc.md` — referenced in cd/pulumi/deploy.yml, ci/github-actions/terraform/plan-apply.yml, backup/
- `docs/guides/environment-strategy.md` — referenced in observability/, cd/
- `docs/guides/secrets-management.md` — check if it exists; if not, create it
- `docs/guides/branching-strategy.md` — check if it exists
- `GETTING_STARTED.md` — exists; review what scenarios are missing and add them

## Your deliverables

### 1. `docs/guides/github-actions-oidc.md`

A comprehensive guide covering:
- **What OIDC is** and why it replaces long-lived credentials (one paragraph, non-technical)
- **AWS OIDC setup**: step-by-step for creating the IAM OIDC provider, trust policy, and IAM role; include the exact trust policy JSON with `# <-- CHANGE THIS` on account ID, org/repo, and branch conditions
- **Azure OIDC setup**: creating a federated credential on a managed identity via Azure CLI and Portal; include the exact `az ad app federated-credential create` command
- **GCP Workload Identity Federation**: creating the workload identity pool and provider; the `gcloud` commands, exact JSON attribute mapping
- **Testing**: how to verify OIDC is working — a minimal workflow that just prints `aws sts get-caller-identity` / `az account show` / `gcloud config list`
- **Troubleshooting**: the five most common errors (wrong audience, wrong subject claim format, missing permissions, token expiry, wrong region)
- A table summarising the GitHub Actions secret names used across the repo (`AWS_DEPLOY_ROLE_ARN`, `AZURE_CLIENT_ID`, etc.)

### 2. `docs/guides/environment-strategy.md`

Cover:
- **The three environments** used in this repo: dev, staging, production
- **Namespace strategy**: one namespace per environment per cluster (`dev`, `staging`, `production`) vs one cluster per environment; when to use each; this repo uses namespace-per-environment for simplicity
- **Configuration differences**: table showing what changes between environments (replica count, resource limits, image tags, TLS, autoscaling)
- **Promotion flow**: dev → staging → production; what gates exist at each step (automated tests, manual approval)
- **Environment labels**: the Kubernetes `environment` label enforced by Kyverno and used by Grafana, Loki, and NetworkPolicy selectors
- **IaC alignment**: how Terraform workspaces or separate state files map to environments; this repo uses separate state keys per module

### 3. `docs/guides/onboarding.md`

A "day one" guide structured as a sequence of steps:

1. Prerequisites checklist (Docker, VS Code, git)
2. Clone the repo and open in devcontainer (`Reopen in Container`)
3. Verify tools: run `bash .devcontainer/scripts/post-create.sh` and check output
4. Start a local Kubernetes cluster: `bash local-dev/kind/setup.sh`
5. Verify the cluster: open `http://localhost/` and `http://localhost/helm`
6. Make a small change: edit `cd/helm/webapp/values.dev.yaml` (change replica count) and re-apply
7. Open a PR: the pre-commit hooks that will run, what to expect
8. Explore the repo: pointer to `GETTING_STARTED.md` for finding the right template for their use case

Include expected time for each step and common failure resolutions.

### 4. `docs/decisions/ADR-004-secret-management.md`

An Architecture Decision Record covering:
- **Context**: the need to consume secrets from cloud KMS/secret stores without baking them into Kubernetes manifests
- **Decision**: External Secrets Operator as the bridge layer
- **Alternatives considered**: Sealed Secrets (requires cluster-specific encryption key, harder DR), Vault (operational overhead), raw Kubernetes Secrets (no rotation, base64 is not encryption)
- **Consequences**: positive (centralised rotation, audit trail, no secrets in Git) and negative (ESO is an additional dependency, if ESO is down new secret versions won't sync)

### 5. `docs/decisions/ADR-005-observability-stack.md`

An ADR covering:
- **Context**: need for metrics, logs, and traces without vendor lock-in
- **Decision**: Prometheus + Loki + Tempo (Grafana stack) with OpenTelemetry as the instrumentation layer
- **Alternatives considered**: Datadog (vendor lock-in, cost at scale), Elastic Stack (higher operational complexity, licensing), CloudWatch/Azure Monitor/Cloud Logging (cloud-specific, harder multi-cloud)
- **Consequences**: OpenTelemetry SDK means instrumentation is portable; Grafana stack is self-hosted so cost is predictable

### 6. `docs/decisions/ADR-006-policy-engine.md`

An ADR covering:
- **Decision**: Kyverno for admission control, Checkov/tfsec for IaC static analysis
- **Alternatives considered**: OPA/Gatekeeper (Rego has steeper learning curve, Kyverno's YAML-native policies are more accessible to platform teams without a dedicated security engineer), jsPolicy
- **Consequences**: Kyverno policies are easier to read and write but have less expressive power than Rego for complex policy logic

### 7. Update `GETTING_STARTED.md`

Add missing scenario rows:
- "I need to configure OIDC for GitHub Actions" → `docs/guides/github-actions-oidc.md`
- "I need to back up my cluster" → `backup/velero/README.md`
- "I need to rotate a secret" → `secrets/rotation/`
- "I need to understand environment differences" → `docs/guides/environment-strategy.md`
- "I'm new to this repo" → `docs/guides/onboarding.md`
- "I need to set up TLS certificates" → `cd/kubernetes/cert-manager/README.md`

## Style rules

- ADRs follow the MADR (Markdown Any Decision Record) format
- Guides use numbered steps for procedures and tables for reference information
- Every CLI command must be a complete copy-paste-ready command with `# <-- CHANGE THIS` on variable parts
- No guide should assume knowledge of another guide without linking to it explicitly
```

---

## Feature 11 — Makefile and Repo Scaffolding

**Prompt file:** `.github/prompts/Makefile.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'runCommands', 'search']
description: 'Generate a root Makefile with common development targets that wrap existing scripts and commands.'
---

# Makefile Generator

You are a senior platform engineer. Generate a root `Makefile` that wraps the most common operations in this repository behind memorable, discoverable targets.

## Context

Read these files first:
- `local-dev/kind/setup.sh`, `teardown.sh`, `load-image.sh` — local cluster scripts
- `.devcontainer/scripts/post-create.sh` — tool verification
- `.pre-commit-config.yaml` — linting and checking hooks
- `GETTING_STARTED.md` — what users need to do

## Your deliverables

### 1. `Makefile`

A POSIX-compatible Makefile with these targets, each with a `##` comment for `make help`:

**Local development:**
- `make help` — prints all targets and their descriptions (self-documenting via `##` comments)
- `make dev` — runs `bash local-dev/kind/setup.sh`
- `make dev-down` — runs `bash local-dev/kind/teardown.sh`
- `make load-image IMAGE=<image>` — runs `bash local-dev/kind/load-image.sh $(IMAGE)`
- `make verify-tools` — runs `bash .devcontainer/scripts/post-create.sh`

**Quality:**
- `make lint` — runs `pre-commit run --all-files`
- `make lint-install` — runs `pre-commit install && pre-commit install --hook-type pre-push`
- `make tf-fmt` — runs `terraform fmt -recursive .` across all Terraform directories
- `make tf-validate MODULE=<path>` — runs `terraform init -backend=false && terraform validate` in `$(MODULE)`

**Kubernetes:**
- `make k-apply-dev` — runs `kubectl apply -k cd/kubernetes/_overlays/dev/`
- `make k-apply-prod` — runs `kubectl apply -k cd/kubernetes/_overlays/prod/` with a confirmation prompt
- `make k-diff ENV=dev` — runs `kubectl diff -k cd/kubernetes/_overlays/$(ENV)/`

**Security:**
- `make scan-secrets` — runs `gitleaks detect --source . --verbose`
- `make scan-iac` — runs `checkov -d terraform --quiet`

**Utilities:**
- `make docs-check` — finds markdown files with broken internal links using a simple `grep` for `](.` patterns that point to non-existent files
- `make clean` — removes `.terraform` lock files and plan outputs (with a confirmation prompt)

Requirements:
- `.PHONY` declaration for all non-file targets
- `@echo` for user-facing output so commands are readable
- Guard variables (`ifndef IMAGE`) for targets that require them
- Confirmation prompts for destructive targets (`make clean`, `make k-apply-prod`) using `read -r -p`
- Coloured output using ANSI codes for the `make help` target

## Style rules

- Makefile comments (`##`) must be on the same line as the target for auto-documentation
- Every target that calls a script must check that the script exists before running it
- Variable names in UPPER_CASE; target names in lowercase with hyphens
```

---

## Feature 12 — GitHub Repo Scaffolding

**Prompt file:** `.github/prompts/RepoScaffolding.prompt.md`

```markdown
---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate CODEOWNERS, PR template, issue templates, and the missing referenced docs to complete repo scaffolding.'
---

# Repository Scaffolding Generator

You are a senior platform engineer. Generate the GitHub repository configuration files that make collaboration and contribution consistent.

## Context

Read these files first:
- `GETTING_STARTED.md` — understand the repo's intended audience
- `.github/dependabot.yml` — team email/ownership patterns
- `.github/workflows/` — existing workflow patterns

## Your deliverables

### 1. `.github/CODEOWNERS`

A CODEOWNERS file with sections:
- Default owner for everything: `* @platform-team` with `# <-- CHANGE THIS`
- Terraform modules: `terraform/ @infra-team` with `# <-- CHANGE THIS`
- Security scanning: `security/ @security-team` with `# <-- CHANGE THIS`
- Observability: `observability/ @sre-team` with `# <-- CHANGE THIS`
- Documentation: `docs/ @platform-team` with `# <-- CHANGE THIS`
- Kubernetes policy: `policy/ @security-team @platform-team` with `# <-- CHANGE THIS`
- Comment at top explaining that CODEOWNERS requires branch protection with "Require review from Code Owners" enabled

### 2. `.github/PULL_REQUEST_TEMPLATE.md`

A PR template with sections:
- **What does this PR do?** (one-line summary)
- **Type of change** (checkboxes: New template, Bug fix, Documentation, Dependency update, Breaking change)
- **Testing done** (checkboxes: Tested in local Kind cluster, Pre-commit hooks pass, Terraform plan reviewed, Checkov/tfsec scan clean)
- **Checklist** (checkboxes: `# <-- CHANGE THIS` markers removed or justified, README updated, GETTING_STARTED.md updated if new scenario added, ADR created if architectural decision made)
- **Related issues** (free text)

### 3. `.github/ISSUE_TEMPLATE/new-template-request.yml`

A structured issue template for requesting a new DevOps template:
- Fields: technology/tool name, use case description, existing workaround, priority (Low/Medium/High)
- Label: `template-request`

### 4. `.github/ISSUE_TEMPLATE/bug-report.yml`

A bug report template for when an existing template doesn't work:
- Fields: template file path, expected behaviour, actual behaviour, environment (cloud provider, Kubernetes version), reproduction steps
- Label: `bug`

### 5. `.github/ISSUE_TEMPLATE/config.yml`

Issue template chooser config that disables blank issues and links to GETTING_STARTED.md for general questions.

## Style rules

- CODEOWNERS team names should be clearly marked as placeholders
- PR template checkboxes should be unchecked by default
- Issue templates should use `required: true` on critical fields
```

---

## Execution Order

When implementing all features, work in this sequence to avoid dependency issues:

1. **Feature 10 (Missing Docs)** — creates `docs/guides/` files that other features reference
2. **Feature 11 (Makefile)** — self-contained, unblocked
3. **Feature 12 (Repo Scaffolding)** — self-contained
4. **Feature 5 (NetworkPolicy)** — depends on understanding existing labels
5. **Feature 6 (RBAC)** — depends on understanding existing resources
6. **Feature 3 (cert-manager)** — depends on existing ingress manifests
7. **Feature 2 (Database Migrations)** — depends on existing deployment patterns
8. **Feature 1 (Secret Rotation)** — can run in parallel with 2-6
9. **Feature 4 (Backup/DR)** — depends on Terraform module understanding
10. **Feature 7 (Terraform Ops)** — depends on existing plan/apply workflow
11. **Feature 8 (Tempo)** — depends on understanding existing observability stack
12. **Feature 9 (SLO Alerts)** — depends on Feature 8 (Tempo) and existing Prometheus setup

---

## Quality Gates

After each feature, verify:

```bash
# Pre-commit passes
make lint

# No broken CHANGE THIS markers left unreplaced in generated files
grep -r "CHANGE THIS" <new-directory> | wc -l  # should be intentional markers only

# YAML is valid
find <new-directory> -name "*.yaml" -o -name "*.yml" | xargs python3 -m yaml.parser 2>&1

# Shell scripts are valid
find <new-directory> -name "*.sh" | xargs shellcheck

# New scenario added to GETTING_STARTED.md
grep -c "new-directory" GETTING_STARTED.md
```