---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Generate a complete multi-cluster fleet management implementation: ArgoCD ApplicationSet patterns for fleet-wide deployment, cross-cluster Kyverno policy inheritance, fleet-level observability aggregation, and a golden path guide — designed for organizations operating 3-20 Kubernetes clusters across multiple clouds and environments.'
---

# Multi-Cluster Fleet Management Generator

You are a senior platform engineer with experience managing Kubernetes fleet operations at Google scale. Your task is to generate a complete multi-cluster fleet management implementation for this repository.

## Mandatory context reads (do these before writing any file)

- `cd/gitops/argocd/applicationset.yaml` — existing ApplicationSet; your fleet patterns extend this
- `cd/gitops/argocd/application.yaml` — existing single-app definition; understand the source format
- `cd/gitops/argocd/app-of-apps.yaml` — existing app-of-apps pattern; your fleet bootstrap extends this
- `cd/kubernetes/_base/` — all base manifests; understand what must be consistent across clusters
- `cd/kubernetes/_overlays/` — existing overlay structure; your fleet overlays mirror this
- `cd/helm/webapp/values.yaml` — understand the Helm values pattern
- `policy/kyverno/README.md` — Kyverno policies must propagate to all clusters
- `docs/decisions/ADR-003-gitops-strategy.md` — the GitOps principles that guide all fleet decisions
- `docs/decisions/ADR-002-helm-vs-kustomize.md` — Helm vs Kustomize applies at fleet level too
- `observability/prometheus/values.yaml` — understand the Prometheus setup; fleet observability aggregates these
- `terraform/aws-eks/main.tf` — understand how clusters are provisioned; fleet management assumes this foundation
- `docs/golden-paths/platform-onboarding.md` — Step 5 covers single namespace; your fleet path covers multi-cluster
- `docs/golden-paths/kubernetes-microservice.md` — Step 11 covers single-cluster ArgoCD; your fleet path is the multi-cluster equivalent
- `.ai/instructions/kubernetes-rules.md` — apply all Kubernetes rules
- `.ai/instructions/engineering-principles.md` — apply all principles
- `.ai/context/terminology.md` — use canonical terms

## Design constraints

- Maximum 20 clusters per fleet (ArgoCD ApplicationSet generator limit at recommended scale)
- Minimum 3 clusters before this pattern adds value over single-cluster ArgoCD
- Fleet-wide policies must degrade gracefully — a single cluster being unreachable must not block policy delivery to other clusters
- Never use `kubectl` federation or Kubernetes Federation v2 — ArgoCD ApplicationSet is the only approved federation mechanism in this repo
- Secret management remains per-cluster (ESO syncs per cluster) — no cross-cluster secret sharing
- Observability aggregation uses Prometheus remote_write to a central store — not Thanos or Cortex (too complex for a starter repo; add `# <-- UPGRADE PATH` comments)

## Fleet topology model

This implementation supports three fleet topologies. Your files must support all three via configuration, not separate templates:

**Hub-and-spoke** (default): One management cluster runs ArgoCD; all workload clusters are targets. Management cluster has no workloads.

**Distributed** (for regulated environments): Each cluster runs its own ArgoCD instance syncing from the same Git repo. No single point of failure.

**Hierarchical** (for large orgs): Regional hub clusters manage zone clusters. Two levels of ApplicationSet generators.

## Your deliverables

### 1. `cd/gitops/argocd/fleet/cluster-registry.yaml`

A `ConfigMap` that serves as the fleet's cluster registry. ArgoCD ApplicationSet generators read from this ConfigMap. This is the single source of truth for which clusters exist in the fleet.

**Structure**:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-registry
  namespace: argocd
  annotations:
    fleet.argocd.io/description: "Single source of truth for all clusters in this fleet"
    fleet.argocd.io/updated: "manual"  # This is human-maintained, not auto-generated
data:
  clusters: |
    - name: prod-us-east-1
      server: https://eks-prod-us-east-1.example.com    # <-- CHANGE THIS
      cloud: aws
      region: us-east-1
      environment: production
      tier: critical                    # critical | standard | dev
      labels:
        team: platform
        cost-center: infrastructure
      kyverno-enforcement: enforce      # enforce | audit
      prometheus-remote-write: enabled  # enabled | disabled
    - name: staging-us-east-1
      server: https://eks-staging-us-east-1.example.com # <-- CHANGE THIS
      cloud: aws
      region: us-east-1
      environment: staging
      tier: standard
      labels:
        team: platform
        cost-center: infrastructure
      kyverno-enforcement: audit
      prometheus-remote-write: enabled
    - name: dev-shared
      server: https://eks-dev.example.com               # <-- CHANGE THIS
      cloud: aws
      region: us-east-1
      environment: dev
      tier: dev
      labels:
        team: platform
        cost-center: engineering
      kyverno-enforcement: audit
      prometheus-remote-write: disabled
