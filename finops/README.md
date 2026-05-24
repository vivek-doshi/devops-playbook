# FinOps - Cost Governance and Optimization

> Enterprise-grade cloud cost management, visibility, and governance for multi-cloud Kubernetes environments.

---

## Quick Links

- Workflow and operating model: [`finops/docs/finops-workflow.md`](docs/finops-workflow.md)
- Optimization decision runbook: [`finops/docs/optimization-runbook.md`](docs/optimization-runbook.md)
- End-to-end implementation path: [`docs/golden-paths/finops-optimization.md`](../docs/golden-paths/finops-optimization.md)
- Budget and cost-center source of truth: [`finops/config/budgets.yaml`](config/budgets.yaml)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CI/CD Pipeline                                   │
│  GitHub Actions / Azure Pipelines / GitLab CI                            │
│  ┌─────────────────┐                                                       │
│  │   Infracost     │  ← Shows cost impact of Terraform changes in PRs    │
│  └─────────────────┘                                                       │
└─────────────────────────────────────┬───────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────┐
│                         Kubernetes Cluster                                │
│                                                                           │
│  ┌─────────────────────────┐    ┌──────────────────────────────────┐     │
│  │  finops namespace        │    │  Policy Layer                    │     │
│  │  ┌──────────────────┐   │    │  ┌────────────────────────────┐  │     │
│  │  │ Kubecost/OpenCost│◄──┼────┤  │ Kyverno ClusterPolicies    │  │     │
│  │  │ (cost monitoring)│   │    │  │  • require-cost-labels     │  │     │
│  │  └──────────────────┘   │    │  │  • enforce-resource-limits │  │     │
│  │  ┌──────────────────┐   │    │  │  • gpu-approval-gate       │  │     │
│  │  │ VPA Recommender  │   │    │  │  • require-pdb-large-wkld  │  │     │
│  │  └──────────────────┘   │    │  └────────────────────────────┘  │     │
│  │  ┌──────────────────┐   │    └──────────────────────────────────┘     │
│  │  │ CronJob: Reports │   │                                              │
│  │  └──────────────────┘   │    ┌──────────────────────────────────┐     │
│  └─────────────────────────┘    │  Application Namespaces           │     │
│                                  │  (labeled with finops.org/*)      │     │
│  Cloud Provider APIs             └──────────────────────────────────┘     │
│  AWS CUR / Azure Cost Mgmt / GCP Billing Export                           │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────┐
│                     Visualization & Alerting                              │
│  ┌──────────────────────────────────┐  ┌──────────────────────────────┐  │
│  │ Grafana Dashboards                │  │ Alertmanager → Slack/PagerDuty│ │
│  │  • Cost Overview                  │  │  • Budget threshold alerts    │  │
│  │  • Cost Breakdown                 │  │  • Cost anomaly alerts        │  │
│  │  • Rightsizing Opportunities      │  │  • Tag compliance alerts      │  │
│  │  • Budget Tracking                │  └──────────────────────────────┘  │
│  │  • Anomaly Detection              │                                     │
│  │  • Tag Compliance                 │  ┌──────────────────────────────┐  │
│  │  • Multi-Cloud Comparison         │  │ Cost Reports (S3/Blob/GCS)   │  │
│  │  • Optimization Opportunities     │  │  • Monthly CSV/JSON          │  │
│  └──────────────────────────────────┘  │  • Chargeback/Showback        │  │
│                                         └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## The Optimization Loop

The FinOps layer now supports a closed loop from recommendation to merged change and verified savings:

1. Detect spend change in alerts or reports
2. Analyze rightsizing and reserved-capacity opportunities
3. Generate implementation artifacts (patches/PR text/proposals)
4. Validate in staging and merge to production
5. Confirm realized savings in dashboards and monthly report

Use these assets end-to-end:

- Decision guide: [`finops/docs/optimization-runbook.md`](docs/optimization-runbook.md)
- Rightsizing automation: [`finops/scripts/generate-optimization-pr.py`](scripts/generate-optimization-pr.py)
- Cross-cloud normalization: [`finops/scripts/normalize-cloud-costs.py`](scripts/normalize-cloud-costs.py)
- Commitment planning: [`finops/scripts/reserved-capacity-advisor.py`](scripts/reserved-capacity-advisor.py)
- End-to-end path: [`docs/golden-paths/finops-optimization.md`](../docs/golden-paths/finops-optimization.md)

---

## Components

| Component | Purpose | Location |
|-----------|---------|----------|
| **Kubecost / OpenCost** | Real-time cost monitoring per namespace/workload | `helm/` |
| **VPA** | Resource rightsizing recommendations | `helm/vpa-values.yaml` |
| **Kyverno Policies** | Cost governance at admission time | `policies/` |
| **Infracost** | Infrastructure cost estimation in CI/CD | `cicd/`, `infracost/` |
| **Budget Alerts** | Prometheus alerting at 80/100/120% thresholds | `prometheus/` |
| **Anomaly Detection** | Alert on unexpected cost spikes | `prometheus/` |
| **Cost Reports** | Monthly chargeback/showback in CSV+JSON | `scripts/`, `kubernetes/` |
| **Grafana Dashboards** | 9 dashboards for cost visibility | `dashboards/` |

---

## Quick Start

```bash
# 1. Deploy cost monitoring
./finops/scripts/install-cost-monitoring.sh --tool kubecost

# 2. Deploy Kyverno policies (audit mode first)
./finops/scripts/deploy-policies.sh --audit-mode

# 3. Deploy Grafana dashboards
GRAFANA_API_KEY=xxx ./finops/scripts/deploy-dashboards.sh

# 4. Check tag compliance
python finops/scripts/validate-cost-tags.py --all-namespaces

# 5. Find rightsizing opportunities
python finops/scripts/analyze-rightsizing.py --all-namespaces

# 6. Generate optimization patch and PR summary from recommendations
python finops/scripts/generate-optimization-pr.py --all-namespaces

# 7. Compare normalized cost across providers
python finops/scripts/normalize-cloud-costs.py --group-by namespace

# 8. Generate reserved-capacity recommendations with risk scoring
python finops/scripts/reserved-capacity-advisor.py --lookback-days 30
```

Full installation: [`docs/installation.md`](docs/installation.md)

---

## Directory Structure

```
finops/
├── helm/                    # Helm values files
│   ├── kubecost-values.yaml
│   ├── opencost-values.yaml
│   └── vpa-values.yaml
├── policies/                # Kyverno ClusterPolicies
│   ├── require-cost-labels.yaml
│   ├── enforce-resource-limits.yaml
│   ├── gpu-approval-gate.yaml
│   └── require-pdb-large-workloads.yaml
├── prometheus/              # Prometheus alerting rules
│   ├── budget-alerts.yaml
│   ├── anomaly-alerts.yaml
│   ├── tag-compliance-alerts.yaml
│   └── alertmanager-budget-config.yaml
├── dashboards/              # Grafana dashboard JSON
│   ├── cost-overview.json
│   ├── cost-breakdown.json
│   ├── rightsizing-opportunities.json
│   ├── budget-tracking.json
│   ├── anomaly-detection.json
│   ├── tag-compliance.json
│   ├── multi-cloud-comparison.json
│   └── optimization-opportunities.json
├── scripts/                 # Automation scripts
│   ├── install-cost-monitoring.sh
│   ├── deploy-dashboards.sh
│   ├── deploy-policies.sh
│   ├── deploy-budget-alerts.sh
│   ├── analyze-rightsizing.py
│   ├── generate-cost-report.py
│   ├── export-cost-report.sh
│   ├── validate-cost-tags.py
│   ├── detect-underutilized.py
│   ├── detect-unused-volumes.py
│   ├── analyze-reserved-capacity.py
│   ├── generate-optimization-pr.py
│   ├── normalize-cloud-costs.py
│   └── reserved-capacity-advisor.py
├── config/                  # Configuration files
│   └── budgets.yaml
├── cicd/                    # CI/CD pipeline templates
│   ├── github-actions-infracost.yml
│   ├── azure-pipelines-infracost.yml
│   └── gitlab-ci-infracost.yml
├── infracost/               # Infracost config
│   └── .infracost.yml
├── kubernetes/              # Kubernetes manifests
│   └── cost-report-cronjob.yaml
├── templates/               # Templates for teams
│   └── pr-checklist.md
└── docs/                    # Documentation
    ├── installation.md
    ├── cloud-provider-setup.md
    ├── cost-tagging-schema.md
    ├── finops-workflow.md
    ├── infracost-integration.md
    ├── kubecost-vs-opencost.md
    ├── reserved-capacity-recommendations.md
    ├── troubleshooting.md
    └── runbooks/
        ├── investigate-cost-spike.md
        └── onboard-new-team.md
```

---

## Key Concepts

- **Cost Center**: Business unit identifier for chargeback (`finops.org/costcenter` label)
- **Showback**: Display costs to teams without billing them
- **Chargeback**: Allocate actual costs to teams for internal billing
- **Rightsizing**: Adjusting resource requests to match actual usage
- **Budget Alert**: Notification when spending exceeds configured threshold

---

## Documentation

| Document | Audience |
|----------|----------|
| [Installation Guide](docs/installation.md) | Platform team |
| [Cloud Provider Setup](docs/cloud-provider-setup.md) | Platform team |
| [Cost Tagging Schema](docs/cost-tagging-schema.md) | All teams |
| [FinOps Workflow Guide](docs/finops-workflow.md) | All teams |
| [Infracost Integration](docs/infracost-integration.md) | Developer, Platform team |
| [Kubecost vs OpenCost](docs/kubecost-vs-opencost.md) | Platform team |
| [Troubleshooting](docs/troubleshooting.md) | Platform team |
| [Investigate Cost Spike](docs/runbooks/investigate-cost-spike.md) | Platform team, FinOps |
| [Onboard New Team](docs/runbooks/onboard-new-team.md) | Platform team, FinOps |
