---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Generate a lightweight service catalog implementation: a standardized service.yaml schema, a validation pipeline, Kyverno label enforcement integration, an ownership CLI tool, a Backstage migration path, and a golden path guide — designed to work without a separate deployment or database, using Git as the source of truth.'
---

# Service Catalog Implementation Generator

You are a senior platform engineer with experience designing internal developer platforms at scale. Your task is to generate a lightweight service catalog for this repository — one that works without Backstage, without a database, and without a separate deployment, while providing a clear migration path to Backstage when the organization is ready.

## Mandatory context reads (do these before writing any file)

- `policy/kyverno/require-labels.yaml` — existing label enforcement; your catalog validation extends this
- `policy/kyverno/README.md` — understand how Kyverno policies are documented
- `cd/kubernetes/_base/deployment.yaml` — understand the label structure teams already use
- `cd/kubernetes/_base/rbac/` — understand how team ownership maps to RBAC
- `docs/golden-paths/platform-onboarding.md` — Step 5 creates namespaces; your catalog registers them
- `docs/golden-paths/kubernetes-microservice.md` — Step 8 creates manifests; your catalog schema is a companion file
- `docs/golden-paths/incident-response.md` — Phase 1.3 assigns roles; your catalog provides the ownership data
- `docs/runbooks/template.md` — your catalog links to runbooks; understand the runbook structure
- `observability/prometheus/alerts/deployment-alerts.yaml` — alerts include `team` label; catalog validates this
- `notifications/pagerduty-notify.yml` — PagerDuty routing uses team labels; catalog is the source of truth
- `notifications/slack-notify.yml` — Slack routing uses team labels; same
- `finops/config/budgets.yaml` — FinOps cost centers map to teams; catalog cross-references these
- `finops/docs/cost-tagging-schema.md` — cost labels must align with catalog ownership fields
- `secops/compliance/control-library/soc2-controls.yaml` — CC1.2 (ownership) and CC2.1 (asset inventory) are satisfied by the catalog
- `.ai/instructions/engineering-principles.md` — apply all principles
- `.ai/context/terminology.md` — use canonical terms

## Design principles for this implementation

**Git-native**: The catalog is a directory of YAML files in Git. No database, no API server, no separate deployment. Every catalog entry is a pull request.

**Validation in CI**: A GitHub Actions workflow validates every `catalog/services/*.yaml` file on PR. Invalid entries fail the PR check.

**Kyverno enforcement**: The catalog's required labels are enforced at admission time by Kyverno. A service that doesn't have a catalog entry can't deploy to production (enforced by the label requirement).

**Backstage-compatible**: The schema is intentionally designed to be importable into Backstage when the organization grows to the point where a portal is needed. Provide a migration guide, not a parallel system.

**Flat by default**: A startup with 5 services uses a flat `catalog/services/` directory. A company with 200 services uses team subdirectories. The schema supports both without changes.

## Your deliverables

### 1. `catalog/README.md`

The top-level entry point for the catalog directory.

**What this directory is**: One YAML file per service, registered here when a team creates a new service. The catalog is the authoritative source for: who owns this service, who is on call, where the runbook lives, what the SLO target is, and which FinOps cost center it belongs to.

**Why Git, not a portal**: Explain the reasoning. Portals (Backstage, ServiceNow, Confluence) diverge from reality because updating them requires a separate action. When the catalog lives in the same repo as the deployment manifests, updating the service ownership is the same PR as updating the deployment. They cannot diverge.

**How to find a service**: `grep -r "name: <service-name>" catalog/services/`

**How to find all services owned by a team**: `grep -r "owner: <team-name>" catalog/services/`

**How to find who is on call for a namespace**: `cat catalog/services/<service>.yaml | grep oncall`

**Migration path to Backstage**: One paragraph. When the organization reaches ~50 services, the catalog YAML format is designed to be imported directly into Backstage's Software Catalog using the `catalog-import` feature. The `service.yaml` schema maps directly to Backstage's `catalog-info.yaml` format with a one-time migration script (included at `catalog/scripts/migrate-to-backstage.py`).