```

Add a comment block at the top explaining:
- How to add a new cluster (update this file + run the onboarding workflow)
- How ArgoCD reads this ConfigMap (ApplicationSet list generator)
- The relationship between `tier` and Kyverno enforcement mode
- The scale limit: this pattern supports up to 20 clusters before the ArgoCD ApplicationSet generator needs to switch to a pull-based model

### 2. `cd/gitops/argocd/fleet/fleet-applicationset.yaml`

The master ApplicationSet that deploys platform components to every cluster in the fleet. Uses the `list` generator reading from `cluster-registry.yaml`.

**What it deploys to every cluster** (one Application per component per cluster):

- `kyverno` — from `policy/kyverno/` via Kustomize
- `external-secrets-operator` — from the ESO Helm chart
- `prometheus-stack` — from `observability/prometheus/values.yaml` via Helm
- `cert-manager` — from `cd/kubernetes/cert-manager/` via Kustomize
- `fleet-network-policies` — from `cd/kubernetes/_base/network-policies/` via Kustomize

**Template structure** (the Application template):

```yaml
template:
  metadata:
    name: "{{cluster.name}}-{{component}}"
    labels:
      fleet.argocd.io/cluster: "{{cluster.name}}"
      fleet.argocd.io/component: "{{component}}"
      fleet.argocd.io/environment: "{{cluster.environment}}"
  spec:
    project: fleet-platform
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
        - ApplyOutOfSyncOnly=true  # Critical for fleet scale: only sync what changed
    # Retry with exponential backoff — a cluster being unreachable is temporary, not fatal
    retry:
      limit: 5
      backoff:
        duration: 30s
        factor: 2
        maxDuration: 5m
```

Add a comment explaining `ApplyOutOfSyncOnly=true`: at fleet scale, syncing 20 clusters × 5 components simultaneously creates API server load spikes. This option limits each sync to only changed resources.

### 3. `cd/gitops/argocd/fleet/fleet-workload-applicationset.yaml`

An ApplicationSet for deploying application workloads (not platform components) across selected clusters. Uses a matrix generator combining the cluster registry with a Git directory generator.

**Git directory path convention**: `cd/fleet-overlays/<environment>/<app-name>/`

**Matrix generator structure**:
```yaml
generators:
  - matrix:
      generators:
        - list:
            elements: "{{clusters | selectattr('environment', 'eq', targetEnvironment)}}"
        - git:
            repoURL: "{{repoURL}}"  # <-- CHANGE THIS
            revision: HEAD
            directories:
              - path: "cd/fleet-overlays/{{cluster.environment}}/*"
```

Add a comment explaining the matrix generator: it creates one Application per (cluster, app-directory) combination. For 5 clusters × 3 apps = 15 Applications, all managed by one ApplicationSet.

Add a comment explaining when to use this vs `fleet-applicationset.yaml`: platform components go in `fleet-applicationset.yaml` (every cluster gets them), application workloads go here (only clusters matching the target environment get them).

### 4. `cd/fleet-overlays/` directory structure

Create the directory structure with stub files showing the pattern. Do not create real application configs — only the structural files.

```
cd/fleet-overlays/
├── README.md                          # Explains the overlay convention
├── production/
│   └── .gitkeep                       # Add real apps here per team
├── staging/
│   └── webapp-example/
│       └── kustomization.yaml         # Example fleet overlay for one app
└── dev/
    └── .gitkeep
```

**`cd/fleet-overlays/staging/webapp-example/kustomization.yaml`**:

```yaml
# Example fleet overlay for the webapp Helm chart
# This overlay is deployed to every cluster with environment: staging
# by fleet-workload-applicationset.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../_base/webapp  # <-- CHANGE THIS: point to your app's base manifests
patches:
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 2
    target:
      kind: Deployment
      name: webapp
