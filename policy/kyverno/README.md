# Kyverno Policies

Kyverno is a Kubernetes-native policy engine. Policies run as an admission webhook —
every `kubectl apply` (or Helm install, ArgoCD sync, etc.) passes through Kyverno before
the resource is persisted. No external policy language is needed; policies are plain YAML.

---

## Installation

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version 3.1.4         # pin to a tested version; check releases before upgrading
```

Wait for the webhook to become ready before applying policies:

```bash
kubectl rollout status deployment kyverno-admission-controller -n kyverno
```

Apply all policies in this directory:

```bash
kubectl apply -f policy/kyverno/
```

---

## Policy Reference

| File | Mode | Severity | Checks |
|------|------|----------|--------|
| [require-non-root.yaml](require-non-root.yaml) | **Enforce** | High | `runAsNonRoot: true` on pod; `allowPrivilegeEscalation: false` on containers |
| [require-resource-limits.yaml](require-resource-limits.yaml) | **Enforce** | Medium | CPU + memory requests and limits on all containers; memory limits on init containers |
| [require-labels.yaml](require-labels.yaml) | **Audit** | Low | `app` + `version` on Deployments; `environment` on Namespaces; `app` on Services |
| [require-readonly-filesystem.yaml](require-readonly-filesystem.yaml) | **Warn** | Medium | `readOnlyRootFilesystem: true` on containers |
| [disallow-latest-tag.yaml](disallow-latest-tag.yaml) | **Enforce** (prod) / **Audit** (other) | High | No `:latest` or untagged images |
| [require-liveness-readiness.yaml](require-liveness-readiness.yaml) | **Audit** | Medium | `livenessProbe` + `readinessProbe` on Deployments with > 1 replica |

---

## Viewing Policy Violations

### PolicyReports (audit and warn mode)

Kyverno writes results to `PolicyReport` (namespaced) and `ClusterPolicyReport` (cluster-scoped)
resources. Check across all namespaces:

```bash
# Summary of all policy reports
kubectl get policyreport -A

# Detailed results for a specific namespace
kubectl describe policyreport -n <namespace>

# Filter for failures only
kubectl get policyreport -A -o json \
  | jq '.items[].results[] | select(.result == "fail")'
```

### Why was a resource blocked?

When `validationFailureAction: Enforce`, Kyverno returns an error to the API server that
surfaces in `kubectl apply` output. To inspect the rule that blocked it:

```bash
kubectl describe clusterpolicy require-non-root
```

Look at the `Status.Conditions` and `Status.Ready` fields to confirm the policy is active,
and the `spec.rules[].validate.message` field for the exact message the developer would see.

---

## Adding an Exception for a Specific Workload

Exceptions can be added directly in the policy's `exclude` block, or as a standalone
`PolicyException` resource (Kyverno 1.9+, preferred — keeps policy files clean).

### Option A: Namespace exclusion (in the policy file)

```yaml
exclude:
  any:
    - resources:
        namespaces:
          - legacy-namespace
```

### Option B: Resource name exclusion (in the policy file)

```yaml
exclude:
  any:
    - resources:
        kinds: [Pod]
        names:
          - my-privileged-job-*   # supports wildcards
        namespaces:
          - batch
```

### Option C: PolicyException resource (preferred for one-off workloads)

```yaml
apiVersion: kyverno.io/v2beta1
kind: PolicyException
metadata:
  name: allow-legacy-root-container
  namespace: legacy-namespace
spec:
  exceptions:
    - policyName: require-non-root
      ruleNames:
        - check-pod-run-as-non-root
  match:
    any:
      - resources:
          kinds: [Pod]
          namespaces: [legacy-namespace]
          names: [legacy-worker-*]
```

Apply it: `kubectl apply -f policy-exception.yaml`

PolicyExceptions require the `policyExceptions.enabled: true` Helm value. Confirm:

```bash
helm get values kyverno -n kyverno | grep policyExceptions
```

---

## Graduating a Policy from Audit to Enforce

1. **Check the current violation count:**
   ```bash
   kubectl get policyreport -A -o json \
     | jq '[.items[].results[] | select(.policy == "require-labels" and .result == "fail")] | length'
   ```

2. **Remediate all violations** — patch the offending resources to add the missing fields.

3. **Confirm zero failures** by re-running the query above.

4. **Update the policy** — change `validationFailureAction: Audit` to `Enforce`:
   ```bash
   kubectl patch clusterpolicy require-labels \
     --type merge \
     -p '{"spec":{"validationFailureAction":"Enforce"}}'
   ```
   Or edit the YAML file and re-apply: `kubectl apply -f policy/kyverno/require-labels.yaml`

5. **Test** by attempting to apply a non-compliant resource:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: test-no-labels
     namespace: default
   spec:
     selector:
       matchLabels:
         run: test
     template:
       metadata:
         labels:
           run: test
       spec:
         containers:
           - name: test
             image: nginx:1.25
   EOF
   ```
   Expect: `Error from server: admission webhook "validate.kyverno.svc" denied the request`

---

## Useful Commands

```bash
# Watch Kyverno admission controller logs in real time
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller -f

# List all ClusterPolicies and their ready state
kubectl get clusterpolicy

# Check background scan results (Kyverno re-evaluates existing resources periodically)
kubectl get backgroundscanreport -A
```