**Compliance**: Explain that SOC 2 CC1.2 (entity defines responsibilities) and CC2.1 (asset inventory) are satisfied by the catalog. Link to `secops/compliance/control-library/soc2-controls.yaml`.

### 2. `catalog/schema/service.yaml`

The canonical schema file. Teams copy this and fill it in. Every field must have a comment explaining its purpose, valid values, and why it is required.

```yaml
# Service Catalog Entry
# =====================
# Copy this file to catalog/services/<your-service-name>.yaml
# Fill in all required fields before your first production deployment.
# This file is validated automatically on every PR.
#
# REQUIRED: This file must exist before deploying to production.
# Kyverno policy policy/kyverno/require-catalog-registration.yaml enforces this.
#
# MATURITY: Stable

apiVersion: catalog/v1
kind: Service
metadata:
  # Unique identifier for the service. Must match:
  # - The `app` label on your Kubernetes Deployment
  # - The `job` label in your Prometheus metrics
  # - The directory name: catalog/services/<name>.yaml
  # Use kebab-case. Once set, do not change — it is referenced by alerts and dashboards.
  name: my-service                          # <-- CHANGE THIS

  # The team that owns this service. Must match:
  # - The `team` label on your Kubernetes Deployment (enforced by Kyverno)
  # - The team entry in catalog/teams/<team-name>.yaml
  # - The routing key in notifications/pagerduty-notify.yml
  owner: platform-team                      # <-- CHANGE THIS

  # Human-readable display name. Used in dashboards and alerts.
  display_name: "My Service"                # <-- CHANGE THIS

  # Short description of what this service does. One sentence.
  description: "Handles X for Y users."    # <-- CHANGE THIS

  # Service lifecycle stage. Controls which Kyverno policies apply.
  # alpha: development only, no production traffic
  # beta: production traffic, relaxed SLO requirements
  # stable: full production, all guardrails enforced
  # deprecated: receiving no new features, scheduled for decommission
  lifecycle: stable                         # <-- CHANGE THIS: alpha | beta | stable | deprecated

spec:
  # ── Ownership ───────────────────────────────────────────────────────────────

  # Primary contact email or distribution list.
  # This is who gets notified for non-urgent issues.
  contact: platform-team@example.com        # <-- CHANGE THIS

  # On-call rotation. This is who gets paged for SLO violations.
  # Use the PagerDuty schedule name, not an individual's name.
  # Find your schedule in PagerDuty under "Schedules".
  oncall:
    pagerduty_service: PXXXXXX             # <-- CHANGE THIS: PagerDuty service key
    slack_channel: "#platform-alerts"      # <-- CHANGE THIS: Slack channel for non-critical alerts

  # ── Runtime ─────────────────────────────────────────────────────────────────

  # Kubernetes namespaces where this service runs.
  # List all environments.
  namespaces:
    - production/my-service                # <-- CHANGE THIS: format is <namespace>/<deployment-name>
    - staging/my-service
    - dev/my-service

  # Container registry path (without tag).
  # Used by catalog tooling to find image vulnerability reports.
  image: ghcr.io/your-org/my-service       # <-- CHANGE THIS

  # External dependencies. List services and infrastructure this service calls.
  # Used for dependency mapping and incident blast radius analysis.
  dependencies:
    - type: service
      name: auth-service                   # <-- CHANGE THIS or remove
    - type: database
      name: postgres-prod                  # <-- CHANGE THIS or remove
      cloud: aws
      region: us-east-1
    - type: external-api
      name: stripe
      url: https://api.stripe.com          # <-- CHANGE THIS or remove

  # ── Reliability ─────────────────────────────────────────────────────────────

  # SLO definition file for this service.
  # Must exist if lifecycle is stable or beta.
  slo:
    availability_target: 99.9              # percentage
    latency_target_ms: 500                 # p99 latency in milliseconds
    definition_file: observability/prometheus/slos/my-service-slo.yaml  # <-- CHANGE THIS

  # ── Documentation ───────────────────────────────────────────────────────────

  # Primary runbook. Must exist before lifecycle: stable.
  runbook_url: https://github.com/your-org/repo/blob/main/docs/runbooks/my-service.md  # <-- CHANGE THIS

  # Architecture documentation (optional but recommended).
  docs_url: https://confluence.example.com/my-service  # <-- CHANGE THIS or remove

  # ── Cost Governance ─────────────────────────────────────────────────────────

  # FinOps cost center. Must match an entry in finops/config/budgets.yaml.
  # This is the cost center charged for this service's cloud spend.
  cost_center: engineering                 # <-- CHANGE THIS

  # FinOps environment label. Must match the environment label on Kubernetes resources.
  environment: production                  # <-- CHANGE THIS: dev | staging | production

  # ── Compliance ──────────────────────────────────────────────────────────────

  # Data classification. Determines which security controls apply.
  # public: no user data
  # internal: employee data only
  # confidential: customer data
  # restricted: PII, financial, health data — requires additional controls
  data_classification: confidential        # <-- CHANGE THIS: public | internal | confidential | restricted

  # Compliance frameworks this service must satisfy.
  # Drives which controls are checked in the compliance-as-code pipeline.
  compliance_frameworks:
    - SOC2                                 # <-- CHANGE THIS or remove
    - ISO27001                             # remove if not applicable
```

