# Golden Path — Multi-Tenant SaaS

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are building a SaaS product on Kubernetes and need to serve multiple customers from a shared cluster
- You need tenant isolation at the namespace, RBAC, network, and data layers
- You need automated, repeatable tenant onboarding without manual Kubernetes operations
- You need billing instrumentation to meter per-tenant usage

Not the right path? See:
- [kubernetes-microservice.md](kubernetes-microservice.md) — single-tenant microservice without isolation requirements
- [database-migrations.md](database-migrations.md) — schema migration workflow used by this path for per-tenant schemas

---

## Prerequisites

Run the environment checker before anything else:

```bash
bash scripts/env-checker.sh
```

Required tools:

| Tool | Version | Purpose |
|------|---------|---------|
| kubectl | 1.29+ | Namespace, RBAC, and NetworkPolicy management |
| Terraform | 1.7+ | Cluster provisioning |
| Helm | 3.14+ | Tenant chart deployments |

Full install guide: [docs/guides/onboarding.md](../guides/onboarding.md)

---

## Flow

```
design isolation model → provision cluster → onboard first tenant
→ namespace + RBAC → network isolation → per-tenant secrets
→ per-tenant schema → billing instrumentation → tenant offboarding
→ observability → guardrails
```

---

## Step 1 — Choose an isolation model

Select the isolation model before provisioning anything. This decision affects cluster sizing, cost, and compliance posture.

| Model | Isolation | Cost | When to use |
|-------|-----------|------|-------------|
| Namespace-per-tenant | Network + RBAC | Low | **Default** — up to ~100 tenants per cluster |
| Cluster-per-tenant | Full | High | Regulated industries (HIPAA, PCI-DSS), contractual isolation requirements |
| Shared namespace + labels | Minimal | Lowest | Internal tools, low-risk tenants only |

> **Scale limit:** Namespace-per-tenant scales to approximately 100 tenants per cluster before Kubernetes control plane overhead (etcd, API server watch lists) becomes significant. Beyond that, provision additional clusters.

This path documents the **namespace-per-tenant** model. Cluster-per-tenant follows the same steps but repeats the cluster provisioning (Step 2) for each tenant.

---

## Step 2 — Provision the cluster

> Skip this step if a cluster already exists. Check with your platform team first.

Multi-tenant clusters need larger node pools than single-tenant clusters — plan for at least 3 nodes per availability zone to accommodate namespace-level resource quotas across all tenants.

```bash
cd terraform/aws-eks    # or azure-aks / gcp-gke
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Directories:
- [`terraform/aws-eks/`](../../terraform/aws-eks/) — EKS on AWS
- [`terraform/azure-aks/`](../../terraform/azure-aks/) — AKS on Azure
- [`terraform/gcp-gke/`](../../terraform/gcp-gke/) — GKE on GCP

---

## Step 3 — Tenant onboarding automation

Onboarding a new tenant is triggered by adding a YAML record to the tenant registry in the repository. A CI job detects the new file and runs the onboarding automation.

### Tenant registry entry

Create a file at `tenants/<slug>.yaml` with all six required fields:

```yaml
# tenants/acme.yaml
slug: acme
tier: pro
region: us-east-1
db_schema: acme
status: active
notification_email: ops@acme.example.com
```

| Field | Description |
|-------|-------------|
| `slug` | Kebab-case identifier, unique and immutable |
| `tier` | `free` \| `pro` \| `enterprise` |
| `region` | AWS/Azure/GCP region code |
| `db_schema` | Database schema name (usually equals `slug`) |
| `status` | `active` \| `offboarding` \| `offboarded` |
| `notification_email` | Ops contact for this tenant |

### Resources created by onboarding

The onboarding automation creates exactly six resources per tenant:

1. **Kubernetes namespace** — `tenant-<slug>`
2. **RBAC roles** — developer and read-only roles scoped to the namespace
3. **NetworkPolicy** — deny-all default with explicit allow-list rules
4. **External Secrets store config** — ESO namespace-scoped secret store for the tenant
5. **Database schema** — per-tenant schema via the database-migrations golden path
6. **ArgoCD Application** — points at the tenant's Helm values file

> **Idempotency guarantee:** The onboarding job is idempotent. If it fails mid-way, re-running it is safe — resources that already exist are left unchanged.

ArgoCD Application template: [`cd/gitops/argocd/application.yaml`](../../cd/gitops/argocd/application.yaml)

---

## Step 4 — Namespace and RBAC

Apply the namespace, base RBAC roles, and network isolation policies for the new tenant:

```bash
# Create the tenant namespace
kubectl create namespace tenant-acme

