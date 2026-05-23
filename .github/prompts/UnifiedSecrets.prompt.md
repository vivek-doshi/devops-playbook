---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Unify the split secrets directory structure: merge secrets/external-secrets/, secrets/rotation/, and ci-security/secret-rotation/ into a single coherent secrets/ hierarchy with a unified README, cross-linked guides, and a secrets golden path covering the full lifecycle from provisioning to rotation to offboarding.'
---

# Unified Secrets Directory Generator

You are a senior platform engineer specializing in secrets management at scale. Your task is to unify the repository's fragmented secrets structure into a single coherent layer without breaking existing references.

## Mandatory context reads (do these before writing any file)

- `secrets/external-secrets/README.md` — current ESO documentation; your unified README must be a superset of this
- `secrets/external-secrets/aws-secret-store.yaml` — understand the pattern; do not modify this file
- `secrets/external-secrets/azure-secret-store.yaml` — understand the pattern; do not modify this file
- `secrets/external-secrets/gcp-secret-store.yaml` — understand the pattern; do not modify this file
- `secrets/external-secrets/example-external-secret.yaml` — understand the pattern; do not modify this file
- `secrets/rotation/aws-rotation.yml` — understand the pattern; do not modify this file
- `secrets/rotation/azure-rotation.yml` — understand the pattern; do not modify this file
- `secrets/rotation/gcp-rotation.yml` — understand the pattern; do not modify this file
- `docs/guides/secrets-management.md` — this guide must be updated to reference the new unified structure
- `docs/golden-paths/kubernetes-microservice.md` — Step 10 references `secrets/`; your output must be consistent with that step
- `docs/golden-paths/platform-onboarding.md` — Step 6 references `secrets/`; your output must be consistent
- `docs/ARCHITECTURE_DECISION_GUIDE.md` — Section 4 "Secret Management" is the decision reference; do not contradict it
- `cd/kubernetes/_base/deployment.yaml` — shows how secrets are consumed via `envFrom`; reference this in examples
- `.ai/instructions/security-rules.md` — all security rules apply
- `.ai/context/terminology.md` — use canonical terms

## Current state (the problem)

The secrets concern is currently split across three locations:
- `secrets/external-secrets/` — ESO ClusterSecretStore configs and ExternalSecret example
- `secrets/rotation/` — GitHub Actions rotation workflows (AWS, Azure, GCP)
- `ci-security/secret-rotation/` — a separate secret rotation directory that overlaps with `secrets/rotation/`

A developer trying to implement secrets management must read three READMEs and discover two rotation directories. This causes confusion during onboarding and increases the chance of choosing the wrong pattern.

## Target structure

Your task is to create the following structure. Do NOT move or rename existing YAML files — only create new files and update existing ones.

```
secrets/
├── README.md                          # REPLACE with unified README (see spec below)
├── external-secrets/                  # UNCHANGED — do not touch these files
│   ├── README.md                      # UNCHANGED
│   ├── aws-secret-store.yaml
│   ├── azure-secret-store.yaml
│   ├── gcp-secret-store.yaml
│   └── example-external-secret.yaml
├── rotation/                          # UNCHANGED — do not touch these files
│   ├── aws-rotation.yml
│   ├── azure-rotation.yml
│   └── gcp-rotation.yml
└── guides/                            # NEW directory
    ├── secret-lifecycle.md            # NEW — full lifecycle guide
    ├── emergency-rotation.md          # NEW — break-glass procedure
    └── secret-offboarding.md         # NEW — what to do when a service is decommissioned
```

## Your deliverables

### 1. `secrets/README.md` (replace existing)

A unified top-level README that serves as the single entry point for all secrets concerns.

**Structure**:

**Why this directory exists** — One paragraph. Secrets (passwords, API keys, certificates, connection strings) must never be in Git, never hardcoded in manifests, and never stored as long-lived credentials in CI pipelines. This directory provides the patterns to satisfy all three constraints.

**Decision tree** (replicate the decision tree format from `docs/ARCHITECTURE_DECISION_GUIDE.md` Section 4 exactly):

