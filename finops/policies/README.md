# Kyverno Cost Governance Policies

This directory contains Kyverno ClusterPolicy resources that enforce cost-related governance rules and prevent expensive misconfigurations.

## Contents

This directory will include:

### Cost Label Policies
- **require-cost-labels.yaml** - Validates presence of `finops.org/costcenter` and `finops.org/environment` labels on all Pods

### Resource Governance Policies
- **enforce-resource-limits.yaml** - Blocks Pods exceeding namespace budget-based resource limits
- **gpu-approval-gate.yaml** - Requires explicit approval annotation for GPU workloads
- **require-pdb-large-workloads.yaml** - Requires PodDisruptionBudget for workloads >4 CPU or >8Gi memory

## Policy Modes

Kyverno policies can operate in two modes:

- **Validation Mode (Blocking)**: Rejects resources that violate policies - recommended for production
- **Audit Mode (Non-blocking)**: Logs violations without blocking - recommended for testing

Use the `deploy-policies.sh` script with `--audit-mode` flag to test policies before enforcing them.

## Error Messages

All policies include descriptive error messages with:
- Policy name and violated rule
- Reason for violation
- Remediation steps with examples

## Testing

Policy validation tests are included in `test-policies.sh` using the Kyverno CLI test framework.

## Required Labels

All Pods must include the following labels for cost allocation:

```yaml
metadata:
  labels:
    finops.org/costcenter: "engineering"  # Required: Cost center for chargeback
    finops.org/environment: "production"  # Required: Environment (dev/staging/production)
```

Refer to `../docs/cost-tagging-schema.md` for the complete tagging schema.
