---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Generate a complete FinOps optimization loop implementation: a VPA-recommendation-to-PR workflow, reserved capacity planning automation, cross-cloud cost normalization, an optimization decision runbook, and a golden path guide — closing the open loop between cost data and concrete action.'
---

# FinOps Optimization Loop Implementation Generator

You are a senior FinOps engineer with experience designing cloud cost optimization workflows at Google scale. Your task is to close the open loop in this repository's FinOps layer — connecting the existing cost data, alerts, and recommendations to concrete, actionable change workflows.

## Mandatory context reads (do these before writing any file)

Read every file listed. Your output must extend, not replace, what exists.

- `finops/README.md` — understand the full FinOps architecture; your additions must integrate cleanly
- `finops/scripts/analyze-rightsizing.py` — existing VPA analysis script; your optimization workflow starts here
- `finops/scripts/detect-underutilized.py` — existing underutilization detection; feeds into the optimization loop
- `finops/scripts/detect-unused-volumes.py` — existing unused volume detection; part of the optimization scope
- `finops/scripts/generate-cost-report.py` — mirror this script's structure for new scripts
- `finops/scripts/analyze-reserved-capacity.py` — existing reserved capacity analysis; your automation extends this
- `finops/config/budgets.yaml` — understand the cost center structure; your optimization targets map here
- `finops/prometheus/budget-alerts.yaml` — existing budget alerts; your optimization alerts extend this
- `finops/prometheus/anomaly-alerts.yaml` — existing anomaly alerts; understand the alert format
- `finops/docs/cost-tagging-schema.md` — tagging schema; optimization recommendations must include tag context
- `finops/docs/reserved-capacity-recommendations.md` — existing reserved capacity docs; your automation implements this
- `finops/docs/installation.md` — understand the Kubecost/OpenCost setup; your scripts query these APIs
- `finops/helm/vpa-values.yaml` — VPA is already configured; your workflow reads VPA recommendations
- `finops/policies/enforce-resource-limits.yaml` — resource limits are enforced; optimization recommendations must respect these
- `finops/templates/pr-checklist.md` — PR checklist exists; your optimization PR template extends this
- `cd/kubernetes/_base/deployment.yaml` — understand the deployment resource spec; optimization PRs modify this
- `ci/github-actions/terraform/cost-estimation.yml` — existing Infracost CI; your reserved capacity estimation extends this
- `docs/golden-paths/kubernetes-microservice.md` — FinOps checkpoints in Steps 13-15; your golden path is the detailed version
- `.ai/instructions/engineering-principles.md` — apply all principles
- `.ai/context/terminology.md` — use canonical terms

## What you are building

The existing FinOps layer collects data (Kubecost, VPA, rightsizing scripts) and fires alerts (budget, anomaly) but the loop between "recommendation received" and "change implemented" is open. Teams get alerts and reports but have no guided workflow for what to do next.

You are building the closed loop:

1. **Optimization decision workflow** — a runbook that takes a cost recommendation and produces a PR
2. **VPA-to-PR automation** — a script that reads VPA recommendations and generates a Kustomize patch PR
3. **Reserved capacity planning** — automation that connects the existing analysis script to cloud provider APIs
4. **Cross-cloud cost normalization** — a script that produces comparable cost metrics across AWS, Azure, and GCP
5. **Optimization golden path** — end-to-end guide from "I got a cost alert" to "PR merged, savings realized"

## Your deliverables

### 1. `finops/scripts/generate-optimization-pr.py`

A Python script that reads VPA recommendations and rightsizing analysis output, then generates a Kustomize patch file and a pre-filled PR description that teams can use to submit the resource optimization change.

**Inputs**:
- `--namespace <namespace>`: the namespace to generate recommendations for
- `--min-savings <percent>`: only generate patches for resources with >= this % savings (default: 20)
- `--dry-run`: print what would be generated without writing files
- `--output-dir <path>`: where to write the patch files (default: `./optimization-patches`)

**How it works**:

1. Query VPA recommendations via `kubectl get vpa -n <namespace> -o json`
2. Query Kubecost/OpenCost API for current cost per workload (read URL from `finops/docs/installation.md` pattern, flag-configurable with `# <-- CHANGE THIS`)
3. For each workload where VPA recommends lower resources AND savings >= threshold:
   - Generate a Kustomize strategic merge patch updating `resources.requests` and `resources.limits`
   - Calculate expected monthly savings (current - recommended) × unit_cost
   - Write patch to `optimization-patches/<namespace>/<deployment-name>-resources.yaml`