```
What do you need?
├── Store a new secret for an application → secrets/external-secrets/
│   ├── AWS → aws-secret-store.yaml + example-external-secret.yaml
│   ├── Azure → azure-secret-store.yaml + example-external-secret.yaml
│   └── GCP → gcp-secret-store.yaml + example-external-secret.yaml
│
├── Rotate an existing secret → secrets/rotation/
│   ├── AWS → aws-rotation.yml
│   ├── Azure → azure-rotation.yml
│   └── GCP → gcp-rotation.yml
│
├── Understand the full secret lifecycle → secrets/guides/secret-lifecycle.md
├── Emergency rotation (breach response) → secrets/guides/emergency-rotation.md
└── Decommission a service's secrets → secrets/guides/secret-offboarding.md
```

**Quick start** (4 commands, one per cloud, showing the minimum to get a secret syncing):

```bash
# AWS (EKS + IRSA)
kubectl apply -f secrets/external-secrets/aws-secret-store.yaml
cp secrets/external-secrets/example-external-secret.yaml secrets/external-secrets/my-app.yaml
# edit my-app.yaml, then:
kubectl apply -f secrets/external-secrets/my-app.yaml

# Verify sync
kubectl get externalsecret my-app -n <namespace>
```

Show equivalent blocks for Azure and GCP.

**Authentication model** (one paragraph per cloud): Explain IRSA, Workload Identity (Azure), and Workload Identity (GCP) in plain language. Include a table: cloud | mechanism | credential stored in cluster? The answer for all three is No — make this explicit.

**Related files table**:

| File | Purpose |
|---|---|
| `docs/guides/secrets-management.md` | Strategic guide — which tool for which scenario |
| `docs/ARCHITECTURE_DECISION_GUIDE.md` Section 4 | Decision framework |
| `docs/golden-paths/kubernetes-microservice.md` Step 10 | How secrets fit into service delivery |
| `docs/golden-paths/platform-onboarding.md` Step 6 | How to set up the secrets layer for a new team |
| `ci-security/secret-rotation/` | Alternative rotation patterns (Terraform-managed) |

### 2. `secrets/guides/secret-lifecycle.md`

A complete lifecycle guide from secret creation to deletion.

**Sections**:

**1. Provisioning a secret** — Step-by-step for each cloud. When to use `dataFrom` (extract all keys) vs `data` (map individual keys). How to name secrets consistently: `/service-name/environment/secret-name` pattern. How long `refreshInterval` should be set (1h default, 15m for high-rotation secrets, 24h for stable infrastructure creds).

**2. Consuming a secret in a pod** — Show the `envFrom.secretRef` pattern from `cd/kubernetes/_base/deployment.yaml`. Show the `volumes.secret` pattern for file-mounted secrets. Explain when to use each: env vars for config, files for certificates and multi-line values.

**3. The rollout-after-rotation problem** — This is the most commonly missed issue. Explain in plain language: ESO updates the Kubernetes Secret, but pods reading environment variables only pick up the new value on restart. Provide the three remediation options:
   - Manual: `kubectl rollout restart deployment/<name>`
   - Automated: the rotation workflows in `secrets/rotation/` handle this automatically
   - Proactive: mount secrets as volumes instead of env vars (volumes refresh without restart)

**4. Monitoring secret sync** — Commands to check ExternalSecret status, force a refresh, and interpret error states. Include the Loki query to find ESO sync failures in logs.

**5. Rotation cadence guidance** (table):

| Secret type | Recommended rotation | Mechanism |
|---|---|---|
| Database passwords | 90 days | `secrets/rotation/<cloud>-rotation.yml` |
| API keys (external SaaS) | 180 days or on provider schedule | Manual + rotation workflow |
| TLS certificates | cert-manager handles automatically | `cd/kubernetes/cert-manager/` |
| CI/CD OIDC federation | Does not rotate — short-lived by design | N/A |
| Container registry tokens | Managed by cloud provider | N/A |

### 3. `secrets/guides/emergency-rotation.md`

A break-glass procedure for when a secret has been compromised or is suspected to have been exposed.

**Trigger conditions** — When to use this guide: secret appears in a Git commit (even if force-pushed), TruffleHog or Gitleaks alert fires on a secret that matches a real credential, secret was exposed in logs or error messages, team member with access departs unexpectedly.

**Immediate steps** (numbered, time-boxed):

