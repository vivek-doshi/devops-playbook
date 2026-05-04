
# Repository Structure (Full Tree)

This document provides a complete, n-level overview of the repository structure, listing every file and directory with a one-line explanation of its purpose.

---

```text
.
├── .devcontainer/         # VS Code dev container configuration
├── .git/                  # Git version control metadata (hidden)
├── .github/               # GitHub workflows, issue templates, and skills
├── .pre-commit-config.yaml # Pre-commit hook configuration
├── backup/
│   ├── terraform/         # Terraform modules for DB backups
│   │   ├── aws-rds-backup.tf         # AWS RDS backup config
│   │   ├── azure-postgres-backup.tf  # Azure PostgreSQL backup config
│   │   └── gcp-cloudsql-backup.tf    # GCP Cloud SQL backup config
│   └── velero/
│       ├── aws-install.sh            # Velero install script for AWS
│       ├── namespace-backup.yaml     # Namespace backup schedule
│       ├── README.md                 # Velero usage and docs
│       └── schedule.yaml             # Velero backup schedule
├── cd/
│   ├── gitops/
│   │   ├── argocd/
│   │   │   ├── app-of-apps.yaml      # ArgoCD app-of-apps pattern
│   │   │   ├── application.yaml      # ArgoCD single app definition
│   │   │   └── applicationset.yaml   # ArgoCD multi-env generator
│   │   └── flux/
│   │       └── kustomization.yaml    # Flux Kustomization config
│   ├── helm/
│   │   ├── microservice/             # Helm chart for microservices
│   │   ├── webapp/                   # Helm chart for webapps
│   │   └── README.md                 # Helm usage and docs
│   ├── kubernetes/
│   │   ├── _base/
│   │   │   ├── cert-manager-bootstrap.yaml # Cert-manager bootstrap
│   │   │   ├── configmap.yaml        # Base ConfigMap
│   │   │   ├── deployment.yaml       # Base Deployment
│   │   │   ├── hpa.yaml              # Horizontal Pod Autoscaler
│   │   │   ├── ingress.yaml          # Ingress resource
│   │   │   ├── kustomization.yaml    # Kustomize base config
│   │   │   ├── network-policies/
│   │   │   │   ├── allow-egress-to-database.yaml # Allow DB egress
│   │   │   │   ├── allow-egress-to-dns.yaml      # Allow DNS egress
│   │   │   │   ├── allow-ingress-from-ingress-controller.yaml # Allow ingress
│   │   │   │   ├── allow-prometheus-scrape.yaml  # Allow Prometheus scrape
│   │   │   │   ├── default-deny.yaml             # Default deny policy
│   │   │   │   ├── kustomization.yaml            # Kustomize for policies
│   │   │   │   └── README.md                     # Policy docs
│   │   │   ├── networkpolicy.yaml    # NetworkPolicy resource
│   │   │   ├── pdb.yaml              # Pod Disruption Budget
│   │   │   ├── rbac/
│   │   │   │   ├── ci-deployer.yaml              # CI deployer RBAC
│   │   │   │   ├── kustomization.yaml            # Kustomize for RBAC
│   │   │   │   ├── namespace-admin.yaml          # Namespace admin RBAC
│   │   │   │   ├── README.md                     # RBAC docs
│   │   │   │   └── readonly-developer.yaml       # Read-only RBAC
│   │   │   ├── rbac.yaml             # Base RBAC
│   │   │   ├── service.yaml          # Base Service
│   │   │   └── vpa.yaml              # Vertical Pod Autoscaler
│   │   ├── _overlays/
│   │   │   ├── dev/
│   │   │   │   └── kustomization.yaml            # Dev overlay config
│   │   │   ├── prod/
│   │   │   │   └── kustomization.yaml            # Prod overlay config
│   │   │   └── staging/
│   │   │       └── kustomization.yaml            # Staging overlay config
│   │   ├── _patterns/
│   │   │   ├── blue-green.yaml       # Blue/Green deployment pattern
│   │   │   ├── canary.yaml           # Canary deployment pattern
│   │   │   ├── db-migration-hook.yaml # DB migration hook
│   │   │   ├── db-migration-init-container.yaml # DB migration init
│   │   │   ├── db-migration-job.yaml # DB migration job
│   │   │   ├── init-containers.yaml  # Init containers pattern
│   │   │   ├── secret-provider-class.yaml # Secret provider class
│   │   │   └── velero-backup.yaml    # Velero backup pattern
│   │   ├── cert-manager/
│   │   │   ├── cluster-issuer-prod.yaml      # Prod issuer
│   │   │   ├── cluster-issuer-selfsigned.yaml # Self-signed issuer
│   │   │   ├── cluster-issuer-staging.yaml   # Staging issuer
│   │   │   ├── kustomization.yaml            # Kustomize for cert-manager
│   │   │   ├── namespace.yaml                # Cert-manager namespace
│   │   │   └── README.md                     # Cert-manager docs
│   │   └── README.md                 # Kubernetes CD docs
│   ├── pulumi/
│   │   ├── aws/                     # Pulumi AWS configs
│   │   ├── azure/                   # Pulumi Azure configs
│   │   ├── gcp/                     # Pulumi GCP configs
│   │   ├── deploy.yml               # Pulumi deploy workflow
│   │   └── README.md                # Pulumi usage and docs
│   └── targets/
│       ├── aws-codepipeline/        # AWS CodePipeline deployment
│       ├── aws-ecs/                 # AWS ECS deployment
│       ├── aws-eks/                 # AWS EKS deployment
│       ├── aws-lambda/              # AWS Lambda deployment
│       ├── azure-aks/               # Azure AKS deployment
│       ├── azure-app-service/       # Azure App Service deployment
│       ├── gcp-gke/                 # GCP GKE deployment
│       └── openshift/               # OpenShift deployment
├── ci/
│   ├── azure-pipelines/             # Azure Pipelines templates
│   ├── github-actions/              # GitHub Actions workflows
│   ├── gitlab-ci/                   # GitLab CI templates
│   ├── jenkins/                     # Jenkins pipeline templates
│   └── README.md                    # CI usage and docs
├── compose/
│   ├── dotnet-sqlserver/            # .NET + SQL Server Compose
│   ├── java-postgres/               # Java + Postgres Compose
│   ├── microservices-example/       # Multi-service Compose example
│   ├── python-postgres-redis/       # Python + Postgres + Redis Compose
│   ├── README.md                    # Compose usage and docs
│   └── _templates/                  # Compose file templates
├── docker/
│   ├── angular/                     # Angular Dockerfiles
│   ├── dotnet/                      # .NET Dockerfiles
│   ├── go/                          # Go Dockerfiles
│   ├── java/                        # Java Dockerfiles
│   ├── node/                        # Node.js Dockerfiles
│   ├── python/                      # Python Dockerfiles
│   ├── react/                       # React Dockerfiles
│   ├── ruby/                        # Ruby Dockerfiles
│   ├── README.md                    # Docker usage and docs
│   └── _base/                       # Base Dockerfiles
├── docs/
│   ├── ARCHITECTURE_DECISION_GUIDE.md # Architecture decision guide
│   ├── ARCHITECTURE_DECISION_GUIDE.pdf # Architecture decision PDF
│   ├── decisions/
│   │   ├── ADR-001-folder-structure.md # ADR: folder structure
│   │   ├── ADR-002-helm-vs-kustomize.md # ADR: Helm vs Kustomize
│   │   └── ADR-003-gitops-strategy.md   # ADR: GitOps strategy
│   ├── diagrams/
│   │   ├── deployment-flow.png          # Deployment flow diagram
│   │   ├── deployment-flow.svg          # SVG diagram
│   │   ├── pipeline-overview.drawio     # Drawio pipeline diagram
│   │   └── pipeline-overview.svg        # SVG pipeline diagram
│   ├── golden-paths/
│   │   ├── data-pipeline.md             # Data pipeline golden path
│   │   ├── frontend-spa.md              # Frontend SPA golden path
│   │   ├── incident-response.md         # Incident response golden path
│   │   ├── kubernetes-microservice.md   # Kubernetes microservice golden path
│   │   ├── platform-onboarding.md       # Platform onboarding golden path
│   │   └── serverless-app.md            # Serverless app golden path
│   ├── guides/
│   │   ├── branching-strategy.md        # Branching strategy guide
│   │   ├── conventional-commits.md      # Conventional commits guide
│   │   ├── database-migrations.md       # Database migrations guide
│   │   ├── disaster-recovery.md         # Disaster recovery guide
│   │   ├── environment-strategy.md      # Environment strategy guide
│   │   ├── github-actions-oidc.md       # GitHub Actions OIDC guide
│   │   ├── onboarding.md                # Onboarding guide
│   │   ├── pre-commit-setup.md          # Pre-commit setup guide
│   │   ├── secrets-management.md        # Secrets management guide
│   │   └── versioning-strategy.md       # Versioning strategy guide
│   ├── repo_structure.md                # This file: repo structure
│   └── runbooks/
│       ├── podcrashloobackoff.md        # Pod crash loop runbook
│       └── template.md                  # Runbook template
├── GETTING_STARTED.md                   # Quickstart guide
├── local-dev/
│   ├── kind/
│   │   ├── kind-config.yaml             # Kind cluster config
│   │   ├── load-image.sh                # Load image into kind
│   │   ├── setup.sh                     # Kind cluster setup
│   │   └── teardown.sh                  # Kind cluster teardown
│   └── README.md                        # Local dev usage and docs
├── Makefile                             # Task runner for common tasks
├── notifications/
│   ├── datadog-notify.yml               # Datadog alert config
│   ├── grafana-notify.yml               # Grafana alert config
│   ├── pagerduty-notify.yml             # PagerDuty alert config
│   ├── slack-notify.yml                 # Slack alert config
│   └── teams-notify.yml                 # Teams alert config
├── observability/
│   ├── loki/                            # Loki log configs
│   ├── opentelemetry/                   # OpenTelemetry collector configs
│   ├── otel/                            # Additional OpenTelemetry configs
│   ├── prometheus/                      # Prometheus rules, dashboards, SLOs
│   ├── README.md                        # Observability usage and docs
│   └── tempo/                           # Tempo tracing configs
├── policy/
│   ├── conftest/                        # Conftest policy files
│   ├── kyverno/                         # Kyverno policy files
│   └── README.md                        # Policy usage and docs
├── quality/
│   ├── dotnet/                          # .NET quality configs
│   ├── javascript/                      # JavaScript quality configs
│   ├── python/                          # Python quality configs
│   └── sonar-project.properties         # SonarQube project config
├── README.md                            # Main project overview
├── scripts/
│   ├── add-educational-comments.ps1     # Add comments to code
│   ├── clean-website-comments.ps1       # Clean comments in website code
│   ├── docker-cleanup.sh                # Docker cleanup script
│   ├── env-checker.sh                   # Environment checker
│   ├── fix-continuation-comments.ps1    # Fix comment formatting
│   ├── k8s-rollout-check.sh             # Kubernetes rollout check
│   └── tag-release.sh                   # Tag a new release
├── secrets/
│   ├── external-secrets/
│   │   ├── aws-secret-store.yaml        # AWS secret store config
│   │   ├── azure-secret-store.yaml      # Azure secret store config
│   │   ├── example-external-secret.yaml # Example external secret
│   │   ├── gcp-secret-store.yaml        # GCP secret store config
│   │   └── README.md                    # External secrets docs
│   └── rotation/                        # Secret rotation scripts
├── security/
│   ├── container-scanning/              # Container scanning configs
│   ├── dependency-audit/                # Dependency audit configs
│   ├── iac-scanning/                    # IaC scanning configs
│   ├── README.md                        # Security usage and docs
│   ├── sast/                            # SAST configs
│   ├── secret-detection/                # Secret detection configs
│   └── secret-rotation/                 # Secret rotation scripts
├── SETUP_GITHUB_PAGES.md                # GitHub Pages setup
├── Taskfile.yml                         # Alternative task runner
├── terraform/
│   ├── aws-ecs/                         # AWS ECS Terraform modules
│   ├── aws-eks/                         # AWS EKS Terraform modules
│   ├── aws-lambda/                      # AWS Lambda Terraform modules
│   ├── azure-aks/                       # Azure AKS Terraform modules
│   ├── azure-app-service/               # Azure App Service Terraform modules
│   ├── gcp-gke/                         # GCP GKE Terraform modules
│   ├── README.md                        # Terraform usage and docs
│   ├── tests/                           # Terraform test modules
│   ├── _bootstrap/                      # Bootstrap Terraform configs
│   └── _testing/                        # Terraform testing utilities
├── website/
│   ├── index.html                       # Website entry point
│   ├── package.json                     # Website dependencies
│   ├── public/                          # Website static assets
│   ├── README.md                        # Website usage and docs
│   ├── scripts/                         # Website scripts
│   ├── src/                             # Website source code
│   ├── tsconfig.json                    # Website TypeScript config
│   └── vite.config.ts                   # Website Vite config
└── _README.md                           # Legacy/alternate readme
```

---

> This document is auto-generated. For the most up-to-date structure, run a recursive directory listing and update this file as needed.