4. Generate a `optimization-patches/PR-DESCRIPTION.md` with:
   - Summary table of all changes and expected savings
   - Per-workload diff showing current vs recommended resources
   - Link to the VPA recommendation evidence
   - The FinOps PR checklist from `finops/templates/pr-checklist.md`
   - Instructions for applying: `kubectl apply -k optimization-patches/<namespace>/`

**Output example** (include this as a comment in the script showing what the generated patch looks like):

```yaml
# Generated by finops/scripts/generate-optimization-pr.py
# VPA recommendation for api-gateway in namespace production
# Expected savings: $47.20/month (32% reduction)
# Evidence: kubectl get vpa api-gateway -n production -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: production
spec:
  template:
    spec:
      containers:
        - name: api-gateway
          resources:
            requests:
              cpu: "250m"     # was: 500m (VPA p95 recommendation)
              memory: "256Mi" # was: 512Mi (VPA p95 recommendation)
            limits:
              cpu: "500m"     # was: 1000m (2× requests, same ratio)
              memory: "512Mi" # was: 1024Mi (2× requests, same ratio)
```

**Safety rules** (enforce these in the script, not just document them):
- Never recommend below the VPA's lower bound — add a check and skip if VPA lower bound > recommendation
- Never set limits below requests — add a check
- Never reduce memory limits by more than 50% in a single change — flag as a warning and require `--allow-aggressive` flag
- If the workload has a PodDisruptionBudget with `minAvailable: 1` and `replicas: 1`, warn: "reducing resources on a single-replica workload with strict PDB may cause OOM kills during rollout"

Mirror the code structure of `finops/scripts/analyze-rightsizing.py` — same argparse pattern, same output formatting.

### 2. `finops/scripts/normalize-cloud-costs.py`

A Python script that queries cost data from AWS Cost Explorer, Azure Cost Management, and GCP Billing Export (or their Kubecost equivalents) and produces a normalized, comparable cost report in a single format.

**The cross-cloud normalization problem**: AWS charges for CPU and memory separately; Azure charges by VM SKU; GCP charges by machine type. Direct comparison is impossible without normalization. This script implements the following normalization model:

```
normalized_unit = (vCPU_hours × $0.048) + (GiB_hours × $0.006)
```

This is the on-demand blended rate across cloud providers for general-purpose compute. Add a comment explaining: "This is an approximation for comparison purposes, not billing. Use your actual cloud bills for financial reporting."

**Inputs** (flag-based, with `# <-- CHANGE THIS` on every API endpoint):
- `--aws` (optional): query AWS Cost Explorer API
- `--azure` (optional): query Azure Cost Management API  
- `--gcp` (optional): query GCP Billing BigQuery export
- `--kubecost <url>` (optional): query Kubecost API (covers all clouds if Kubecost is deployed multi-cluster)
- `--period <days>` (default: 30): look-back period
- `--output <json|csv|markdown>` (default: markdown)
- `--by <service|team|environment|namespace>`: grouping dimension

**Output format** (markdown):

```markdown
# Cross-Cloud Cost Report
Period: 2026-04-01 to 2026-05-01

## By Team

| Team | AWS | Azure | GCP | Total | MoM Change |
|---|---|---|---|---|---|
| platform | $1,240 | $380 | $0 | $1,620 | +12% |
| payments | $820 | $0 | $640 | $1,460 | -8% |

## Optimization Opportunities

| Workload | Cloud | Current | Recommended | Savings |
|---|---|---|---|---|
| api-gateway | AWS/EKS | $340/mo | $228/mo | $112/mo |

## Reserved Capacity Opportunities

| Resource | Cloud | Current spend | Committed rate | Annual savings |
|---|---|---|---|---|
| us-east-1 r6i.large | AWS | $180/mo | $108/mo (1yr) | $864/yr |
```

Mirror the output style of `finops/scripts/generate-cost-report.py`.

### 3. `finops/scripts/reserved-capacity-advisor.py`

A Python script that extends the existing `finops/scripts/analyze-reserved-capacity.py` to connect recommendations to actual cloud provider commitment APIs and generate a committed spend proposal.