1. (0-5 min) Determine scope — which secret, which services consume it, which environments are affected. Commands to find all ExternalSecrets referencing a secret path.
2. (5-15 min) Rotate in the cloud store — commands for each cloud to set a new secret version. For AWS: `aws secretsmanager put-secret-value`. For Azure: `az keyvault secret set`. For GCP: `gcloud secrets versions add`.
3. (15-20 min) Force ESO sync — `kubectl annotate externalsecret <name> force-sync=$(date +%s) --overwrite`. Verify the Kubernetes Secret updated.
4. (20-30 min) Restart affected deployments — `kubectl rollout restart deployment/<name>`. Watch rollout status.
5. (30-60 min) Verify old credential no longer works — cloud-specific commands to disable or destroy the old secret version.
6. (60+ min) Audit access — review cloud provider access logs for the compromised credential. Document the exposure window.

**Escalation path** — if the compromised secret was a cloud provider credential (not an application secret), link to `secops/runbooks/secret-exposure.md` for the full incident response procedure.

**Post-incident** — update the rotation schedule for the affected secret, file a ticket to review how the exposure occurred.

### 4. `secrets/guides/secret-offboarding.md`

What to do with secrets when a service is decommissioned or a team is offboarded.

**Why this matters** — Orphaned secrets are an attack surface and a compliance liability. Every secret created must have a corresponding deletion procedure.

**Offboarding checklist** (mapped to the multi-tenant SaaS offboarding pattern in `docs/golden-paths/multi-tenant-saas.md` Step 8):

- [ ] Identify all ExternalSecrets for the service: `kubectl get externalsecret -A -l app=<service-name>`
- [ ] Delete ExternalSecret resources (triggers automatic deletion of the synced Kubernetes Secret if `creationPolicy: Owner`)
- [ ] Delete the upstream secret in the cloud store — commands for each cloud
- [ ] Revoke any IAM roles or service account bindings created for ESO access
- [ ] Audit rotation workflows — remove or disable scheduled rotation jobs for this service
- [ ] Confirm deletion in audit log — cloud-specific commands

**Do not delete immediately** — If the service's data is being migrated rather than deleted, keep the secret for 30 days after decommission to allow emergency data recovery. Add a tag/label to the upstream secret: `status=pending-deletion`, `deletion-date=YYYY-MM-DD`.

### 5. Update `docs/guides/secrets-management.md`

Add a new section at the top, after the introduction:

**"Secret implementation patterns"** — A navigation table:

| Task | Go to |
|---|---|
| Store and sync a secret to Kubernetes | `secrets/README.md` |
| Full lifecycle (provision → rotate → offboard) | `secrets/guides/secret-lifecycle.md` |
| Emergency rotation | `secrets/guides/emergency-rotation.md` |
| Decommission a service's secrets | `secrets/guides/secret-offboarding.md` |
| Terraform-managed rotation (alternative) | `ci-security/secret-rotation/` |
| OIDC federation for CI/CD | `docs/guides/github-actions-oidc.md` |

Do not modify any other content in this guide.

### 6. Update `GETTING_STARTED.md`

The existing "🔒 I need security scanning" section already exists. Add a separate section:

**🔑 "I need to manage secrets"**

| Need | File |
|---|---|
| Store a secret for my app (AWS/Azure/GCP) | [`secrets/external-secrets/`](secrets/external-secrets/) |
| Rotate a secret on a schedule | [`secrets/rotation/`](secrets/rotation/) |
| Understand the full secret lifecycle | [`secrets/guides/secret-lifecycle.md`](secrets/guides/secret-lifecycle.md) |
| Emergency: secret was exposed | [`secrets/guides/emergency-rotation.md`](secrets/guides/emergency-rotation.md) |

## Style rules

- Every guide must follow the existing documentation standards from `.ai/instructions/documentation-rules.md`
- The `secrets/README.md` decision tree must use the exact ASCII tree format from `docs/ARCHITECTURE_DECISION_GUIDE.md`
- File paths in guides must be relative links that actually resolve — verify against the repo map
- Every command block must have a comment explaining what it does and what success looks like
- Emergency rotation guide must never have more than 6 numbered steps in the immediate-steps section — brevity is safety-critical during an incident
- Do not duplicate content between guides — cross-link instead
- The secret-lifecycle.md rollout-after-rotation section must be written so a developer who has never thought about this problem before understands it in one read
