# Implementation Plan: FinOps Feature

## Overview

This implementation plan breaks down the FinOps feature into discrete coding tasks. The feature integrates cost monitoring (Kubecost/OpenCost), resource optimization (VPA), policy governance (Kyverno), infrastructure cost estimation (Infracost), and chargeback/showback patterns into the CI/CD reference architecture. Tasks are organized to build incrementally, with early validation of core functionality and integration points.

## Tasks

- [x] 1. Set up FinOps directory structure and base configuration
  - Create `finops/` directory with subdirectories: `helm/`, `scripts/`, `policies/`, `dashboards/`, `docs/`
  - Create `.kiro/specs/finops/.config.kiro` with spec metadata
  - Create placeholder README files in each subdirectory
  - _Requirements: 11.1, 11.2_

- [x] 2. Implement Kubecost and OpenCost Helm configurations
  - [x] 2.1 Create Kubecost Helm values file
    - Create `finops/helm/kubecost-values.yaml` with Prometheus integration, namespace configuration, and cloud provider settings
    - Configure data retention period (90 days default)
    - Configure Ingress with TLS for web UI
    - _Requirements: 1.1, 1.2, 1.3, 1.5_
  
  - [x] 2.2 Create OpenCost Helm values file
    - Create `finops/helm/opencost-values.yaml` with Prometheus integration and multi-cloud support
    - Configure namespace and resource limits
    - Configure Ingress with TLS for web UI
    - _Requirements: 1.1, 1.2, 1.3, 1.5_
  
  - [x] 2.3 Create installation script for cost monitoring tools
    - Create `finops/scripts/install-cost-monitoring.sh` that accepts `--tool` parameter (kubecost or opencost)
    - Script creates `finops` namespace if not exists
    - Script deploys selected tool using Helm with appropriate values file
    - Script validates deployment success and prints access URL
    - _Requirements: 1.2, 1.5_
  
  - [x] 2.4 Create cloud provider configuration documentation
    - Create `finops/docs/cloud-provider-setup.md` with IAM role/service principal setup for AWS, Azure, GCP
    - Document required API permissions for each cloud provider
    - Include example IAM policies and service principal configurations
    - _Requirements: 1.6, 9.1, 9.2, 9.3, 9.6_

- [x] 3. Checkpoint - Verify cost monitoring deployment
  - Ensure cost monitoring tool deploys successfully, ask the user if questions arise.

- [ ] 4. Implement Grafana dashboards for cost visibility
  - [x] 4.1 Create Cost Overview dashboard
    - Create `finops/dashboards/cost-overview.json` with panels for total cluster cost, cost by namespace, cost by team, 7/30/90-day trends
    - Configure Prometheus data source queries for cost metrics
    - Add variables for namespace and cost center filtering
    - _Requirements: 2.4, 2.5_
  
  - [ ] 4.2 Create Cost Breakdown dashboard
    - [x] 4.2.1 Create base dashboard structure with compute vs storage vs network cost panels
    - [ ] 4.2.2 Add cost by workload type panels
    - [ ] 4.2.3 Add drill-down links to namespace-specific views
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [-] 4.3 Create Rightsizing Opportunities dashboard
    - Create `finops/dashboards/rightsizing-opportunities.json` with table panel showing top 10 optimization opportunities
    - Configure sorting by potential monthly savings
    - Add links to VPA recommendation details
    - _Requirements: 3.5, 3.6_
  
  - [-] 4.4 Create Budget Tracking dashboard
    - Create `finops/dashboards/budget-tracking.json` with panels for current spend vs budget by cost center, forecast to month-end
    - Add threshold indicators at 80%, 100%, 120%
    - Include alert status indicators
    - _Requirements: 4.6_
  
  - [-] 4.5 Create Anomaly Detection dashboard
    - Create `finops/dashboards/anomaly-detection.json` with panels for cost spikes, new high-cost namespaces, unusual patterns
    - Display anomalies over past 30 days with trend analysis
    - _Requirements: 10.5, 10.6_
  
  - [~] 4.6 Create Tag Compliance dashboard
    - Create `finops/dashboards/tag-compliance.json` with panels for percentage of pods with required cost labels, non-compliant resources
    - Display compliance trends over time
    - _Requirements: 14.5_
  
  - [~] 4.7 Create Multi-Cloud Comparison dashboard
    - Create `finops/dashboards/multi-cloud-comparison.json` with panels for cost comparison across AWS, Azure, GCP in normalized USD
    - Add cloud provider filtering and cost breakdown by service
    - _Requirements: 9.4, 9.5_
  
  - [~] 4.8 Create dashboard deployment script
    - Create `finops/scripts/deploy-dashboards.sh` that imports all dashboard JSON files to Grafana
    - Script uses Grafana API to create/update dashboards
    - Script validates dashboard import success
    - _Requirements: 2.4, 2.5_