**What the existing script does**: analyzes current usage patterns and identifies candidates for reserved capacity. Reads the existing analysis output.

**What this new script adds**:

1. **Fetches current pricing** from cloud provider pricing APIs (or static pricing tables with `# <-- UPDATE QUARTERLY` comment):
   - AWS: EC2 Reserved Instance pricing via `aws pricing get-products`
   - Azure: Reserved VM Instances pricing via Azure Retail Prices API
   - GCP: Committed Use Discount pricing via GCP SKU API

2. **Calculates break-even point**: how many months until the commitment pays off vs on-demand

3. **Generates a commitment proposal** in markdown, covering:
   - Recommended commitments (1-year vs 3-year comparison)
   - Break-even month for each commitment
   - Risk assessment (is the workload stable enough to commit?)
   - Total annual savings if all recommendations are adopted

4. **Risk scoring** for each commitment candidate:
   - `low`: workload has been running for >6 months with <10% resource variance → safe to commit
   - `medium`: workload is 3-6 months old or has 10-30% resource variance → commit with caution
   - `high`: workload is <3 months old or has >30% variance → do not commit yet

**Flags**:
- `--min-savings <annual_usd>` (default: 500): only show recommendations with >= this annual savings
- `--max-risk <low|medium|high>` (default: medium): filter by risk score
- `--term <1yr|3yr>` (default: 1yr): commitment term to optimize for
- `--output-proposal <path>`: write the commitment proposal to a file for leadership review

Add a comment at the top: "Run this quarterly, after reviewing 3 months of stable usage data. Do not run immediately after a major architecture change — usage patterns need time to stabilize."

### 4. `finops/docs/optimization-runbook.md`

An operational runbook for responding to FinOps alerts and implementing cost optimizations. This is the decision guide that closes the loop.

**Trigger conditions** — when to use this runbook:
- A budget alert fires (`ComplianceScoreWarning`, `BudgetThreshold80`, `BudgetThreshold100` from `finops/prometheus/budget-alerts.yaml`)
- A cost anomaly fires (`CostAnomalyDetected` from `finops/prometheus/anomaly-alerts.yaml`)
- The monthly cost report shows MoM increase > 15%
- VPA has recommendations that have been open for > 30 days

**Decision tree** (ASCII format matching `docs/ARCHITECTURE_DECISION_GUIDE.md`):

```
FinOps alert fires
│
├── Budget alert (BudgetThreshold80 or BudgetThreshold100)?
│   ├── New workload deployed this month?
│   │   ├── YES → Check if workload is over-provisioned → Section 2: Resource Rightsizing
│   │   └── NO → Investigate cost anomaly → Section 3: Anomaly Investigation
│   └── Reserved capacity opportunity identified?
│       └── YES → Section 4: Reserved Capacity Commitment
│
├── Cost anomaly (CostAnomalyDetected)?
│   ├── New namespace or workload?
│   │   └── YES → Check for missing cost labels → Section 1: Label Compliance
│   └── Existing workload spiked?
│       └── YES → Check for runaway HPA scaling → Section 3: Anomaly Investigation
│
└── Monthly report shows MoM increase?
    └── YES → Run normalize-cloud-costs.py → identify largest movers → Section 2 or 4
```

**Section 1: Label Compliance**

Commands to identify unlabeled resources:
```bash
python finops/scripts/validate-cost-tags.py --all-namespaces --output json | jq '.violations[]'
```
Fix: add labels to the Deployment manifest, re-deploy, verify in Kubecost within 1 hour.

**Section 2: Resource Rightsizing**

Step-by-step:
1. Identify candidates: `python finops/scripts/analyze-rightsizing.py --namespace <ns> --min-savings 20`
2. Verify VPA has enough data (requires 24h minimum): `kubectl get vpa -n <ns>`
3. Generate the optimization PR: `python finops/scripts/generate-optimization-pr.py --namespace <ns>`
4. Review the generated patch — confirm no safety warnings
5. Test in staging first: `kubectl apply -k optimization-patches/<ns>/` against staging namespace
6. Monitor for 24h: check for OOMKilled pods, latency increase, error rate change
7. If staging is stable, open the PR with the generated `PR-DESCRIPTION.md`

**Section 3: Anomaly Investigation**