# Apply base RBAC (developer + read-only roles scoped to namespace)
kubectl apply -k cd/kubernetes/_base/rbac/ -n tenant-acme

# Apply deny-all NetworkPolicy (no traffic in or out by default)
kubectl apply -f cd/kubernetes/_base/network-policies/default-deny.yaml -n tenant-acme

# Allow egress to the shared database cluster
kubectl apply -f cd/kubernetes/_base/network-policies/allow-egress-to-database.yaml -n tenant-acme

# Allow egress to DNS (required for service discovery)
kubectl apply -f cd/kubernetes/_base/network-policies/allow-egress-to-dns.yaml -n tenant-acme

# Allow ingress from the ingress controller (external traffic)
kubectl apply -f cd/kubernetes/_base/network-policies/allow-ingress-from-ingress-controller.yaml -n tenant-acme
```

RBAC files: [`cd/kubernetes/_base/rbac/`](../../cd/kubernetes/_base/rbac/)  
NetworkPolicy files: [`cd/kubernetes/_base/network-policies/`](../../cd/kubernetes/_base/network-policies/)

---

## Step 5 — Per-tenant secrets

Each tenant gets its own isolated set of secrets. The naming convention is `tenant-<slug>-<secret-name>`.

### External Secret example

```yaml
# Adapted from secrets/external-secrets/example-external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: tenant-acme-db-credentials
  namespace: tenant-acme
spec:
  secretStoreRef:
    name: aws-secret-store   # or azure-secret-store / gcp-secret-store
    kind: SecretStore
  target:
    name: app-db-credentials
  data:
    - secretKey: DB_HOST
      remoteRef:
        key: /tenants/acme/db
        property: host
    - secretKey: DB_PASSWORD
      remoteRef:
        key: /tenants/acme/db
        property: password
```

Secret store configs: [`secrets/external-secrets/`](../../secrets/external-secrets/)  
Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

> **Isolation guarantee:** Each tenant's ExternalSecret is scoped to its own namespace. RBAC prevents workloads in `tenant-acme` from reading secrets in `tenant-globex`.

---

## Step 6 — Per-tenant schema

Schema-per-tenant is the default data isolation model. Each tenant gets a dedicated schema in the shared database cluster, connected via a tenant-scoped connection string.

```bash
# Run the migration Job scoped to the tenant namespace
kubectl apply -f cd/kubernetes/_patterns/db-migration-job.yaml \
  -n tenant-acme
```

The migration Job reads the tenant's database credentials from the External Secret created in Step 5.

Cross-link: [database-migrations.md](database-migrations.md) — full migration workflow including expand/contract pattern, CI integration, and rollback procedures.

> **Scale limit:** Schema-per-tenant on a shared database cluster scales to approximately 1,000 tenants before connection pool exhaustion becomes a concern. At that scale, deploy [PgBouncer](https://www.pgbouncer.org/) or an equivalent connection pooler in front of the database.

---

## Step 7 — Billing instrumentation

Billing is driven by Prometheus metrics exported from each tenant's workloads. All metrics **MUST** carry a `tenant` label to enable per-tenant aggregation.

### Recording rule

Add the following recording rule to `observability/prometheus/`:

```yaml
groups:
  - name: tenant_billing
    rules:
      - record: tenant:api_requests:rate5m
        expr: sum by (tenant) (rate(http_requests_total[5m]))
