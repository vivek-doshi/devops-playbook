# FinOps Documentation

This directory contains comprehensive documentation for deploying, configuring, and operating the FinOps system.

## Contents

This directory will include:

### Getting Started
- **installation.md** - Step-by-step installation instructions for all FinOps components
- **kubecost-vs-opencost.md** - Feature comparison to guide cost monitoring tool selection
- **cloud-provider-setup.md** - IAM role/service principal setup for AWS, Azure, GCP

### Configuration
- **cost-tagging-schema.md** - Required cost allocation labels and enforcement mechanisms
- **infracost-integration.md** - Integrate Infracost into CI/CD pipelines
- **finops-workflow.md** - When to perform FinOps reviews in the development lifecycle

### Runbooks
- **runbooks/investigate-cost-spike.md** - Step-by-step troubleshooting for cost anomalies
- **runbooks/onboard-new-team.md** - Process for adding new teams to the FinOps system

### Reference
- **troubleshooting.md** - Common FinOps component failures and solutions
- **prometheus-api-examples.md** - Example queries for cost metrics via Prometheus API
- **reserved-capacity-recommendations.md** - Reserved instance and savings plan options for AWS, Azure, GCP

## Architecture

The FinOps system consists of five primary layers:

1. **Cost Collection Layer**: Kubecost/OpenCost collects resource usage metrics and integrates with cloud provider billing APIs
2. **Policy Enforcement Layer**: Kyverno validates cost-related policies at admission time
3. **Optimization Layer**: VPA generates rightsizing recommendations with cost impact analysis
4. **Alerting Layer**: Prometheus Alertmanager triggers notifications for budget thresholds and anomalies
5. **Reporting Layer**: Scripts generate chargeback/showback reports and export to external systems

## Support

For issues, questions, or contributions, refer to the main project documentation.
