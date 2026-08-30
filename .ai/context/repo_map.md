# Repository Map

Generated from current workspace structure.

- Root: d:/personal/projects/devops-playbook
- Generated: 2026-06-25 23:04:54
- Exclusions: .ai/, .git/, .github/prompts/, .github/skills/, .kiro/, catalog/scripts/__pycache__/, finops/scripts/__pycache__/, secops/compliance/scripts/__pycache__/, website/

```text
.
├── .devcontainer
│   ├── gpu
│   │   ├── devcontainer.json
│   │   ├── post-create.sh
│   │   └── README.md
│   ├── scripts
│   │   └── post-create.sh
│   ├── devcontainer.json
│   ├── devcontainer-lock.json
│   ├── Dockerfile
│   └── README.md
├── .github
│   ├── ISSUE_TEMPLATE
│   │   ├── bug-report.yml
│   │   └── feature-request.yml
│   ├── workflows
│   │   ├── dependabot-automerge.yml
│   │   ├── deploy.yml
│   │   └── validate-catalog.yml
│   ├── CODEOWNERS
│   ├── copilot-instructions.md
│   ├── dependabot.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── .vscode
│   └── settings.json
├── backup
│   ├── terraform
│   │   ├── aws-rds-backup.tf
│   │   ├── azure-postgres-backup.tf
│   │   └── gcp-cloudsql-backup.tf
│   └── velero
│       ├── aws-install.sh
│       ├── namespace-backup.yaml
│       ├── README.md
│       └── schedule.yaml
├── catalog
│   ├── schema
│   │   └── service.yaml
│   ├── scripts
│   │   ├── generate-codeowners.py
│   │   ├── migrate-to-backstage.py
│   │   └── validate-catalog.py
│   ├── services
│   │   └── example-api-gateway.yaml
│   ├── teams
│   │   ├── schema
│   │   │   └── team.yaml
│   │   ├── platform-team.yaml
│   │   └── README.md
│   └── README.md
├── cd
│   ├── fleet-overlays
│   │   ├── dev
│   │   │   └── .gitkeep
│   │   ├── production
│   │   │   └── .gitkeep
│   │   ├── staging
│   │   │   └── webapp-example
│   │   │       └── kustomization.yaml
│   │   └── README.md
│   ├── gitops
│   │   ├── argocd
│   │   │   ├── fleet
│   │   │   │   ├── cluster-registry.yaml
│   │   │   │   ├── fleet-applicationset.yaml
│   │   │   │   ├── fleet-project.yaml
│   │   │   │   └── fleet-workload-applicationset.yaml
│   │   │   ├── application.yaml
│   │   │   ├── applicationset.yaml
│   │   │   └── app-of-apps.yaml
│   │   └── flux
│   │       └── kustomization.yaml
│   ├── helm
│   │   ├── microservice
│   │   │   └── README.md
│   │   ├── webapp
│   │   │   ├── templates
│   │   │   │   ├── _helpers.tpl
│   │   │   │   └── deployment.yaml
│   │   │   ├── Chart.yaml
│   │   │   ├── values.dev.yaml
│   │   │   ├── values.prod.yaml
│   │   │   └── values.yaml
│   │   └── README.md
│   ├── kubernetes
│   │   ├── _base
│   │   │   ├── network-policies
│   │   │   │   ├── allow-egress-to-database.yaml
│   │   │   │   ├── allow-egress-to-dns.yaml
│   │   │   │   ├── allow-ingress-from-ingress-controller.yaml
│   │   │   │   ├── allow-prometheus-scrape.yaml
│   │   │   │   ├── default-deny.yaml
│   │   │   │   ├── kustomization.yaml
│   │   │   │   └── README.md
│   │   │   ├── rbac
│   │   │   │   ├── ci-deployer.yaml
│   │   │   │   ├── kustomization.yaml
│   │   │   │   ├── namespace-admin.yaml
│   │   │   │   ├── README.md
│   │   │   │   └── readonly-developer.yaml
│   │   │   ├── cert-manager-bootstrap.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── hpa.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── kustomization.yaml
│   │   │   ├── networkpolicy.yaml
│   │   │   ├── pdb.yaml
│   │   │   ├── rbac.yaml
│   │   │   ├── service.yaml
│   │   │   └── vpa.yaml
│   │   ├── _overlays
│   │   │   ├── dev
│   │   │   │   └── kustomization.yaml
│   │   │   ├── prod
│   │   │   │   └── kustomization.yaml
│   │   │   └── staging
│   │   │       └── kustomization.yaml
│   │   ├── _patterns
│   │   │   ├── blue-green.yaml
│   │   │   ├── canary.yaml
│   │   │   ├── db-migration-hook.yaml
│   │   │   ├── db-migration-init-container.yaml
│   │   │   ├── db-migration-job.yaml
│   │   │   ├── dev-scale-to-zero.yaml
│   │   │   ├── gpu-inference-deployment.yaml
│   │   │   ├── gpu-training-job.yaml
│   │   │   ├── init-containers.yaml
│   │   │   ├── secret-provider-class.yaml
│   │   │   └── velero-backup.yaml
│   │   ├── cert-manager
│   │   │   ├── cluster-issuer-prod.yaml
│   │   │   ├── cluster-issuer-selfsigned.yaml
│   │   │   ├── cluster-issuer-staging.yaml
│   │   │   ├── kustomization.yaml
│   │   │   ├── namespace.yaml
│   │   │   └── README.md
│   │   └── README.md
│   ├── pulumi
│   │   ├── aws
│   │   │   ├── index.ts
│   │   │   ├── Pulumi.prod.yaml
│   │   │   └── Pulumi.yaml
│   │   ├── azure
│   │   │   ├── index.ts
│   │   │   ├── Pulumi.prod.yaml
│   │   │   └── Pulumi.yaml
│   │   ├── gcp
│   │   │   ├── index.ts
│   │   │   ├── Pulumi.prod.yaml
│   │   │   └── Pulumi.yaml
│   │   ├── deploy.yml
│   │   └── README.md
│   ├── targets
│   │   ├── aws-codepipeline
│   │   │   ├── buildspec.yml
│   │   │   └── codepipeline.yml
│   │   ├── aws-ecs
│   │   │   └── github-actions-deploy.yml
│   │   ├── aws-eks
│   │   │   ├── github-actions-deploy.yml
│   │   │   └── gitlab-deploy.yml
│   │   ├── aws-lambda
│   │   │   └── serverless-deploy.yml
│   │   ├── azure-aks
│   │   │   ├── azure-pipelines-deploy.yml
│   │   │   ├── github-actions-deploy.yml
│   │   │   └── gitlab-deploy.yml
│   │   ├── azure-app-service
│   │   │   └── github-actions-deploy.yml
│   │   ├── gcp-gke
│   │   │   ├── cloudbuild.yaml
│   │   │   └── github-actions-deploy.yml
│   │   └── openshift
│   │       ├── azure-pipelines-deploy.yml
│   │       ├── github-actions-deploy.yml
│   │       └── gitlab-deploy.yml
│   └── README.md
├── ci
│   ├── azure-pipelines
│   │   ├── _strategies
│   │   │   ├── deployment-gates.yml
│   │   │   └── variable-groups.yml
│   │   ├── _templates
│   │   │   ├── build-template.yml
│   │   │   ├── docker-template.yml
│   │   │   └── test-template.yml
│   │   ├── angular
│   │   │   └── azure-pipelines.yml
│   │   ├── dotnet
│   │   │   └── azure-pipelines.yml
│   │   ├── python
│   │   │   └── azure-pipelines.yml
│   │   └── terraform
│   │       └── azure-pipelines.yml
│   ├── github-actions
│   │   ├── _shared
│   │   │   ├── environment-protection.md
│   │   │   ├── pr-conventional-commit.yml
│   │   │   ├── reusable-attest.yml
│   │   │   ├── reusable-docker-build.yml
│   │   │   ├── reusable-notify-slack.yml
│   │   │   ├── reusable-security-scan.yml
│   │   │   ├── reusable-supply-chain.yml
│   │   │   └── reusable-supply-chain-verify.yml
│   │   ├── _strategies
│   │   │   ├── matrix-build.yml
│   │   │   ├── monorepo-affected.yml
│   │   │   ├── release-please.yml
│   │   │   └── semantic-release.yml
│   │   ├── angular
│   │   │   ├── build-test.yml
│   │   │   └── lighthouse-audit.yml
│   │   ├── dotnet
│   │   │   ├── build-test.yml
│   │   │   ├── docker-publish.yml
│   │   │   ├── sonar-scan.yml
│   │   │   └── supply-chain-integration.yml
│   │   ├── go
│   │   │   ├── build-test.yml
│   │   │   └── docker-publish.yml
│   │   ├── java
│   │   │   └── build-test.yml
│   │   ├── python
│   │   │   ├── build-test.yml
│   │   │   └── security-scan.yml
│   │   ├── react
│   │   │   └── build-test.yml
│   │   ├── ruby
│   │   │   └── build-test.yml
│   │   └── terraform
│   │       ├── cost-estimation.yml
│   │       ├── drift-detection.yml
│   │       ├── module-test.yml
│   │       └── plan-apply.yml
│   ├── gitlab-ci
│   │   ├── _includes
│   │   │   ├── .docker-build.yml
│   │   │   ├── .notify.yml
│   │   │   └── .sast-scan.yml
│   │   ├── _strategies
│   │   │   ├── dynamic-pipeline.yml
│   │   │   └── parent-child-pipeline.yml
│   │   ├── dotnet
│   │   │   └── .gitlab-ci.yml
│   │   ├── python
│   │   │   └── .gitlab-ci.yml
│   │   └── terraform
│   │       └── .gitlab-ci.yml
│   ├── jenkins
│   │   ├── _shared
│   │   │   └── shared-library-example
│   │   │       └── vars
│   │   │           └── buildAndTest.groovy
│   │   ├── dotnet
│   │   │   └── Jenkinsfile
│   │   └── python
│   │       └── Jenkinsfile
│   └── README.md
├── ci-security
│   ├── container-scanning
│   │   ├── grype-scan.yml
│   │   └── trivy-scan.yml
│   ├── dependency-audit
│   │   ├── npm-audit.yml
│   │   ├── nuget-audit.yml
│   │   └── pip-audit.yml
│   ├── iac-scanning
│   │   ├── checkov.yml
│   │   ├── README.md
│   │   └── tfsec.yml
│   ├── sast
│   │   ├── semgrep.yml
│   │   ├── snyk.yml
│   │   └── sonarqube.yml
│   ├── secret-detection
│   │   ├── gitleaks.yml
│   │   └── trufflehog.yml
│   ├── secret-rotation
│   │   ├── aws-rotation-lambda.py
│   │   ├── aws-rotation-lambda.tf
│   │   ├── azure-keyvault-rotation.tf
│   │   └── README.md
│   └── README.md
├── compose
│   ├── _templates
│   │   └── docker-compose.base.yml
│   ├── dotnet-sqlserver
│   │   └── docker-compose.yml
│   ├── java-postgres
│   │   ├── .env.example
│   │   ├── docker-compose.debug.yml
│   │   ├── docker-compose.yml
│   │   └── README.md
│   ├── microservices-example
│   │   └── docker-compose.yml
│   ├── python-postgres-redis
│   │   └── docker-compose.yml
│   └── README.md
├── docker
│   ├── _base
│   │   ├── Dockerfile.multistage
│   │   └── security-hardened.Dockerfile
│   ├── angular
│   │   ├── .dockerignore
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   ├── dotnet
│   │   ├── .dockerignore
│   │   ├── Dockerfile.api
│   │   └── Dockerfile.worker
│   ├── go
│   │   ├── .dockerignore
│   │   └── Dockerfile
│   ├── java
│   │   ├── .dockerignore
│   │   ├── Dockerfile.gradle
│   │   └── Dockerfile.springboot
│   ├── node
│   │   ├── .dockerignore
│   │   ├── Dockerfile.express
│   │   └── Dockerfile.nextjs
│   ├── python
│   │   ├── .dockerignore
│   │   ├── Dockerfile.django
│   │   ├── Dockerfile.fastapi
│   │   └── Dockerfile.flask
│   ├── react
│   │   ├── Dockerfile
│   │   ├── Dockerfile.dev
│   │   └── nginx.conf
│   ├── ruby
│   │   ├── .dockerignore
│   │   └── Dockerfile.rails
│   └── README.md
├── docs
│   ├── decisions
│   │   ├── ADR-001-folder-structure.md
│   │   ├── ADR-002-helm-vs-kustomize.md
│   │   ├── ADR-003-gitops-strategy.md
│   │   ├── ADR-004-policy-enforcement-layering.md
│   │   ├── ADR-005-slo-driven-operations-standard.md
│   │   └── README.md
│   ├── diagrams
│   │   ├── deployment-flow.png
│   │   ├── deployment-flow.svg
│   │   ├── pipeline-overview.drawio
│   │   ├── pipeline-overview.svg
│   │   └── README.md
│   ├── golden-paths
│   │   ├── compliance-reporting.md
│   │   ├── database-migrations.md
│   │   ├── data-pipeline.md
│   │   ├── finops-optimization.md
│   │   ├── frontend-spa.md
│   │   ├── incident-response.md
│   │   ├── kubernetes-microservice.md
│   │   ├── mlops-workflow.md
│   │   ├── mobile-backend.md
│   │   ├── multi-cluster-fleet.md
│   │   ├── multi-tenant-saas.md
│   │   ├── platform-onboarding.md
│   │   ├── serverless-app.md
│   │   ├── service-catalog.md
│   │   ├── slo-driven-development.md
│   │   └── supply-chain-security.md
│   ├── guides
│   │   ├── branching-strategy.md
│   │   ├── concepts.md
│   │   ├── conventional-commits.md
│   │   ├── database-migrations.md
│   │   ├── disaster-recovery.md
│   │   ├── environment-strategy.md
│   │   ├── github-actions-oidc.md
│   │   ├── onboarding.md
│   │   ├── pre-commit-setup.md
│   │   ├── secrets-management.md
│   │   └── versioning-strategy.md
│   ├── runbooks
│   │   ├── podcrashloobackoff.md
│   │   ├── README.md
│   │   ├── slo-breach-response.md
│   │   ├── slo-quarterly-review.md
│   │   └── template.md
│   ├── ARCHITECTURE_DECISION_GUIDE.md
│   └── ARCHITECTURE_DECISION_GUIDE.pdf
├── finops
│   ├── cicd
│   │   ├── azure-pipelines-infracost.yml
│   │   ├── github-actions-infracost.yml
│   │   └── gitlab-ci-infracost.yml
│   ├── config
│   │   └── budgets.yaml
│   ├── dashboards
│   │   ├── anomaly-detection.json
│   │   ├── budget-tracking.json
│   │   ├── cost-breakdown.json
│   │   ├── cost-overview.json
│   │   ├── multi-cloud-comparison.json
│   │   ├── optimization-opportunities.json
│   │   ├── README.md
│   │   ├── reserved-capacity.json
│   │   ├── rightsizing-opportunities.json
│   │   └── tag-compliance.json
│   ├── docs
│   │   ├── runbooks
│   │   │   ├── investigate-cost-spike.md
│   │   │   └── onboard-new-team.md
│   │   ├── cloud-provider-setup.md
│   │   ├── cost-tagging-schema.md
│   │   ├── finops-workflow.md
│   │   ├── infracost-integration.md
│   │   ├── installation.md
│   │   ├── kubecost-vs-opencost.md
│   │   ├── optimization-runbook.md
│   │   ├── prometheus-api-examples.md
│   │   ├── README.md
│   │   ├── reserved-capacity-recommendations.md
│   │   └── troubleshooting.md
│   ├── helm
│   │   ├── kubecost-values.yaml
│   │   ├── opencost-values.yaml
│   │   ├── README.md
│   │   └── vpa-values.yaml
│   ├── infracost
│   │   └── .infracost.yml
│   ├── kubernetes
│   │   └── cost-report-cronjob.yaml
│   ├── policies
│   │   ├── enforce-resource-limits.yaml
│   │   ├── gpu-approval-gate.yaml
│   │   ├── README.md
│   │   ├── require-cost-labels.yaml
│   │   ├── require-pdb-large-workloads.yaml
│   │   └── test-policies.sh
│   ├── prometheus
│   │   ├── alertmanager-anomaly-config.yaml
│   │   ├── alertmanager-budget-config.yaml
│   │   ├── anomaly-alerts.yaml
│   │   ├── budget-alerts.yaml
│   │   └── tag-compliance-alerts.yaml
│   ├── scripts
│   │   ├── analyze-reserved-capacity.py
│   │   ├── analyze-rightsizing.py
│   │   ├── deploy-anomaly-alerts.sh
│   │   ├── deploy-budget-alerts.sh
│   │   ├── deploy-dashboards.sh
│   │   ├── deploy-policies.sh
│   │   ├── detect-underutilized.py
│   │   ├── detect-unused-volumes.py
│   │   ├── export-cost-report.sh
│   │   ├── generate-cost-report.py
│   │   ├── generate-optimization-pr.py
│   │   ├── install-cost-monitoring.sh
│   │   ├── normalize-cloud-costs.py
│   │   ├── README.md
│   │   ├── reserved-capacity-advisor.py
│   │   ├── send-to-billing-api.py
│   │   ├── test_analyze_reserved_capacity.py
│   │   ├── test_analyze_rightsizing.py
│   │   ├── test_detect_underutilized.py
│   │   ├── test_generate_cost_report.py
│   │   ├── test_validate_cost_tags.py
│   │   └── validate-cost-tags.py
│   ├── templates
│   │   └── pr-checklist.md
│   └── README.md
├── local-dev
│   ├── kind
│   │   ├── kind-config.yaml
│   │   ├── load-image.sh
│   │   ├── setup.sh
│   │   └── teardown.sh
│   └── README.md
├── notifications
│   ├── datadog-notify.yml
│   ├── grafana-notify.yml
│   ├── pagerduty-notify.yml
│   ├── slack-notify.yml
│   └── teams-notify.yml
├── observability
│   ├── loki
│   │   ├── dashboards
│   │   │   └── log-explorer.json
│   │   ├── grafana-datasource.yaml
│   │   ├── loki-ruler-alerts.yaml
│   │   ├── README.md
│   │   └── values.yaml
│   ├── opentelemetry
│   │   ├── env-vars
│   │   │   ├── dotnet.env
│   │   │   ├── java.env
│   │   │   └── python.env
│   │   ├── collector-config.yaml
│   │   ├── collector-sidecar.yaml
│   │   └── README.md
│   ├── otel
│   │   └── README.md
│   ├── prometheus
│   │   ├── alerts
│   │   │   ├── cert-manager-alerts.yaml
│   │   │   ├── deployment-alerts.yaml
│   │   │   ├── pod-alerts.yaml
│   │   │   ├── slo-burn-rate-alerts.yaml
│   │   │   └── slo-rules.yaml
│   │   ├── dashboards
│   │   │   ├── slo-burn-rate.json
│   │   │   ├── slo-burn-rate-configmap.yaml
│   │   │   └── slo-status-configmap.yaml
│   │   ├── recording-rules
│   │   │   └── slo-burn-rates.yaml
│   │   ├── slos
│   │   │   ├── availability-slo.yaml
│   │   │   ├── latency-slo.yaml
│   │   │   ├── my-service-availability-slo.yaml
│   │   │   ├── my-service-latency-slo.yaml
│   │   │   ├── README.md
│   │   │   └── slo-schema.yaml
│   │   ├── fleet-aggregation.yaml
│   │   ├── README.md
│   │   └── values.yaml
│   ├── tempo
│   │   ├── grafana-datasource.yaml
│   │   ├── README.md
│   │   └── values.yaml
│   └── README.md
├── policy
│   ├── conftest
│   │   ├── kubernetes
│   │   │   ├── deny_latest_tag.rego
│   │   │   ├── deny_privileged.rego
│   │   │   ├── require_labels.rego
│   │   │   ├── require_probes.rego
│   │   │   └── require_resources.rego
│   │   ├── terraform
│   │   │   └── deny_public_s3.rego
│   │   ├── .conftest.yaml
│   │   └── README.md
│   ├── kyverno
│   │   ├── disallow-latest-tag.yaml
│   │   ├── enforce-finops-labels.yaml
│   │   ├── fleet-policy-propagation.yaml
│   │   ├── README.md
│   │   ├── require-catalog-registration.yaml
│   │   ├── require-labels.yaml
│   │   ├── require-liveness-readiness.yaml
│   │   ├── require-non-root.yaml
│   │   ├── require-readonly-filesystem.yaml
│   │   └── require-resource-limits.yaml
│   └── README.md
├── quality
│   ├── dotnet
│   │   └── .runsettings
│   ├── javascript
│   │   ├── .eslintrc.json
│   │   └── .prettierrc
│   ├── python
│   │   ├── .flake8
│   │   └── pyproject.toml
│   ├── .editorconfig
│   └── sonar-project.properties
├── scripts
│   ├── add-educational-comments.ps1
│   ├── clean-website-comments.ps1
│   ├── docker-cleanup.ps1
│   ├── docker-cleanup.sh
│   ├── env-checker.ps1
│   ├── env-checker.sh
│   ├── fix-continuation-comments.ps1
│   ├── generate-repo-map.ps1
│   ├── k8s-rollout-check.ps1
│   ├── k8s-rollout-check.sh
│   ├── tag-release.ps1
│   └── tag-release.sh
├── secops
│   ├── compliance
│   │   ├── alerts
│   │   │   └── compliance-alerts.yaml
│   │   ├── control-library
│   │   │   ├── cis-kubernetes.yaml
│   │   │   ├── control-to-policy-map.yaml
│   │   │   ├── iso27001.yaml
│   │   │   └── soc2-controls.yaml
│   │   ├── controls
│   │   │   ├── cis-kubernetes.md
│   │   │   ├── iso27001.md
│   │   │   └── soc2.md
│   │   ├── kubernetes
│   │   │   └── compliance-report-cronjob.yaml
│   │   ├── scripts
│   │   │   ├── collect-evidence.sh
│   │   │   └── generate-compliance-report.py
│   │   ├── kube-bench-cronjob.yaml
│   │   ├── kube-bench-job.yaml
│   │   └── README.md
│   ├── runbooks
│   │   ├── compromised-pod.md
│   │   ├── node-compromise.md
│   │   ├── secret-exposure.md
│   │   └── supply-chain-incident.md
│   ├── runtime
│   │   ├── audit-logging
│   │   │   ├── audit-policy.yaml
│   │   │   └── loki-shipper.yaml
│   │   └── falco
│   │       ├── rules
│   │       │   ├── alerts.yaml
│   │       │   └── custom-rules.yaml
│   │       └── values.yaml
│   ├── supply-chain
│   │   ├── cosign-verify-policy.yaml
│   │   ├── README.md
│   │   ├── sbom-policy.yaml
│   │   ├── slsa-verify.yaml
│   │   └── supply-chain-status.yaml
│   └── README.md
├── secrets
│   ├── external-secrets
│   │   ├── aws-secret-store.yaml
│   │   ├── azure-secret-store.yaml
│   │   ├── example-external-secret.yaml
│   │   ├── gcp-secret-store.yaml
│   │   └── README.md
│   └── rotation
│       ├── aws-rotation.yml
│       ├── azure-rotation.yml
│       └── gcp-rotation.yml
├── terraform
│   ├── _bootstrap
│   │   ├── aws
│   │   │   └── main.tf
│   │   ├── azure
│   │   │   └── main.tf
│   │   ├── gcp
│   │   │   └── main.tf
│   │   └── README.md
│   ├── _testing
│   │   └── terratest
│   │       └── aws_eks_test.go
│   ├── aws-ecs
│   │   ├── modules
│   │   │   ├── alb
│   │   │   ├── autoscaling
│   │   │   ├── ecr
│   │   │   ├── ecs
│   │   │   ├── network
│   │   │   └── security-groups
│   │   ├── locals.tf
│   │   ├── main.tf (orchestrator: module calls only)
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── aws-eks
│   │   ├── modules
│   │   │   ├── backup
│   │   │   ├── ecr
│   │   │   ├── eks
│   │   │   ├── iam
│   │   │   ├── network
│   │   │   └── security-groups
│   │   ├── tests
│   │   │   └── unit.tftest.hcl
│   │   ├── locals.tf
│   │   ├── main.tf (orchestrator: module calls only)
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── aws-lambda
│   │   ├── modules
│   │   │   ├── api-gateway
│   │   │   ├── iam
│   │   │   └── lambda
│   │   ├── main.tf (orchestrator: module calls only)
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── azure-aks
│   │   ├── modules
│   │   │   ├── acr
│   │   │   ├── acr-rbac
│   │   │   ├── aks
│   │   │   ├── backup
│   │   │   ├── monitoring
│   │   │   └── network
│   │   ├── locals.tf
│   │   ├── main.tf (orchestrator: module calls only)
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── azure-app-service
│   │   ├── modules
│   │   │   ├── app-service-plan
│   │   │   ├── monitoring
│   │   │   ├── staging-slot
│   │   │   └── web-app
│   │   ├── locals.tf
│   │   ├── main.tf (orchestrator: module calls only)
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── gcp-gke
│   │   ├── modules
│   │   │   ├── artifact-registry
│   │   │   ├── backup
│   │   │   ├── gke
│   │   │   ├── iam
│   │   │   └── network
│   │   ├── locals.tf
│   │   ├── main.tf (orchestrator: module calls only)
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── tests
│   │   ├── aws-eks.tftest.hcl
│   │   ├── azure-aks.tftest.hcl
│   │   └── README.md
│   └── README.md
├── .gitignore
├── .pre-commit-config.yaml
├── .tflint.hcl
├── GEMINI.md
├── GETTING_STARTED.md
├── Makefile
├── README.md
└── Taskfile.yml
```