```

**`cd/fleet-overlays/README.md`**:

Explain the naming convention, the relationship to `fleet-workload-applicationset.yaml`, and how to add a new application to the fleet (create a directory here → ApplicationSet detects it → deploys to matching clusters).

### 5. `cd/gitops/argocd/fleet/fleet-project.yaml`

An ArgoCD `AppProject` resource that scopes what the fleet ApplicationSets are allowed to deploy. This is the security boundary for fleet-level GitOps.

**Permissions**:
- Source: only this repository (add `# <-- CHANGE THIS` on the repoURL)
- Destinations: all clusters registered in `cluster-registry.yaml` (wildcard server, specific namespaces: `kyverno`, `external-secrets-system`, `monitoring`, `cert-manager`, `argocd`, `fleet-*`)
- Cluster resources allowed: Namespace, ClusterRole, ClusterRoleBinding, ClusterPolicy (Kyverno)
- Namespace resources allowed: all (the fleet manages platform namespaces)

Add a comment: "This project intentionally uses broad permissions because it deploys platform components. Application teams should use separate AppProjects with narrower scope — see cd/gitops/argocd/application.yaml for the single-app pattern."

### 6. `policy/kyverno/fleet-policy-propagation.yaml`

A Kyverno `ClusterPolicy` that validates fleet-level label consistency. When this policy is deployed to every cluster in the fleet via `fleet-applicationset.yaml`, it ensures every cluster maintains the same labeling standards.

**Rules**:

- `require-fleet-namespace-labels` — every Namespace must have `fleet.argocd.io/cluster` and `environment` labels (validates that ArgoCD applied the fleet labels correctly)
- `require-fleet-workload-labels` — every Deployment in a non-system namespace must have `fleet.argocd.io/app` label (enables fleet-level filtering in Grafana)
- `deny-cross-cluster-secrets` — deny any Secret with the label `fleet.io/shared: "true"` (prevents accidental cross-cluster secret patterns)

Mode: Audit for all rules. Add a comment: "These rules are audit-only because they validate fleet management tool behavior, not user workloads. Failures indicate an ArgoCD configuration problem, not a developer error."

### 7. `observability/prometheus/fleet-aggregation.yaml`

A `PrometheusRule` and documentation for fleet-level metrics aggregation.

**Recording rules** (aggregate per-cluster metrics into fleet-level views):

```yaml
groups:
  - name: fleet.aggregate
    interval: 5m
    rules:
      - record: fleet:up:ratio
        expr: avg(up) by (cluster_name, environment)
        labels:
          fleet: "true"
      - record: fleet:pod_restart_rate:5m
        expr: sum(rate(kube_pod_container_status_restarts_total[5m])) by (cluster_name, namespace)
      - record: fleet:kyverno_violations:count
        expr: sum(kyverno_policy_results_total{result="fail"}) by (cluster_name, policy_name)
```

**`remote_write` configuration comment block** (add to the end of `observability/prometheus/values.yaml` as commented-out YAML):

```yaml
# Fleet observability: enable remote_write to aggregate metrics from all clusters
# into a central Prometheus or Thanos instance.
# Uncomment and configure when you have a central metrics store.
# <-- UPGRADE PATH: Replace central Prometheus with Thanos for long-term storage
#                   See: https://thanos.io/tip/thanos/quick-tutorial.md
#
# prometheus:
#   prometheusSpec:
#     remoteWrite:
#       - url: https://central-prometheus.example.com/api/v1/write  # <-- CHANGE THIS
#         basicAuth:
#           username:
#             name: central-prometheus-auth
#             key: username
#           password:
#             name: central-prometheus-auth
#             key: password
#         writeRelabelConfigs:
#           - sourceLabels: [__name__]
#             regex: fleet:.*    # Only send fleet-level recording rules, not raw metrics
#             action: keep
#         externalLabels:
#           cluster_name: <cluster-name>   # <-- CHANGE THIS per cluster via Kustomize patch
#           environment: <environment>     # <-- CHANGE THIS per cluster via Kustomize patch
```

### 8. `docs/golden-paths/multi-cluster-fleet.md`

A complete golden path in the exact format of `docs/golden-paths/kubernetes-microservice.md`.

**When to use this path**: organizations operating 3 or more Kubernetes clusters who need consistent platform component delivery, policy enforcement, and observability across all clusters without manual per-cluster configuration.

**Not the right path**: reference `platform-onboarding.md` Step 11 for single-cluster ArgoCD setup. Reference `kubernetes-microservice.md` Step 11 for deploying a single application to a single cluster.

**Scale guidance** (table at the top):

| Cluster count | Recommended approach |
|---|---|
| 1-2 | Single-cluster ArgoCD (`cd/gitops/argocd/application.yaml`) |
| 3-10 | This path — hub-and-spoke topology |
| 10-20 | This path — hierarchical topology |
| 20+ | Contact platform team — requires custom ApplicationSet generator |

