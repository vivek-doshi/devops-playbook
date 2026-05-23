# Repository Map

Generated from current workspace structure.

- Root: d:/projects/cicd-reference
- Generated: 2026-05-23 19:39:59
- Exclusions: .ai/, .git/, .github/prompts/, .github/skills/, .kiro/, website/

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
│   ├── Dockerfile
│   └── README.md
├── .github
│   ├── ISSUE_TEMPLATE
│   │   ├── bug-report.yml
│   │   └── feature-request.yml
│   ├── workflows
│   │   ├── dependabot-automerge.yml
│   │   └── deploy.yml
│   ├── CODEOWNERS
│   ├── copilot-instructions.md
│   ├── dependabot.yml
│   └── PULL_REQUEST_TEMPLATE.md
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
├── cd
│   ├── gitops
│   │   ├── argocd
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
│   │   │   └── reusable-security-scan.yml
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
│   │   │   └── sonar-scan.yml
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
│   │   ├── external-secrets-operator.yaml
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
│   │   └── ADR-003-gitops-strategy.md
│   ├── diagrams
│   │   ├── deployment-flow.png
│   │   ├── deployment-flow.svg
│   │   ├── pipeline-overview.drawio
│   │   └── pipeline-overview.svg
│   ├── golden-paths
│   │   ├── database-migrations.md
│   │   ├── data-pipeline.md
│   │   ├── frontend-spa.md
│   │   ├── incident-response.md
│   │   ├── kubernetes-microservice.md
│   │   ├── mlops-workflow.md
│   │   ├── mobile-backend.md
│   │   ├── multi-tenant-saas.md
│   │   ├── platform-onboarding.md
│   │   └── serverless-app.md
│   ├── guides
│   │   ├── branching-strategy.md
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
│   │   └── template.md
│   ├── ARCHITECTURE_DECISION_GUIDE.md
│   ├── ARCHITECTURE_DECISION_GUIDE.pdf
│   └── repo_structure.md
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
│   │   ├── install-cost-monitoring.sh
│   │   ├── README.md
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
│   │   │   └── slo-rules.yaml
│   │   ├── dashboards
│   │   │   ├── slo-burn-rate.json
│   │   │   └── slo-burn-rate-configmap.yaml
│   │   ├── slos
│   │   │   ├── availability-slo.yaml
│   │   │   ├── latency-slo.yaml
│   │   │   └── README.md
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
│   │   ├── README.md
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
│   ├── docker-cleanup.sh
│   ├── env-checker.sh
│   ├── fix-continuation-comments.ps1
│   ├── generate-repo-map.ps1
│   ├── k8s-rollout-check.sh
│   └── tag-release.sh
├── secops
│   ├── compliance
│   │   ├── controls
│   │   │   ├── cis-kubernetes.md
│   │   │   ├── iso27001.md
│   │   │   └── soc2.md
│   │   ├── kube-bench-cronjob.yaml
│   │   └── kube-bench-job.yaml
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
│   │   ├── sbom-policy.yaml
│   │   └── slsa-verify.yaml
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
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── aws-eks
│   │   ├── tests
│   │   │   └── unit.tftest.hcl
│   │   ├── backup.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── aws-lambda
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── azure-aks
│   │   ├── backup.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── azure-app-service
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-gke
│   │   ├── backup.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── tests
│   │   ├── aws-eks.tftest.hcl
│   │   ├── azure-aks.tftest.hcl
│   │   └── README.md
│   └── README.md
├── .gitignore
├── .pre-commit-config.yaml
├── GETTING_STARTED.md
├── Makefile
├── README.md
├── SETUP_GITHUB_PAGES.md
└── Taskfile.yml
```
