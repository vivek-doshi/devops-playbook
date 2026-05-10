# Grafana Dashboards

This directory contains Grafana dashboard definitions in JSON format for visualizing cost data, trends, and optimization opportunities.

## Contents

This directory will include:

### Core Dashboards
- **cost-overview.json** - Total cluster cost, cost by namespace/team, 7/30/90-day trends
- **cost-breakdown.json** - Compute vs storage vs network costs, cost by workload type
- **budget-tracking.json** - Current spend vs budget by cost center, forecast to month-end

### Optimization Dashboards
- **rightsizing-opportunities.json** - Top 10 VPA recommendations ranked by potential savings
- **optimization-opportunities.json** - Top 20 cost optimization opportunities (underutilized workloads, unused volumes)
- **reserved-capacity.json** - Reserved capacity utilization and coverage, stable workload candidates

### Monitoring Dashboards
- **anomaly-detection.json** - Cost spikes, new high-cost namespaces, unusual patterns
- **tag-compliance.json** - Percentage of pods with required cost labels, compliance trends
- **multi-cloud-comparison.json** - Cost comparison across AWS, Azure, GCP in normalized USD

## Deployment

Dashboards can be deployed using the `../scripts/deploy-dashboards.sh` script, which imports all JSON files to Grafana via the Grafana API.

## Data Source

All dashboards use Prometheus as the data source for cost metrics. Ensure Prometheus is configured to scrape cost metrics from Kubecost/OpenCost before deploying dashboards.

## Customization

Dashboard JSON files can be customized to match your organization's requirements:
- Modify time ranges and refresh intervals
- Add custom panels and queries
- Adjust thresholds and alert indicators
- Configure variables for filtering by namespace, cost center, or environment

## Performance

Dashboards are optimized for query performance:
- Queries return results within 5 seconds for 90-day periods
- Dashboards load within 3 seconds
- Efficient use of Prometheus query aggregations and caching