- [ ] 5. Implement VPA integration and cost impact analysis
  - [~] 5.1 Create VPA deployment configuration
    - Create `finops/helm/vpa-values.yaml` for VPA Helm chart with recommender, updater, admission controller
    - Configure VPA in recommendation-only mode (no automatic updates)
    - _Requirements: 3.1_
  
  - [~] 5.2 Create cost impact analyzer script
    - Create `finops/scripts/analyze-rightsizing.py` that queries VPA API for recommendations
    - Script queries Kubecost/OpenCost API for pricing data
    - Script calculates cost difference: `(recommended_cpu - current_cpu) * cpu_hourly_rate + (recommended_memory - current_memory) * memory_hourly_rate`
    - Script generates JSON report with workload name, current cost, recommended cost, potential savings, savings percentage
    - Script highlights recommendations with >20% savings as high-priority
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_
  
  - [~] 5.3 Write unit tests for cost impact calculation
    - Create `finops/scripts/test_analyze_rightsizing.py` with pytest tests
    - Test cost difference calculation with various CPU/memory values
    - Test handling of missing pricing data
    - Test savings percentage calculation and priority classification
    - _Requirements: 3.2, 3.3, 3.4, 3.6_

- [ ] 6. Implement budget configuration and alerting
  - [~] 6.1 Create budget configuration schema and example
    - Create `finops/config/budgets.yaml` with schema for cost center, monthly threshold, alert channels
    - Add example budget configurations for 2-3 cost centers
    - _Requirements: 4.1_
  
  - [~] 6.2 Create Prometheus alerting rules for budget thresholds
    - Create `finops/prometheus/budget-alerts.yaml` with alerting rules for 80%, 100%, 120% thresholds
    - Configure alert labels for cost center, threshold, and severity
    - Add annotations with current spend, threshold, percentage over budget, Grafana dashboard link
    - _Requirements: 4.2, 4.3, 4.5, 4.6_
  
  - [~] 6.3 Create Alertmanager configuration for budget alerts
    - Create `finops/prometheus/alertmanager-budget-config.yaml` with routing rules for budget alerts
    - Configure Slack, Microsoft Teams, and PagerDuty integrations
    - Add templates for alert notifications with cost details
    - _Requirements: 4.4, 4.6_
  
  - [~] 6.4 Create budget alert deployment script
    - Create `finops/scripts/deploy-budget-alerts.sh` that applies Prometheus rules and Alertmanager config
    - Script validates budget configuration file syntax
    - Script reloads Prometheus and Alertmanager configurations
    - _Requirements: 4.1, 4.2_

- [~] 7. Checkpoint - Verify budget alerting
  - Ensure budget alerts deploy successfully and test with synthetic metrics, ask the user if questions arise.

