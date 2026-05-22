# FinOps Scripts

This directory contains automation scripts for deploying, configuring, and operating the FinOps system.

## Contents

This directory will include:

### Deployment Scripts
- **install-cost-monitoring.sh** - Deploy Kubecost or OpenCost to the cluster
  - Creates `finops` namespace if not exists
  - Deploys selected tool using Helm with appropriate values file
  - Validates deployment success and prints access URL
  - Usage: `./install-cost-monitoring.sh --tool <kubecost|opencost>`
- **deploy-dashboards.sh** - Import Grafana dashboards
- **deploy-policies.sh** - Apply Kyverno cost governance policies
- **deploy-budget-alerts.sh** - Configure budget alerting rules
- **deploy-anomaly-alerts.sh** - Configure cost anomaly detection

### Analysis Scripts
- **analyze-rightsizing.py** - Generate VPA recommendations with cost impact analysis
- **detect-underutilized.py** - Identify underutilized workloads for optimization
- **detect-unused-volumes.py** - Identify unused persistent volumes
- **analyze-reserved-capacity.py** - Recommend reserved instances and savings plans

### Reporting Scripts
- **generate-cost-report.py** - Generate monthly chargeback/showback reports
- **export-cost-report.sh** - Export cost reports to S3/Blob/GCS
- **send-to-billing-api.py** - Integrate with enterprise billing systems

### Validation Scripts
- **validate-cost-tags.py** - Scan for missing cost allocation labels
- **export-metrics.py** - Export cost metrics in Prometheus format

## Requirements

- Python 3.8+ with dependencies: `requests`, `pyyaml`, `kubernetes`, `prometheus-client`
- kubectl configured with cluster access
- Helm 3.x for deployment scripts
- Appropriate cloud provider credentials for cost data access

## Usage

Each script includes inline documentation and help text. Run scripts with `--help` flag for usage information.
