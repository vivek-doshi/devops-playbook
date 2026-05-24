# Golden Path — Service Catalog Registration

This path standardizes how teams register services, validate ownership metadata, and enforce admission guardrails in Kubernetes.

## Outcomes

- Every deployed service has an owner, on-call route, runbook, and cost center.
- CI validates metadata integrity and deployment mapping before merge.
- Kyverno requires catalog registration for deployments.

## Prerequisites

- Team file exists in `catalog/teams/`.
- Service SLO definition file exists in `observability/prometheus/slos/`.
- Cost center exists in `finops/config/budgets.yaml`.

## Step 1: Register Team

1. Copy `catalog/teams/schema/team.yaml` to `catalog/teams/<team-name>.yaml`.
2. Set team lead, members, on-call schedule, and ownership paths.
3. Validate team yaml formatting with your standard YAML linter.

## Step 2: Register Service

1. Copy `catalog/schema/service.yaml` to `catalog/services/<service-name>.yaml`.
2. Ensure `metadata.name` matches deployment app label and file name.
3. Set `metadata.owner` to a team from `catalog/teams/`.
4. Set `spec.slo.definition_file` to an existing SLO file.
5. Set `spec.cost_center` to a value from `finops/config/budgets.yaml`.

## Step 3: Validate Locally

```bash
python catalog/scripts/validate-catalog.py --strict --skip-url-check
```

Validate one service only:

```bash
python catalog/scripts/validate-catalog.py --service api-gateway --strict --skip-url-check
```

## Step 4: Generate CODEOWNERS

```bash
python catalog/scripts/generate-codeowners.py --output .github/CODEOWNERS
```

This keeps ownership rules in sync with team metadata.

## Step 5: CI Gate

PRs that modify `catalog/` trigger `.github/workflows/validate-catalog.yml`. Merges are blocked if catalog validation fails.

## Step 6: Admission Guardrail

Apply policy:

```bash
kubectl apply -f policy/kyverno/require-catalog-registration.yaml
```

- Audit mode checks all namespaces.
- Enforce mode applies to namespaces labeled `environment=production`.

## Step 7: Optional Backstage Migration

When service count approaches 50, export Backstage components:

```bash
python catalog/scripts/migrate-to-backstage.py --output-dir backstage/catalog
```

Review generated component annotations and owner mappings before importing into Backstage.