- [ ] 8. Implement Kyverno cost governance policies
  - [~] 8.1 Create cost label validation policy
    - Create `finops/policies/require-cost-labels.yaml` ClusterPolicy that validates presence of `finops.org/costcenter` and `finops.org/environment` labels on all Pods
    - Configure validation mode (blocking) with descriptive error messages
    - Add remediation instructions in policy annotations
    - _Requirements: 5.1, 5.6_
  
  - [~] 8.2 Create resource limit enforcement policy
    - Create `finops/policies/enforce-resource-limits.yaml` ClusterPolicy that blocks Pods exceeding namespace budget-based resource limits
    - Configure per-namespace resource quotas based on budget configuration
    - Add error messages with current request, limit, and remediation steps
    - _Requirements: 5.2, 5.6_
  
  - [~] 8.3 Create GPU approval gate policy
    - Create `finops/policies/gpu-approval-gate.yaml` ClusterPolicy that requires explicit approval annotation for GPU workloads
    - Policy checks for `finops.org/gpu-approved: "true"` annotation
    - Add error message explaining approval process
    - _Requirements: 5.3, 5.6_
  
  - [~] 8.4 Create PDB requirement policy
    - Create `finops/policies/require-pdb-large-workloads.yaml` ClusterPolicy that requires PodDisruptionBudget for workloads >4 CPU or >8Gi memory
    - Policy validates PDB exists in same namespace with matching selector
    - Add error message with PDB creation instructions
    - _Requirements: 5.4, 5.6_
  
  - [~] 8.5 Create policy deployment script
    - Create `finops/scripts/deploy-policies.sh` that applies all Kyverno ClusterPolicy resources
    - Script validates policy syntax using Kyverno CLI
    - Script supports `--audit-mode` flag for testing policies without blocking
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  
  - [~] 8.6 Write policy validation tests
    - Create `finops/policies/test-policies.sh` using Kyverno CLI test framework
    - Test policy enforcement with valid and invalid Pod manifests
    - Verify error messages include remediation steps
    - _Requirements: 5.6_

- [ ] 9. Implement cost reporting and chargeback
  - [~] 9.1 Create cost report generation script
    - Create `finops/scripts/generate-cost-report.py` that queries Kubecost/OpenCost API for monthly cost data
    - Script aggregates costs by cost center across all namespaces
    - Script calculates shared cluster costs (control plane, monitoring, logging) and allocates proportionally by namespace resource usage
    - Script generates CSV and JSON output formats
    - Script includes columns: cost center, namespace, total cost, compute cost, storage cost, network cost, shared cost allocation
    - _Requirements: 6.1, 6.2, 6.3, 6.6_
  
  - [~] 9.2 Create cost report export script
    - Create `finops/scripts/export-cost-report.sh` that uploads cost reports to S3/Blob/GCS
    - Script accepts `--provider` parameter (aws, azure, gcp) and `--bucket` parameter
    - Script includes error handling for permission failures with runbook link
    - _Requirements: 13.2, 13.3, 13.4_
  
  - [~] 9.3 Create enterprise billing API integration example
    - Create `finops/scripts/send-to-billing-api.py` with example REST API integration code
    - Include authentication examples (OAuth, API key)
    - Add error handling and retry logic
    - _Requirements: 6.5_
  
  - [~] 9.4 Create cost report scheduling configuration
    - Create `finops/kubernetes/cost-report-cronjob.yaml` CronJob that runs monthly
    - Configure job to execute cost report generation and export scripts
    - Add resource limits and service account with appropriate RBAC
    - _Requirements: 6.1_
  
  - [~] 9.5 Write unit tests for cost report generation
    - Create `finops/scripts/test_generate_cost_report.py` with pytest tests
    - Test CSV/JSON formatting
    - Test shared cost allocation calculation
    - Test handling of namespaces without cost labels
    - Test date range filtering
    - _Requirements: 6.2, 6.3, 6.6_