```

This rule aggregates per-tenant API request rates into a single time series per tenant, which the billing exporter reads to emit usage records.

Reference: [`observability/prometheus/`](../../observability/prometheus/) — add tenant-scoped alert rules and recording rules here.

> **Label requirement:** Any Prometheus metric that does not carry a `tenant` label cannot be attributed to a specific tenant for billing. Enforce this with the Kyverno policy in the Guardrails section.

---

## Step 8 — Tenant offboarding

Offboarding must be deliberate and audited. Follow these steps in order — do not skip or reorder them.

### Offboarding checklist

- [ ] **1. Mark tenant as offboarding** — update `status: offboarding` in `tenants/<slug>.yaml` and merge the PR
- [ ] **2. Export tenant data via Velero namespace backup** — ensure billing metrics are exported to the billing system first, then take a Velero namespace snapshot:
  ```bash
  kubectl apply -f backup/velero/namespace-backup.yaml
  # Verify the backup completed before proceeding
  ```
- [ ] **3. Delete the ArgoCD Application** — stops all deployments to the tenant namespace:
  ```bash
  kubectl delete application tenant-acme -n argocd
  ```
- [ ] **4. Delete the namespace** — removes all workloads, services, and network policies:
  ```bash
  kubectl delete namespace tenant-acme
  ```
- [ ] **5. Drop the tenant schema** — **manual DBA step, requires explicit approval**
- [ ] **6. Remove the tenant's secrets from the secrets store** — delete the tenant's entries from the secrets store

> **Schema drop policy:** Dropping the tenant schema requires explicit DBA approval and **MUST NOT be automated**. The DBA must verify the Velero backup is complete and the tenant has confirmed data export before executing the `DROP SCHEMA` command.

> **Billing metrics gate:** Billing metrics MUST be exported before the namespace is deleted (Step 5). Once the namespace is gone, in-flight metrics are lost permanently.

Velero files: [`backup/velero/`](../../backup/velero/)

---

## Step 9 — Observability

### Prometheus alert rules

Add tenant-level alert rules to [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/). Example alerts to configure:

- Alert when a tenant's error rate exceeds 5% for more than 5 minutes
- Alert when a tenant's API latency p99 exceeds 2 seconds
- Alert when a tenant's namespace has no running pods (possible onboarding failure)

### Notification routing

Route tenant alerts to the appropriate channels:

| File | Purpose |
|------|---------|
| [`notifications/pagerduty-notify.yml`](../../notifications/pagerduty-notify.yml) | Page on-call for critical tenant failures |
| [`notifications/slack-notify.yml`](../../notifications/slack-notify.yml) | Notify team channel for warnings |

---

## Guardrails

These rules are enforced by automation. Violations are blocked at the cluster level.

| Rule | Enforced by |
|------|-------------|
| Namespace-per-tenant | Onboarding automation — each tenant record creates exactly one namespace |
| NetworkPolicy deny-all default | [`cd/kubernetes/_base/network-policies/default-deny.yaml`](../../cd/kubernetes/_base/network-policies/default-deny.yaml) applied to every tenant namespace |
| `tenant` label required on all resources | [`policy/kyverno/require-labels.yaml`](../../policy/kyverno/require-labels.yaml) — extend to require `tenant` label in multi-tenant clusters |
| Per-tenant secrets isolation | RBAC scoped to namespace + ESO namespace-scoped SecretStore — no cross-tenant secret access |
| Schema-per-tenant isolation | Application-level connection string scoping — each tenant's workload connects only to its own schema |
| Offboarding data export gate | Step 8 checklist — Velero backup must complete before namespace deletion |
| Billing metrics export gate | Step 8 checklist — billing metrics must be exported before namespace deletion |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Application code with `tenant` label on all metrics; tenant registry YAML entries; per-tenant Helm values |
| Platform team | Cluster provisioning (Step 2); onboarding automation; RBAC and NetworkPolicy templates; ArgoCD Application management; Velero backup configuration |
| DBA | Schema creation and migration review; schema drop approval during offboarding (Step 8, item 6) |

---

## Related paths and guides

- [kubernetes-microservice.md](kubernetes-microservice.md) — base path this extends; use for single-tenant services
- [database-migrations.md](database-migrations.md) — per-tenant schema creation and migration workflow
- [platform-onboarding.md](platform-onboarding.md) — cluster and namespace foundations
- [docs/guides/secrets-management.md](../guides/secrets-management.md) — full guide to per-tenant secret stores
