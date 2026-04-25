# RBAC

This directory provides least-privilege Kubernetes RBAC patterns for the three most common principal types: developers, CI/CD pipelines, and namespace-owning teams.

## Design Principles

1. **Default deny**: New principals get no permissions. Access is granted explicitly.
2. **Least privilege**: Each role grants only the verbs and resources required for the job.
3. **Namespace scope first**: Prefer `Role` + `RoleBinding` (namespace-scoped) over `ClusterRole` + `ClusterRoleBinding` unless cluster-wide access is genuinely needed.
4. **Groups over users**: Bind to OIDC/SSO groups so onboarding/offboarding is controlled in your IdP, not in Kubernetes YAML.
5. **Audit regularly**: Run `kubectl auth can-i --list --as=<user>` periodically to verify permissions haven't drifted.

## File Reference

| File | Type | Scope | Use case |
|------|------|-------|----------|
| `readonly-developer.yaml` | ClusterRole + ClusterRoleBinding | Cluster-wide | On-call triage, read-only inspection |
| `ci-deployer.yaml` | ServiceAccount + Role + RoleBinding | Namespace | GitHub Actions / GitLab CI pipeline |
| `namespace-admin.yaml` | Role + RoleBinding | Namespace | Team owns a namespace end-to-end |

## Quick Apply

```bash
# Apply all RBAC resources (adjust namespace fields in each file first)
kubectl apply -k cd/kubernetes/_base/rbac/

# Or apply individually
kubectl apply -f cd/kubernetes/_base/rbac/readonly-developer.yaml
kubectl apply -f cd/kubernetes/_base/rbac/ci-deployer.yaml -n production
kubectl apply -f cd/kubernetes/_base/rbac/namespace-admin.yaml -n payments
```

## Verify Permissions

```bash
# What can the ci-deployer service account do in the production namespace?
kubectl auth can-i --list \
  --as=system:serviceaccount:production:ci-deployer \
  -n production

# Can the developers group list pods in the kube-system namespace?
kubectl auth can-i list pods \
  --as-group=developers \
  -n kube-system
# Expected: no

# Can a developer get a deployment in the default namespace?
kubectl auth can-i get deployments \
  --as-group=developers \
  -n default
# Expected: yes
```

## OIDC / SSO Integration

Group names in `subjects[].name` must match the group claims in your OIDC token.

| Provider | Token claim | Example value |
|----------|------------|---------------|
| GitHub (OIDC via Dex) | `groups` | `org:payments-team` |
| Azure AD | `groups` | Object ID or group name (depends on claim config) |
| Google Workspace | `groups` | `payments-team@example.com` |
| Okta | `groups` | `payments-team` |

Configure the API server `--oidc-groups-claim` flag to the claim name your provider uses.

## Common Audit Commands

```bash
# List all ClusterRoleBindings and their subjects
kubectl get clusterrolebindings -o wide

# Find all RoleBindings in a namespace
kubectl get rolebindings -n production -o wide

# Find who has cluster-admin
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.roleRef.name=="cluster-admin") | .subjects'

# Check effective permissions for a user
kubectl auth can-i --list --as=jane@example.com
```

## Related Files

- [`cd/kubernetes/_base/network-policies/`](../network-policies/) — restrict pod-to-pod traffic
- [`secrets/external-secrets/`](../../../secrets/external-secrets/) — secrets access via ESO (no RBAC to Secrets needed)
- [`cd/kubernetes/_overlays/`](../../_overlays/) — overlay patches to adjust namespace in RBAC resources per environment