- [ ] 10. Implement Infracost CI/CD integration
  - [ ] 10.1 Create Infracost configuration template
    - Create `finops/infracost/.infracost.yml` template with project path, cost thresholds (percentage and absolute)
    - Document configuration options and threshold recommendations
    - _Requirements: 7.5_
  
  - [~] 10.2 Create GitHub Actions workflow template
    - Create `finops/cicd/github-actions-infracost.yml` workflow that runs Infracost after `terraform plan`
    - Workflow posts cost estimate as PR comment
    - Workflow marks PR check as failed if cost increase exceeds threshold
    - _Requirements: 7.1, 7.4_
  
  - [~] 10.3 Create Azure Pipelines template
    - Create `finops/cicd/azure-pipelines-infracost.yml` pipeline that runs Infracost after `terraform plan`
    - Pipeline posts cost estimate as PR comment
    - Pipeline marks PR check as failed if cost increase exceeds threshold
    - _Requirements: 7.2, 7.4_
  
  - [~] 10.4 Create GitLab CI template
    - Create `finops/cicd/gitlab-ci-infracost.yml` job that runs Infracost after `terraform plan`
    - Job posts cost estimate as merge request comment
    - Job marks MR check as failed if cost increase exceeds threshold
    - _Requirements: 7.3, 7.4_
  
  - [~] 10.5 Create Infracost integration documentation
    - Create `finops/docs/infracost-integration.md` explaining how to integrate Infracost into existing plan-apply workflows
    - Document threshold configuration and PR check behavior
    - Include troubleshooting section for common issues
    - _Requirements: 7.6_

- [ ] 11. Implement cost anomaly detection
  - [~] 11.1 Create Prometheus alerting rules for cost anomalies
    - Create `finops/prometheus/anomaly-alerts.yaml` with rules for cost increases >50% compared to 7-day average
    - Add rule for new namespaces with costs >$100 within 24 hours
    - Configure alert labels for namespace, severity, and anomaly type
    - Add annotations with current cost, baseline cost, percentage increase, cost breakdown link
    - _Requirements: 10.1, 10.2, 10.3_
  
  - [~] 11.2 Create Alertmanager configuration for anomaly alerts
    - Create `finops/prometheus/alertmanager-anomaly-config.yaml` with routing rules for anomaly alerts
    - Configure Slack, Microsoft Teams, and PagerDuty integrations
    - Add templates for anomaly notifications with cost details
    - _Requirements: 10.4, 10.6_
  
  - [~] 11.3 Create anomaly alert deployment script
    - Create `finops/scripts/deploy-anomaly-alerts.sh` that applies Prometheus rules and Alertmanager config
    - Script validates alerting rule syntax
    - Script reloads Prometheus and Alertmanager configurations
    - _Requirements: 10.1, 10.2, 10.3_

- [ ] 12. Implement cost optimization recommendations
  - [~] 12.1 Create underutilized workload detection script
    - Create `finops/scripts/detect-underutilized.py` that queries Prometheus for CPU and memory utilization over 7 days
    - Script identifies workloads with CPU utilization <20% or memory utilization <20%
    - Script calculates current cost using Kubecost/OpenCost pricing data
    - Script generates report with workload name, current cost, utilization percentage, recommended action
    - _Requirements: 12.1, 12.2, 12.4_
  
  - [~] 12.2 Create unused volume detection script
    - Create `finops/scripts/detect-unused-volumes.py` that queries Kubernetes API for PersistentVolumes
    - Script identifies volumes not accessed in 30 days using last access timestamp
    - Script calculates storage cost using Kubecost/OpenCost pricing data
    - Script generates report with volume name, size, cost, last access date, recommended action
    - _Requirements: 12.3, 12.4_
  
  - [~] 12.3 Create optimization dashboard
    - Create `finops/dashboards/optimization-opportunities.json` with panels for top 20 cost optimization opportunities
    - Display underutilized workloads and unused volumes ranked by potential savings
    - Add links to detailed workload/volume information
    - _Requirements: 12.5_
  
  - [~] 12.4 Write unit tests for optimization detection
    - Create `finops/scripts/test_detect_underutilized.py` with pytest tests
    - Test utilization threshold detection
    - Test cost calculation
    - Test report generation
    - _Requirements: 12.1, 12.2, 12.4_