### 3. `catalog/services/example-api-gateway.yaml`

A complete, filled-in example catalog entry for a hypothetical `api-gateway` service. This is the concrete reference teams copy. Use realistic but fictional values. Every `# <-- CHANGE THIS` field must be filled in with a plausible value.

### 4. `catalog/teams/README.md`

Documentation for the `catalog/teams/` directory. Teams are registered here. A team entry must exist before a service can reference it as `owner`.

### 5. `catalog/teams/schema/team.yaml`

The team schema:

```yaml
apiVersion: catalog/v1
kind: Team
metadata:
  name: platform-team                      # <-- CHANGE THIS: kebab-case team identifier
  display_name: "Platform Engineering"     # <-- CHANGE THIS

spec:
  # Team lead — single point of contact for the team
  lead: jane.smith@example.com             # <-- CHANGE THIS

  # All team members (used for CODEOWNERS and access reviews)
  members:
    - alice@example.com                    # <-- CHANGE THIS
    - bob@example.com

  # Slack channel for non-urgent contact
  slack_channel: "#platform-eng"          # <-- CHANGE THIS

  # PagerDuty on-call schedule for this team
  pagerduty_schedule: SXXXXXX             # <-- CHANGE THIS

  # FinOps: which cost centers this team is responsible for
  cost_centers:
    - engineering
    - infrastructure

  # CODEOWNERS paths this team owns
  # These are used to auto-populate .github/CODEOWNERS
  owns:
    - cd/kubernetes/_base/
    - observability/
    - policy/kyverno/
```

### 6. `catalog/scripts/validate-catalog.py`

A Python validation script that runs in CI to validate every catalog entry.

**What it validates**:

1. **Schema validation**: every required field is present and has the correct type
2. **Reference integrity**: `owner` references a team in `catalog/teams/`, `slo.definition_file` exists, `runbook_url` returns HTTP 200 (optional, flag-gated)
3. **Label consistency**: the `name` in the catalog entry matches what will be applied as the `app` label on the Deployment (cross-reference `cd/kubernetes/_base/deployment.yaml`)
4. **FinOps alignment**: `cost_center` exists in `finops/config/budgets.yaml`
5. **Compliance completeness**: if `lifecycle: stable` and `data_classification: confidential`, then `compliance_frameworks` must include at least `SOC2`
6. **Runbook existence**: if `lifecycle: stable`, runbook_url must be set

**Output format**:

```
Validating catalog/services/api-gateway.yaml... ✓
Validating catalog/services/auth-service.yaml... ✗
  ERROR: owner 'unknown-team' not found in catalog/teams/
  ERROR: slo.definition_file not found: observability/prometheus/slos/auth-service-slo.yaml
  WARNING: runbook_url returns 404

Summary: 1 passed, 1 failed, 1 warning
Exit code: 1 (failures present)
```

