---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Kyverno policy-as-code that enforces organisational Kubernetes standards across all workloads in this repo.'
---

# Kyverno Policy Generator

You are a senior platform engineer and Kubernetes security specialist. Generate Kyverno policies that enforce the security and operational standards already demonstrated in this repo's Kubernetes manifests.

## Context

Read these files carefully — your policies must enforce what these files demonstrate as best practice:
- `cd/kubernetes/_base/deployment.yaml` — security context, resource limits, non-root user, read-only filesystem
- `cd/kubernetes/_base/hpa.yaml` — HPA requirements
- `cd/helm/webapp/templates/deployment.yaml` — Helm-deployed workload patterns
- `cd/kubernetes/_overlays/prod/kustomization.yaml` — production standards
- `docs/decisions/ADR-001-folder-structure.md` — understand what "organisational standards" means in this context

## Your deliverables

Create all policies in `policy/kyverno/`. Each policy must be a standalone YAML file.

### 1. `policy/kyverno/require-non-root.yaml`

A Kyverno `ClusterPolicy` (enforce mode) that:
- Validates that all Pods have `securityContext.runAsNonRoot: true`
- Validates that all containers have `securityContext.allowPrivilegeEscalation: false`
- Excludes namespaces: `kube-system`, `kube-public`, `monitoring` (Prometheus needs some privileges)
- Has a clear `message` explaining what to add and why
- References the pattern in `cd/kubernetes/_base/deployment.yaml` in a comment

### 2. `policy/kyverno/require-resource-limits.yaml`

A Kyverno `ClusterPolicy` (enforce mode) that:
- Validates that all containers have `resources.limits.memory` and `resources.limits.cpu` set
- Validates that all containers have `resources.requests.memory` and `resources.requests.cpu` set
- Excludes init containers from CPU limits (common pattern — add a comment explaining why)
- Excludes `kube-system` namespace
- Has a message referencing the resource values in `cd/kubernetes/_base/deployment.yaml` as a starting point

### 3. `policy/kyverno/require-labels.yaml`

A Kyverno `ClusterPolicy` (enforce mode) that:
- Validates that all Deployments have the labels: `app`, `version` (or `app.kubernetes.io/version`)
- Validates that all Namespaces have the label: `environment` (values: dev, staging, production)
- Validates that all Services have the label: `app`
- Has a message explaining that labels are required for Prometheus ServiceMonitor selectors and Grafana filtering
- Is in `audit` mode (not enforce) — add a comment explaining: "Start in audit mode to identify existing violations before enforcing"

### 4. `policy/kyverno/require-readonly-filesystem.yaml`

A Kyverno `ClusterPolicy` (warn mode) that:
- Validates that containers have `securityContext.readOnlyRootFilesystem: true`
- Uses `warn` mode (not enforce) with a clear comment explaining that some applications need write access (e.g. to `/tmp`) and teams should migrate progressively
- Provides the exception pattern in the message: `volumeMounts` for `/tmp` using `emptyDir`
- References `cd/kubernetes/_base/deployment.yaml` which already uses this pattern correctly

### 5. `policy/kyverno/disallow-latest-tag.yaml`

A Kyverno `ClusterPolicy` (enforce mode in production, audit in dev) that:
- Validates that no container image uses the `:latest` tag or has no tag at all
- Uses namespace label selector: `environment: production` — add a comment explaining that dev/staging may use mutable tags during active development
- Has a message explaining why `latest` breaks rollback (can't pin to a known good version)

### 6. `policy/kyverno/require-liveness-readiness.yaml`

A Kyverno `ClusterPolicy` (audit mode) that:
- Validates that all Deployments with more than 1 replica have both `livenessProbe` and `readinessProbe` defined
- Is in audit mode — add a comment: "Audit only — enforcing would break many legacy workloads. Review violations in the Kyverno policy report."
- Has a message with example probe configuration matching `cd/kubernetes/_base/deployment.yaml`

### 7. `policy/kyverno/README.md`

A guide covering:
- Installation: `helm install kyverno kyverno/kyverno -n kyverno --create-namespace`
- How to view policy violations: `kubectl get policyreport -A`
- How to check why a resource was blocked: `kubectl describe clusterpolicy <name>`
- How to add an exception for a specific workload (using `namespace` or `name` exclusions)
- How to graduate a policy from `audit` to `enforce` mode
- A table listing all policies, their mode, and what they check

### 8. `policy/README.md`

A top-level overview explaining:
- The difference between Kyverno (Kubernetes admission control) and Conftest (static analysis in CI)
- When each runs in the development lifecycle
- Links to the Kyverno and Conftest subdirectories

## Style rules

- Every policy must have `annotations` with `policies.kyverno.io/title`, `policies.kyverno.io/description`, and `policies.kyverno.io/severity`
- Every policy must have a comment at the top referencing the specific file in this repo that demonstrates the standard being enforced
- Use `ClusterPolicy` (not namespaced `Policy`) so rules apply uniformly
- Validation failure messages must be actionable — tell the developer exactly what to add, not just what is wrong
- Audit-mode policies must explain in a comment how to monitor violations: `kubectl get policyreport`