- [ ] 13. Implement cost tagging validation
  - [~] 13.1 Create tag validation script
    - Create `finops/scripts/validate-cost-tags.py` that scans all namespaces for missing `finops.org/costcenter` and `finops.org/environment` labels
    - Script generates report listing non-compliant namespaces and pods
    - Script calculates compliance percentage
    - _Requirements: 14.1, 14.2, 14.3_
  
  - [~] 13.2 Create Prometheus alerting rules for tag compliance
    - Create `finops/prometheus/tag-compliance-alerts.yaml` with rule that triggers when >5% of pods lack required cost tags
    - Configure alert with namespace and compliance percentage
    - _Requirements: 14.4_
  
  - [~] 13.3 Create tag compliance documentation
    - Create `finops/docs/cost-tagging-schema.md` explaining required cost tagging schema
    - Document enforcement mechanisms (Kyverno policies, compliance alerts)
    - Include examples of properly tagged resources
    - _Requirements: 14.6_
  
  - [~] 13.4 Write unit tests for tag validation
    - Create `finops/scripts/test_validate_cost_tags.py` with pytest tests
    - Test detection of missing labels
    - Test compliance percentage calculation
    - Test namespace filtering
    - _Requirements: 14.1, 14.2, 14.3_

- [ ] 14. Implement reserved capacity recommendations
  - [~] 14.1 Create workload stability analysis script
    - Create `finops/scripts/analyze-reserved-capacity.py` that queries Prometheus for workload resource usage over 90 days
    - Script identifies workloads with <10% resource variance (stable workloads)
    - Script calculates current on-demand cost using Kubecost/OpenCost pricing data
    - Script estimates reserved capacity cost (typically 30-40% discount)
    - Script calculates potential annual savings
    - Script generates report with workload name, current cost, reserved cost, potential savings
    - _Requirements: 15.1, 15.2, 15.3, 15.4_
  
  - [~] 14.2 Create reserved capacity dashboard
    - Create `finops/dashboards/reserved-capacity.json` with panels for reserved capacity utilization and coverage percentage
    - Display stable workload candidates ranked by potential savings
    - _Requirements: 15.6_
  
  - [~] 14.3 Create reserved capacity documentation
    - Create `finops/docs/reserved-capacity-recommendations.md` explaining reserved instance and savings plan options for AWS, Azure, GCP
    - Document how to purchase and manage reserved capacity
    - Include cost-benefit analysis examples
    - _Requirements: 15.5_
  
  - [~] 14.4 Write unit tests for stability analysis
    - Create `finops/scripts/test_analyze_reserved_capacity.py` with pytest tests
    - Test resource variance calculation
    - Test stable workload identification
    - Test savings calculation
    - _Requirements: 15.1, 15.2, 15.3_

- [ ] 15. Implement FinOps metrics export
  - [~] 15.1 Create Prometheus metrics exporter
    - Create `finops/scripts/export-metrics.py` that exposes cost metrics in Prometheus format at `/metrics` endpoint
    - Metrics include namespace cost, workload cost, resource type breakdown
    - Add metadata labels for cluster name, cloud provider, cost center
    - _Requirements: 13.1, 13.6_
  
  - [~] 15.2 Create Prometheus API query examples
    - Create `finops/docs/prometheus-api-examples.md` with example queries for cost metrics
    - Include curl commands and Python requests examples
    - Document metric names and label filters
    - _Requirements: 13.5_