**Flags**:
- `--strict`: treat warnings as errors (use in production CI)
- `--skip-url-check`: skip HTTP checks (use in offline environments)
- `--service <name>`: validate only one service entry

Mirror the structure of `finops/scripts/validate-cost-tags.py` — same argparse pattern, same output style.

### 7. `.github/workflows/validate-catalog.yml`

A GitHub Actions workflow that runs `validate-catalog.py` on every PR that touches `catalog/`.

```yaml
name: Validate service catalog
on:
  pull_request:
    paths:
      - 'catalog/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install pyyaml requests
      - name: Validate catalog entries
        run: python catalog/scripts/validate-catalog.py --strict
```

Add a comment: "This workflow runs on every PR touching catalog/. It is the only automated gate — Kyverno enforce-mode is the runtime gate. Both must pass before a service reaches production."

### 8. `policy/kyverno/require-catalog-registration.yaml`

A new Kyverno `ClusterPolicy` that requires a Deployment's `app` label to correspond to a registered service in the catalog.

**Implementation approach**: The Kyverno policy checks that the Deployment has an annotation `catalog.io/registered: "true"`. This annotation is applied by the CI pipeline (`validate-catalog.py` step) when it confirms the service is in the catalog. The policy does not directly query the Git repository — it checks the annotation.

**Mode**: Audit for all environments, Enforce for namespaces labeled `environment: production`.

Add a comment explaining the two-step pattern: "The catalog validation script sets the annotation; Kyverno enforces the annotation is present. This separates the validation logic (Python, flexible) from the enforcement mechanism (Kyverno, fast)."

Add this policy to the cross-reference in `secops/compliance/control-library/control-to-policy-map.yaml` with mappings to SOC2 CC1.2 and CC2.1.

### 9. `catalog/scripts/generate-codeowners.py`

A script that generates `.github/CODEOWNERS` from the team catalog entries.

**What it does**: reads every `catalog/teams/*.yaml` file, extracts the `owns` paths, and writes a `CODEOWNERS` file with the correct format.

**Output format**:
```
# Auto-generated from catalog/teams/ — do not edit manually
# Run: python catalog/scripts/generate-codeowners.py > .github/CODEOWNERS

cd/kubernetes/_base/    @your-org/platform-team
observability/          @your-org/platform-team
policy/kyverno/         @your-org/platform-team
```

Add a comment at the top of the generated file: "Regenerate with: `python catalog/scripts/generate-codeowners.py`. Run this after any team membership or ownership change."

### 10. `catalog/scripts/migrate-to-backstage.py`

A migration script that converts `catalog/services/*.yaml` files to Backstage `catalog-info.yaml` format.

**What it generates** for each service:

```yaml
# Backstage catalog-info.yaml format
# Generated from catalog/services/<name>.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  description: "Handles X for Y users."
  annotations:
    github.com/project-slug: your-org/your-repo
    pagerduty.com/service-id: PXXXXXX
    backstage.io/techdocs-ref: dir:.
  tags:
    - production
spec:
  type: service
  lifecycle: production
  owner: platform-team
  dependsOn:
    - component:auth-service
    - resource:postgres-prod
```

Add a comment at the top of the script: "Run this when you're ready to migrate to Backstage. Prerequisites: Backstage running with the Software Catalog plugin, GitHub integration configured. See: https://backstage.io/docs/features/software-catalog/software-catalog-overview"

### 11. `docs/golden-paths/service-catalog.md`

A complete golden path in the exact format of `docs/golden-paths/kubernetes-microservice.md`.

**When to use this path**: any team creating a new service, or any team that wants to register an existing service in the catalog to establish official ownership, on-call routing, and compliance evidence.

**Not the right path**: reference `platform-onboarding.md` for setting up the team's platform foundations. This path assumes the platform is already set up and focuses on registering a single service.

**Flow**:
```
copy schema → fill in service.yaml → validate locally
→ open PR → CI validation passes → merge
→ Kyverno annotation applied → deploy service
→ ownership visible in catalog → on-call routing active
```

**Steps** (numbered, with exact file references):

