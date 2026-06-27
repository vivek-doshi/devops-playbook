# FinOps

This folder contains cost-governance controls and optimization tooling for cloud-native workloads.

## Purpose

Use `finops/` to make cloud spend observable, actionable, and integrated into engineering workflows.

## What's Inside

- `cicd/`: Infracost pipeline templates.
- `prometheus/`: budget and anomaly alerts.
- `policies/`: admission controls for labels and resource governance.
- `dashboards/`: cost visibility dashboards.
- `scripts/`: rightsizing, normalization, reporting, and recommendation tooling.
- `docs/`: operational guidance and runbooks.

## Use This Component Alone

- Run cost analysis and identify optimization opportunities.
- Deploy budget alerts and dashboards for one cluster.

## Use This Component With Others

- With `ci/` and `terraform/`: evaluate infrastructure cost in pull requests.
- With `policy/`: enforce mandatory cost labels and resource constraints.
- With `observability/` and `notifications/`: trigger alerts and operational response.
- With `catalog/`: map cost to service ownership and cost centers.

## Optimization Loop

1. Detect budget drift or anomalies.
2. Analyze rightsizing and commitment opportunities.
3. Generate implementation change proposals.
4. Deploy changes safely.
5. Verify savings in dashboards within 48 hours.