1. Identify which cost center spiked: `python finops/scripts/normalize-cloud-costs.py --by team --period 7`
2. Identify which workload: query Kubecost/OpenCost dashboard (link to `finops/docs/runbooks/investigate-cost-spike.md`)
3. Check HPA scaling history: `kubectl get events -n <ns> --field-selector reason=SuccessfulRescale`
4. Check for runaway jobs: `kubectl get jobs -A --sort-by=.metadata.creationTimestamp`
5. If a runaway job: `kubectl delete job <name> -n <ns>` and investigate the root cause

**Section 4: Reserved Capacity Commitment**

1. Run the advisor: `python finops/scripts/reserved-capacity-advisor.py --min-savings 500 --max-risk medium`
2. Review the proposal — confirm the workload has been stable for >= 3 months
3. Get leadership approval for commitments > $10,000/year (add `# <-- CHANGE THIS` threshold)
4. Execute via the cloud console or Terraform (link to the cloud-specific Terraform modules)
5. Update `finops/config/budgets.yaml` to reflect the new committed rate for that cost center

### 5. `finops/dashboards/optimization-opportunities.json`

Update the existing dashboard (which already exists per the README) to add the following panels that are missing from the current implementation:

**New panels to add** (describe the panel configuration in detail — Copilot will generate the JSON):

- **VPA Recommendation Age** (table panel): list of workloads with VPA recommendations older than 7 days that haven't been acted on. Columns: workload, namespace, recommendation age, estimated monthly savings, link to generate PR command.
- **Optimization Savings Realized** (stat panel): total monthly savings from optimization changes in the current month. Calculated as: sum of resource reductions × unit_cost, tracked via a custom metric that the `generate-optimization-pr.py` script writes to a ConfigMap after each PR merge.
- **Reserved vs On-Demand Spend** (pie chart): breakdown of current spend by commitment type. Requires `finops.io/commitment-type` label on cloud resources (add `# <-- CHANGE THIS: apply this label via your Terraform modules`).
- **Cross-Cloud Cost Comparison** (bar chart): normalized cost per team per cloud, using the output of `normalize-cloud-costs.py`. Data sourced from the ConfigMap that the normalization script writes to.

### 6. `finops/docs/finops-workflow.md`

Update the existing workflow documentation to include the optimization loop. Add a new section:

**The Optimization Loop**:

```
Data collection (Kubecost, VPA, billing APIs)
        ↓
Analysis (analyze-rightsizing.py, reserved-capacity-advisor.py)
        ↓
Alert or report fires
        ↓
Engineer follows optimization-runbook.md
        ↓
generate-optimization-pr.py creates the change
        ↓
PR reviewed and merged
        ↓
Cost reduction realized within 24-48 hours
        ↓
Cost report confirms savings → loop closes
```

Add a "time to value" table showing how long each optimization type takes from identification to savings:

| Optimization type | Time to identify | Time to implement | Time to realize savings |
|---|---|---|---|
| Resource rightsizing | Immediate (VPA running) | 1-2 days (PR review) | 24-48 hours after merge |
| Unused volumes | Daily (detect-unused-volumes.py) | 1 hour | Immediate after deletion |
| Reserved capacity | Quarterly (advisor script) | 1 week (approval + commitment) | Next billing cycle |
| Cross-cloud migration | Monthly (normalize-cloud-costs.py) | Weeks-months | Next billing cycle |

### 7. `docs/golden-paths/finops-optimization.md`

A complete golden path in the exact format of `docs/golden-paths/kubernetes-microservice.md`.

**When to use this path**: any team that has received a FinOps alert, seen a budget dashboard, or wants to proactively reduce their cloud spend. Assumes the FinOps stack (Kubecost/OpenCost, VPA, Prometheus budget alerts) is already installed.

**Not the right path**: reference `finops/README.md` for installing the FinOps stack from scratch. This path assumes it is running.

**Flow**:
```
receive alert or review monthly report
→ identify optimization type (rightsizing | reserved | anomaly | label compliance)
→ run analysis script → review recommendations
→ generate optimization PR (for rightsizing) or commitment proposal (for reserved)
→ test in staging → merge to production
→ verify savings in dashboard → close the loop
```

**Steps** (numbered, with exact file references):