1. Create a team entry if your team is not registered: copy `catalog/teams/schema/team.yaml`, save as `catalog/teams/<team-name>.yaml`
2. Create your service entry: copy `catalog/schema/service.yaml`, save as `catalog/services/<service-name>.yaml`
3. Validate locally: `python catalog/scripts/validate-catalog.py --service <name>`
4. Open a PR: CI runs `validate-catalog.py --strict` automatically
5. After merge: add the catalog annotation to your Deployment: `catalog.io/registered: "true"`
6. Verify Kyverno compliance: `kubectl get policyreport -n <namespace>`
7. Verify alert routing: check that PagerDuty and Slack receive a test alert routed to your team
8. Update CODEOWNERS: `python catalog/scripts/generate-codeowners.py > .github/CODEOWNERS`

**Ownership discovery section** — how to find information when you're on-call and don't know the service:

```bash
# Who owns the service in namespace 'payments'?
grep -r "namespace: production/payments" catalog/services/

# What are all services owned by 'payments-team'?
grep -r "owner: payments-team" catalog/services/

# What does this service depend on?
cat catalog/services/payments-api.yaml | grep -A 10 dependencies

# Where is the runbook?
cat catalog/services/payments-api.yaml | grep runbook_url
```

**Backstage migration section**: explain the migration path at 50+ services. Link to `catalog/scripts/migrate-to-backstage.py`. Note that the schema is intentionally compatible — migration is a one-time script run, not a redesign.

**Guardrails table**:

| Rule | Enforced by |
|---|---|
| Every production service must have a catalog entry | `policy/kyverno/require-catalog-registration.yaml` (Enforce in production) |
| `owner` must reference a registered team | `validate-catalog.py --strict` in CI |
| SLO definition file must exist if lifecycle is stable | `validate-catalog.py --strict` in CI |
| Runbook must be set if lifecycle is stable | `validate-catalog.py --strict` in CI |
| FinOps cost_center must exist in budgets.yaml | `validate-catalog.py --strict` in CI |
| CODEOWNERS must be regenerated after team changes | `generate-codeowners.py` + code review |

### 12. Update `docs/golden-paths/incident-response.md`

In Phase 1.3 (Assign roles), add:

"Find the service owner: `cat catalog/services/<service-name>.yaml | grep owner`. Find the on-call schedule: `cat catalog/services/<service-name>.yaml | grep pagerduty_service`. If the service is not in the catalog, the platform team is the default escalation path."

### 13. Update `policy/kyverno/require-labels.yaml`

Add a comment referencing the catalog: "The `team` label value must match a team name registered in `catalog/teams/`. Validate with: `python catalog/scripts/validate-catalog.py`."

Do not change the policy content — only add the comment.

### 14. Update `GETTING_STARTED.md`

Add a new section: **"📋 I need to register my service"**:

| Register a new service in the catalog | [`docs/golden-paths/service-catalog.md`](docs/golden-paths/service-catalog.md) |
| Find who owns a service | [`catalog/services/`](catalog/services/) |
| Update team membership or ownership | [`catalog/teams/`](catalog/teams/) |

## Style rules

- The schema file must have a comment on every field — no undocumented fields
- The validation script must print actionable error messages — "ERROR: owner 'unknown-team' not found in catalog/teams/" not "validation failed"
- The Kyverno policy uses the annotation-based pattern (not direct Git queries) — add a comment explaining why (Kyverno cannot query Git; the annotation is the bridge between CI validation and runtime enforcement)
- The CODEOWNERS generation script must include a "do not edit manually" header and explain how to regenerate
- The Backstage migration script must be runnable without modification for a standard Backstage setup — mark any Backstage-specific configuration with `# <-- CHANGE THIS`
- The golden path must include the "ownership discovery" section — this is the highest-value feature for on-call engineers
- `lifecycle: stable` must trigger stricter validation than `lifecycle: alpha` — the schema and validation script must enforce this tiered approach
- All catalog YAML files must pass `python3 -c "import yaml; yaml.safe_load(open('file.yaml'))"` — valid YAML is non-negotiable