**Flow**:
```
provision clusters (Terraform) → configure cluster-registry.yaml
→ deploy fleet ArgoCD project → deploy fleet-applicationset
→ platform components propagate to all clusters
→ add workload overlays to cd/fleet-overlays/
→ fleet-workload-applicationset deploys to matching clusters
→ Prometheus remote_write aggregates to central store
→ fleet-level alerts fire on any cluster
```

**Steps** (numbered, with exact file references):

1. Add all clusters to the registry: `cd/gitops/argocd/fleet/cluster-registry.yaml`
2. Create the fleet ArgoCD project: `cd/gitops/argocd/fleet/fleet-project.yaml`
3. Apply the fleet ApplicationSet for platform components: `cd/gitops/argocd/fleet/fleet-applicationset.yaml`
4. Verify platform components are deploying: `kubectl get applications -n argocd -l fleet.argocd.io/component`
5. Apply the fleet policy propagation: `policy/kyverno/fleet-policy-propagation.yaml`
6. Check policy compliance across all clusters: `kubectl get policyreport -A --context <each-cluster>`
7. Configure Prometheus remote_write for fleet observability (optional — see `observability/prometheus/fleet-aggregation.yaml`)
8. Add a workload application: create `cd/fleet-overlays/<environment>/<app-name>/kustomization.yaml`
9. Apply the workload ApplicationSet: `cd/gitops/argocd/fleet/fleet-workload-applicationset.yaml`

**Day-2 operations section** (unique to this path — no equivalent in single-cluster paths):

- How to add a new cluster: update `cluster-registry.yaml` → ApplicationSet detects it → platform components auto-deploy
- How to remove a cluster: set `kyverno-enforcement: audit` first, then remove from registry → ArgoCD prunes Applications
- How to emergency-patch all clusters: commit to the base manifests → all fleet ApplicationSets sync within their retry window
- How to skip one cluster during a rollout: add a temporary `suspend: true` to the specific Application resource

**Guardrails table**:

| Rule | Enforced by |
|---|---|
| No manual `kubectl apply` to fleet clusters | ArgoCD self-heal enabled |
| Platform components identical across clusters | Single ApplicationSet source |
| No cross-cluster secret sharing | `fleet-policy-propagation.yaml` deny rule |
| Cluster registry is human-maintained, not auto-generated | Comment in `cluster-registry.yaml` |
| Fleet scale limit: 20 clusters | Comment in `fleet-applicationset.yaml` |

### 9. Update `GETTING_STARTED.md`

Add under "🚀 I need to deploy to production":

| Deploy to multiple clusters (fleet management) | [`docs/golden-paths/multi-cluster-fleet.md`](docs/golden-paths/multi-cluster-fleet.md) |

### 10. Update `docs/decisions/ADR-003-gitops-strategy.md`

Add a new section at the end:

**Multi-cluster fleet extension (2026)**:

Document that `fleet-applicationset.yaml` using the list generator reading from `cluster-registry.yaml` was chosen over:
- Cluster API + GitOps — too complex for a starter repo
- ArgoCD cluster-config generator — tighter coupling between cluster provisioning and ArgoCD
- Flux multi-tenancy — viable but inconsistent with the ArgoCD default chosen in ADR-003

Consequences: cluster registry is human-maintained (toil at >20 clusters), but is explicit and auditable, which outweighs the automation benefit at the target scale.

## Style rules

- Every ArgoCD resource must include `finalizers: [resources-finalizer.argocd.argoproj.io]` on Applications and `cascade: true` on AppProjects — without these, ArgoCD orphans resources when Applications are deleted
- `retry.backoff` must be set on all fleet ApplicationSets — at fleet scale, transient failures are expected and must not trigger immediate re-sync storms
- `ApplyOutOfSyncOnly: true` must be in `syncOptions` for all fleet ApplicationSets — justify this in a comment
- Every `# <-- CHANGE THIS` comment must explain what to change, why it differs per cluster, and where to find the value
- The fleet cluster-registry ConfigMap must include the scale limit comment — this is the most important operational constraint
- `fleet-policy-propagation.yaml` must use Audit mode only — fleet management policy failures indicate ArgoCD problems, not user errors; blocking admission from a fleet policy would be catastrophic
- The golden path must include the "Day-2 operations" section — fleet management is primarily an operational concern, not a deployment concern
- All ArgoCD ApplicationSet generators must use the `list` generator reading from `cluster-registry.yaml`, not the `clusters` generator (which requires cluster secrets in ArgoCD) — add a comment explaining this design choice