1. Identify the trigger: which alert fired, or what does the monthly report show? (link to `finops/docs/optimization-runbook.md`)
2. Run cross-cloud cost normalization to understand the full picture: `python finops/scripts/normalize-cloud-costs.py --by team`
3. Run rightsizing analysis for the affected namespace: `python finops/scripts/analyze-rightsizing.py --namespace <ns>`
4. Generate the optimization PR if VPA recommendations are available: `python finops/scripts/generate-optimization-pr.py --namespace <ns>`
5. Run the reserved capacity advisor quarterly: `python finops/scripts/reserved-capacity-advisor.py`
6. Test resource changes in staging for 24h before applying to production
7. Apply the optimization: merge the PR, the changes take effect within one rollout cycle
8. Verify savings: check the optimization dashboard in Grafana within 48 hours
9. Update the budget if the savings materially change the cost center forecast: `finops/config/budgets.yaml`

**FinOps alert response guide** (add as a dedicated section):

| Alert | Immediate action | Script to run | Expected resolution time |
|---|---|---|---|
| `BudgetThreshold80` | Identify top spender | `normalize-cloud-costs.py --by team` | 1-3 days |
| `BudgetThreshold100` | Stop non-critical deployments | `normalize-cloud-costs.py --by team` | Same day |
| `CostAnomalyDetected` | Check for runaway workloads | `detect-underutilized.py` | Hours |
| VPA recommendation > 7 days old | Generate optimization PR | `generate-optimization-pr.py` | 1-2 days |
| Unused volumes detected | Review and delete | `detect-unused-volumes.py` | 1 hour |

**Guardrails table**:

| Rule | Enforced by |
|---|---|
| Never reduce memory limits > 50% in one change | `generate-optimization-pr.py` safety check |
| Never commit reserved capacity for workloads < 3 months old | `reserved-capacity-advisor.py` risk scoring |
| Test resource changes in staging for 24h before production | Step 6 in this path |
| Reserved capacity commitments > $10,000/year require leadership approval | `optimization-runbook.md` Section 4 |
| All optimization PRs must include the FinOps PR checklist | `finops/templates/pr-checklist.md` in PR template |

### 8. Update `GETTING_STARTED.md`

Add under "💰 FinOps — Cloud Cost Governance":

| I got a cost alert — what do I do? | [`finops/docs/optimization-runbook.md`](finops/docs/optimization-runbook.md) |
| Optimize resource requests based on VPA recommendations | [`docs/golden-paths/finops-optimization.md`](docs/golden-paths/finops-optimization.md) |
| Compare costs across AWS, Azure, and GCP | [`finops/scripts/normalize-cloud-costs.py`](finops/scripts/normalize-cloud-costs.py) |

### 9. Update `finops/README.md`

Add a new section **"The Optimization Loop"** after the existing architecture diagram, describing the closed-loop workflow and linking to:
- `finops/docs/optimization-runbook.md` — the decision guide
- `finops/scripts/generate-optimization-pr.py` — the automation
- `finops/scripts/normalize-cloud-costs.py` — cross-cloud analysis
- `finops/scripts/reserved-capacity-advisor.py` — commitment planning
- `docs/golden-paths/finops-optimization.md` — the end-to-end path

## Style rules

- `generate-optimization-pr.py` must output a complete, copy-pasteable PR description — no placeholders in the generated content, only `# <-- CHANGE THIS` in the script's configuration section
- The optimization runbook must use the same ASCII decision tree format as `docs/ARCHITECTURE_DECISION_GUIDE.md`
- All scripts must mirror the structure of `finops/scripts/generate-cost-report.py`: argparse, main function, modular helpers, consistent output formatting
- Safety rules in `generate-optimization-pr.py` must be enforced in code (raise exceptions, skip candidates) not just documented in comments
- The `normalize-cloud-costs.py` script must work with Kubecost as the primary data source and cloud APIs as optional enrichment — not the reverse. Most users will have Kubecost before they have direct API access configured.
- The reserved capacity advisor must include explicit risk scoring — recommending a 3-year commitment for a 2-month-old workload is a common and expensive mistake
- Every `# <-- CHANGE THIS` must specify: what to change, what valid values look like, and where to find the correct value
- The golden path must reference the specific scripts (with their flags) not just "run the analysis" — vague guidance does not close loops
- Add `# <-- UPDATE QUARTERLY` on any pricing data embedded in the scripts