- [ ] 16. Implement golden path integration
  - [~] 16.1 Update kubernetes-microservice golden path documentation
    - Update `docs/golden-paths/kubernetes-microservice.md` to include FinOps checkpoint steps
    - Add step: Review VPA recommendations before production deployment
    - Add step: Verify `finops.org/costcenter` and `finops.org/environment` labels present
    - Add step: Confirm resource requests align with team budget
    - _Requirements: 8.1, 8.2, 8.3_
  
  - [~] 16.2 Update serverless-app golden path documentation
    - Update `docs/golden-paths/serverless-app.md` to include FinOps checkpoint steps
    - Add step: Review Infracost estimates in PR
    - Add step: Approve cost increases >20%
    - _Requirements: 8.4_
  
  - [~] 16.3 Create FinOps PR checklist template
    - Create `finops/templates/pr-checklist.md` with FinOps review items
    - Checklist items: FinOps labels applied, Infracost estimate reviewed, VPA recommendations considered, cost impact documented
    - _Requirements: 8.5_
  
  - [~] 16.4 Create FinOps workflow documentation
    - Create `finops/docs/finops-workflow.md` explaining when to perform FinOps reviews in development lifecycle
    - Document pre-production review process and major change review process
    - _Requirements: 8.6_

- [ ] 17. Create comprehensive FinOps documentation
  - [~] 17.1 Create main FinOps README
    - Create `finops/README.md` with architecture overview, component descriptions, and quick start guide
    - Include architecture diagrams showing data flow between components
    - _Requirements: 11.1, 11.6_
  
  - [~] 17.2 Create installation guide
    - Create `finops/docs/installation.md` with step-by-step instructions for deploying all FinOps components
    - Document prerequisites (Prometheus, Grafana, Kyverno)
    - Include verification steps for each component
    - _Requirements: 11.2_
  
  - [~] 17.3 Create cost spike investigation runbook
    - Create `finops/docs/runbooks/investigate-cost-spike.md` with step-by-step troubleshooting process
    - Include Prometheus queries for cost analysis
    - Document common causes and remediation steps
    - _Requirements: 11.3_
  
  - [~] 17.4 Create team onboarding runbook
    - Create `finops/docs/runbooks/onboard-new-team.md` with process for adding new teams to FinOps system
    - Document budget configuration, namespace labeling, and dashboard access setup
    - _Requirements: 11.4_
  
  - [~] 17.5 Create troubleshooting guide
    - Create `finops/docs/troubleshooting.md` with common FinOps component failures and solutions
    - Include sections for cost monitoring, VPA, Kyverno, alerting, and reporting issues
    - _Requirements: 11.5_
  
  - [~] 17.6 Create tool comparison documentation
    - Create `finops/docs/kubecost-vs-opencost.md` comparing Kubecost and OpenCost feature sets
    - Document decision criteria for tool selection
    - Include licensing, support, and feature comparison table
    - _Requirements: 1.4_

- [~] 18. Final checkpoint - Integration testing and validation
  - Ensure all FinOps components deploy successfully, dashboards display data, alerts trigger correctly, and documentation is complete. Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key integration points
- Unit tests validate script logic and calculations
- The implementation uses existing tools (Kubecost/OpenCost, VPA, Kyverno, Infracost) with custom integration scripts
- Python scripts use `pytest` for unit testing
- Bash scripts use `bats` for unit testing (where applicable)
- Kyverno policies use Kyverno CLI test framework for validation
- All configuration files are YAML-based for consistency with Kubernetes ecosystem
- Documentation follows the existing CI/CD reference architecture structure

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.3", "2.4"] },
    { "id": 2, "tasks": ["4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "4.7", "5.1", "6.1", "8.1", "8.2", "8.3", "8.4", "10.1"] },
    { "id": 3, "tasks": ["4.8", "5.2", "6.2", "6.3", "8.5", "9.1", "10.2", "10.3", "10.4", "11.1", "11.2", "12.1", "12.2", "13.1", "13.2", "14.1", "15.1"] },
    { "id": 4, "tasks": ["5.3", "6.4", "8.6", "9.2", "9.3", "9.4", "10.5", "11.3", "12.3", "13.3", "14.2", "14.3", "15.2"] },
    { "id": 5, "tasks": ["9.5", "12.4", "13.4", "14.4", "16.1", "16.2", "16.3", "16.4"] },
    { "id": 6, "tasks": ["17.1", "17.2", "17.3", "17.4", "17.5", "17.6"] }
  ]
}
```
