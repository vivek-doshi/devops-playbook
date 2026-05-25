# Concepts Guide

This guide explains the core concepts used across this repository, from beginner to intermediate depth.

Use this as a companion to:
- [README.md](../../README.md)
- [docs/golden-paths/](../golden-paths/)
- [docs/runbooks/](../runbooks/)
- [docs/decisions/](../decisions/)

## Repository Website

- Deployed playbook viewer: [DevOps Playbook Viewer](https://vivek-doshi.github.io/devops-playbook/)
- Source for the viewer app: [website/](../../website/)

## How To Read This Guide

Each section uses this structure:
- What it is: Plain-language definition.
- Why it matters: Practical reason teams adopt it.
- Beginner view: What to do first.
- Intermediate view: How to scale or harden the practice.
- Where in this repo: Concrete file and folder pointers.

---

## 1) Repository-Wide Mental Model

This repository models a complete engineering lifecycle:

1. Build app artifacts (containers, packages, binaries).
2. Validate quality locally (pre-commit) before push.
3. Run CI checks (tests, lint, security scans).
4. Provision infrastructure (Terraform and Pulumi).
5. Deploy workloads (Kubernetes, serverless, app platforms).
6. Manage configuration with GitOps and overlays.
7. Protect secrets and identity with cloud-native patterns.
8. Enforce policy and governance continuously.
9. Observe reliability (metrics, logs, traces, alerts).
10. Operate with runbooks and incident workflows.
11. Manage ownership with service catalog and CODEOWNERS.
12. Optimize cost with FinOps governance and feedback loops.

Where in this repo:
- [docker/](../../docker/)
- [ci/](../../ci/)
- [cd/](../../cd/)
- [terraform/](../../terraform/)
- [observability/](../../observability/)
- [secops/](../../secops/)
- [catalog/](../../catalog/)
- [finops/](../../finops/)

---

## 2) Source Control, Team Flow, And Release Basics

### Branching strategy
What it is: A rule set for how teams create, merge, and protect branches.

Why it matters: Reduces merge chaos and release risk.

Beginner view:
- Use short-lived feature branches.
- Keep main branch always deployable.

Intermediate view:
- Add branch protection rules and required checks.
- Use release branches only when your release cadence requires them.

Where in this repo:
- [docs/guides/branching-strategy.md](branching-strategy.md)

### Conventional commits
What it is: Commit message format like feat, fix, chore, docs.

Why it matters: Improves changelog generation and release automation.

Beginner view:
- Use clear prefixes and concise scope.

Intermediate view:
- Drive automated semantic versioning from commit types.

Where in this repo:
- [docs/guides/conventional-commits.md](conventional-commits.md)

### Versioning strategy
What it is: Rules for incrementing versions using semantic versioning.

Why it matters: Communicates compatibility and upgrade risk.

Beginner view:
- Use MAJOR.MINOR.PATCH consistently.

Intermediate view:
- Align release tags with pipeline promotion gates.

Where in this repo:
- [docs/guides/versioning-strategy.md](versioning-strategy.md)
- [scripts/tag-release.sh](../../scripts/tag-release.sh)

---

## 3) Local Developer Experience (DevEx)

### Dev container
What it is: A reproducible development environment in a container.

Why it matters: Removes machine drift and onboarding friction.

Beginner view:
- Open in container and use the pinned toolchain.

Intermediate view:
- Keep language and CLI versions pinned and reviewed quarterly.

Where in this repo:
- [.devcontainer/devcontainer.json](../../.devcontainer/devcontainer.json)
- [.devcontainer/Dockerfile](../../.devcontainer/Dockerfile)
- [.devcontainer/scripts/post-create.sh](../../.devcontainer/scripts/post-create.sh)

### Task runners and command orchestration
What it is: Standardized commands through Makefile and Taskfile.

Why it matters: Teams run the same commands the same way.

Beginner view:
- Use predefined targets instead of ad hoc shell commands.

Intermediate view:
- Add guard tasks that verify required CLIs before execution.

Where in this repo:
- [Makefile](../../Makefile)
- [Taskfile.yml](../../Taskfile.yml)

---

## 4) Pre-Commit, Linting, And Quality Gates

### Pre-commit hooks
What it is: Local checks that run before commit or push.

Why it matters: Catches fast failures early and keeps CI cleaner.

Beginner view:
- Install hooks and run all hooks before opening a PR.

Intermediate view:
- Pin hook versions, separate commit-time and push-time checks, and document skip policies.

Where in this repo:
- [.pre-commit-config.yaml](../../.pre-commit-config.yaml)
- [docs/guides/pre-commit-setup.md](pre-commit-setup.md)

### Linting and formatting
What it is: Automated style and static checks for code and configs.

Why it matters: Improves readability and reduces avoidable defects.

Beginner view:
- Run language linters and fix warnings that indicate correctness issues.

Intermediate view:
- Centralize linter config and align local and CI rules.

Where in this repo:
- [quality/](../../quality/)
- [quality/python/pyproject.toml](../../quality/python/pyproject.toml)

### Type checking
What it is: Validation of types before runtime.

Why it matters: Prevents a broad class of integration bugs.

Beginner view:
- Add type hints on public interfaces first.

Intermediate view:
- Raise strictness gradually and fail CI on type regressions.

Where in this repo:
- [quality/python/pyproject.toml](../../quality/python/pyproject.toml)

---

## 5) CI Concepts

### Continuous Integration (CI)
What it is: Automated build, test, and scan on every change.

Why it matters: Ensures shared quality gates before merge.

Beginner view:
- Build once, test fast, fail fast.

Intermediate view:
- Add matrix builds, artifact reuse, and conditional workflows for speed.

Where in this repo:
- [ci/](../../ci/)
- [ci/github-actions/](../../ci/github-actions/)
- [ci/azure-pipelines/](../../ci/azure-pipelines/)
- [ci/gitlab-ci/](../../ci/gitlab-ci/)
- [ci/jenkins/](../../ci/jenkins/)

### Pipeline parity
What it is: Equivalent pipeline patterns across multiple CI platforms.

Why it matters: Lets teams switch platforms with minimal process change.

Beginner view:
- Keep build and test steps conceptually identical across providers.

Intermediate view:
- Maintain reusable templates and shared naming conventions across systems.

Where in this repo:
- [ci/README.md](../../ci/README.md)

---

## 6) Shift-Left Security Concepts

### Secret detection
What it is: Scanning code and history for credential leaks.

Why it matters: Prevents long-lived credential exposure.

Beginner view:
- Treat every hit as potentially real until triaged.

Intermediate view:
- Combine local pre-commit checks with CI enforcement and incident playbooks.

Where in this repo:
- [ci-security/secret-detection/](../../ci-security/secret-detection/)

### SAST (Static Application Security Testing)
What it is: Code analysis for insecure patterns without running the app.

Why it matters: Finds common vulnerabilities early in development.

Beginner view:
- Start with high-severity issues and known risky sinks.

Intermediate view:
- Tune rules to reduce noise and enforce policy thresholds.

Where in this repo:
- [ci-security/sast/](../../ci-security/sast/)

### Dependency scanning
What it is: Scanning libraries for known CVEs and risky versions.

Why it matters: Most app risk enters through dependencies.

Beginner view:
- Patch critical vulnerabilities first.

Intermediate view:
- Add policy for maximum CVSS and exploitability windows.

Where in this repo:
- [ci-security/dependency-audit/](../../ci-security/dependency-audit/)

### Container scanning
What it is: Vulnerability scanning of container images and layers.

Why it matters: Base image risk ships directly into runtime.

Beginner view:
- Scan every image in CI before publish.

Intermediate view:
- Gate deployment by severity, fixed-version availability, and image age.

Where in this repo:
- [ci-security/container-scanning/](../../ci-security/container-scanning/)

### IaC scanning
What it is: Security and policy checks against Terraform and Kubernetes manifests.

Why it matters: Prevents insecure infrastructure before creation.

Beginner view:
- Fail on critical issues.

Intermediate view:
- Map checks to compliance controls and exception workflows.

Where in this repo:
- [ci-security/iac-scanning/](../../ci-security/iac-scanning/)

---

## 7) Infrastructure As Code (IaC) Concepts

### Terraform modules and environments
What it is: Declarative cloud resources defined as code.

Why it matters: Reproducible provisioning and reviewable changes.

Beginner view:
- Separate reusable modules from environment-specific variables.

Intermediate view:
- Add remote state, state locking, workspace strategy, and policy checks.

Where in this repo:
- [terraform/](../../terraform/)
- [terraform/_bootstrap/](../../terraform/_bootstrap/)
- [terraform/_testing/](../../terraform/_testing/)

### Pulumi
What it is: IaC using general-purpose languages instead of only HCL.

Why it matters: Useful when teams prefer language-native abstractions.

Beginner view:
- Start with simple stacks and explicit config.

Intermediate view:
- Use stack references, policy packs, and environment promotion flows.

Where in this repo:
- [cd/pulumi/](../../cd/pulumi/)

---

## 8) Deployment Concepts

### Continuous Delivery (CD)
What it is: Automated promotion of validated artifacts to environments.

Why it matters: Reduces manual deployment risk and lead time.

Beginner view:
- Use dev, staging, and production separation.

Intermediate view:
- Add environment-specific approvals and progressive delivery controls.

Where in this repo:
- [cd/](../../cd/)
- [cd/targets/](../../cd/targets/)

### Promotion strategy
What it is: A consistent path from lower to higher environments.

Why it matters: Ensures artifacts are tested in realistic stages.

Beginner view:
- Promote the same artifact, do not rebuild per environment.

Intermediate view:
- Add immutable artifact attestations and provenance checks.

Where in this repo:
- [docs/guides/environment-strategy.md](environment-strategy.md)

---

## 9) Kubernetes Packaging And Configuration

### Kubernetes manifests
What it is: YAML resources that define desired cluster state.

Why it matters: Core deployment model for containerized workloads.

Beginner view:
- Understand Deployment, Service, ConfigMap, Secret, Ingress.

Intermediate view:
- Use probes, limits, PDBs, and disruption-aware rollout strategies.

Where in this repo:
- [cd/kubernetes/](../../cd/kubernetes/)

### Kustomize overlays
What it is: Layered patching of base manifests per environment.

Why it matters: Keeps shared defaults while allowing safe env customization.

Beginner view:
- Use one base and separate overlays for dev, staging, prod.

Intermediate view:
- Add reusable patch patterns and policy-driven labels/annotations.

Where in this repo:
- [cd/kubernetes/_base/](../../cd/kubernetes/_base/)
- [cd/kubernetes/_overlays/](../../cd/kubernetes/_overlays/)
- [cd/kubernetes/_patterns/](../../cd/kubernetes/_patterns/)

### Helm charts
What it is: Templated Kubernetes packaging for reusable releases.

Why it matters: Better for reusable distributions and parameterized deployments.

Beginner view:
- Use values files and avoid over-templating.

Intermediate view:
- Add chart tests, schema validation, and version discipline.

Where in this repo:
- [cd/helm/](../../cd/helm/)
- [cd/helm/webapp/](../../cd/helm/webapp/)
- [cd/helm/microservice/](../../cd/helm/microservice/)

### Helm vs Kustomize
What it is: Two valid but different approaches to manifest management.

Why it matters: Teams need consistent choice per application.

Beginner view:
- Pick one approach per app and stay consistent.

Intermediate view:
- Standardize platform guidance for when each approach is preferred.

Where in this repo:
- [docs/decisions/ADR-002-helm-vs-kustomize.md](../decisions/ADR-002-helm-vs-kustomize.md)

---

## 10) GitOps Concepts

### GitOps core principles
What it is: Declarative state in Git, pull-based reconciliation by controllers.

Why it matters: Auditability, drift correction, and predictable rollouts.

Beginner view:
- Keep desired state in Git and avoid manual cluster edits.

Intermediate view:
- Add health checks, sync windows, and rollback conventions.

Where in this repo:
- [cd/gitops/](../../cd/gitops/)
- [docs/decisions/ADR-003-gitops-strategy.md](../decisions/ADR-003-gitops-strategy.md)

### Argo CD and Flux
What it is: Controllers that reconcile cluster state from Git.

Why it matters: Automates deployment and drift remediation.

Beginner view:
- Start with one GitOps controller per platform.

Intermediate view:
- Adopt app-of-apps or fleet patterns for multi-cluster scale.

Where in this repo:
- [cd/gitops/argocd/](../../cd/gitops/argocd/)
- [cd/gitops/flux/](../../cd/gitops/flux/)
- [cd/fleet-overlays/](../../cd/fleet-overlays/)

---

## 11) Identity, Secrets, And Access Concepts

### OIDC federation for CI
What it is: Workload identity federation from CI to cloud providers.

Why it matters: Removes long-lived cloud credentials from CI secrets.

Beginner view:
- Use short-lived cloud tokens issued by trusted identity providers.

Intermediate view:
- Scope trust policies by branch, repo, and environment claims.

Where in this repo:
- [docs/guides/github-actions-oidc.md](github-actions-oidc.md)

### Secrets lifecycle management
What it is: Provision, rotate, audit, and retire secrets safely.

Why it matters: Credential leakage and stale access are common breach vectors.

Beginner view:
- Never commit plaintext secrets.

Intermediate view:
- Implement scheduled rotation and emergency rollback playbooks.

Where in this repo:
- [secrets/](../../secrets/)
- [docs/guides/secrets-management.md](secrets-management.md)
- [secrets/guides/](../../secrets/guides/)

### External Secrets Operator
What it is: Synchronizes cloud/Vault secrets into Kubernetes resources.

Why it matters: Keeps source of truth in secret managers, not Git.

Beginner view:
- Use ESO for runtime injection of app credentials.

Intermediate view:
- Tune refresh intervals by secret volatility and rotation policy.

Where in this repo:
- [secrets/external-secrets/](../../secrets/external-secrets/)

---

## 12) Policy As Code And Governance Concepts

### Policy as code
What it is: Machine-enforced governance rules authored in versioned code.

Why it matters: Prevents unsafe changes before they become incidents.

Beginner view:
- Start with audit mode to understand current violations.

Intermediate view:
- Move selected policies to enforce mode with exception process.

Where in this repo:
- [policy/](../../policy/)

### Kyverno admission policies
What it is: Kubernetes admission rules for validation and mutation.

Why it matters: Enforces security, compliance, and cost controls at deploy time.

Beginner view:
- Enforce required labels, resource limits, and secret guardrails.

Intermediate view:
- Add policy reports, staged rollout, and namespace-scoped enforcement strategies.

Where in this repo:
- [policy/kyverno/](../../policy/kyverno/)
- [finops/policies/](../../finops/policies/)

### Conftest and OPA
What it is: Policy checks for files in CI before cluster admission.

Why it matters: Catches policy violations earlier than runtime admission.

Beginner view:
- Validate manifests and IaC in pull requests.

Intermediate view:
- Share policy bundles across repositories and pipelines.

Where in this repo:
- [policy/conftest/](../../policy/conftest/)

---

## 13) SecOps Concepts

### Runtime security
What it is: Detection and response for threats in live environments.

Why it matters: Some attacks only appear after deployment.

Beginner view:
- Monitor suspicious process, network, and filesystem behavior.

Intermediate view:
- Integrate runtime detections with SIEM and incident runbooks.

Where in this repo:
- [secops/runtime/](../../secops/runtime/)
- [secops/runbooks/](../../secops/runbooks/)

### Compliance as code
What it is: Mapped controls, evidence scripts, and automated scoring.

Why it matters: Turns audits into continuous engineering practice.

Beginner view:
- Track implemented controls and evidence sources.

Intermediate view:
- Add CI fail thresholds and control traceability in policies.

Where in this repo:
- [secops/compliance/](../../secops/compliance/)

### Security operations runbooks
What it is: Step-by-step response procedures for incidents.

Why it matters: Improves consistency and response time during outages or breaches.

Beginner view:
- Follow runbook flow rather than inventing ad hoc response.

Intermediate view:
- Add post-incident reviews and measurable action items.

Where in this repo:
- [docs/runbooks/](../runbooks/)
- [secops/runbooks/](../../secops/runbooks/)

---

## 14) Supply Chain Security Concepts

### Software supply chain
What it is: Everything from source code to built artifact to deployed workload.

Why it matters: Tampering can occur at build, dependency, or registry layers.

Beginner view:
- Pin dependencies and trusted base images.

Intermediate view:
- Add provenance, signatures, and policy-based verification.

Where in this repo:
- [secops/supply-chain/](../../secops/supply-chain/)

### SBOM (Software Bill of Materials)
What it is: Inventory of components included in an artifact.

Why it matters: Enables vulnerability impact analysis and compliance traceability.

Beginner view:
- Generate SBOM per build artifact.

Intermediate view:
- Store SBOMs with artifacts and include them in release evidence.

Where in this repo:
- [secops/supply-chain/](../../secops/supply-chain/)

### Artifact signing and verification
What it is: Cryptographic signing of images and verification at deploy time.

Why it matters: Ensures artifacts are authentic and untampered.

Beginner view:
- Sign release images and verify signatures in CI/CD.

Intermediate view:
- Enforce keyless signature verification through admission policies.

Where in this repo:
- [secops/supply-chain/](../../secops/supply-chain/)

### Provenance and SLSA-style controls
What it is: Evidence of how, where, and from what source artifacts were built.

Why it matters: Detects untrusted build paths and unauthorized release flows.

Beginner view:
- Use trusted CI and immutable build logs.

Intermediate view:
- Enforce provenance requirements in policy and promotion workflows.

Where in this repo:
- [secops/supply-chain/](../../secops/supply-chain/)

---

## 15) Observability Concepts

### The three pillars
What it is: Metrics, logs, and traces.

Why it matters: Each answers different operational questions.

Beginner view:
- Use metrics for trends, logs for details, traces for request paths.

Intermediate view:
- Correlate all three with shared labels and trace IDs.

Where in this repo:
- [observability/prometheus/](../../observability/prometheus/)
- [observability/loki/](../../observability/loki/)
- [observability/tempo/](../../observability/tempo/)
- [observability/opentelemetry/](../../observability/opentelemetry/)

### OpenTelemetry
What it is: Vendor-neutral instrumentation and telemetry pipeline standards.

Why it matters: Standardized collection across languages and backends.

Beginner view:
- Instrument core request paths and external calls.

Intermediate view:
- Use semantic conventions and sampling strategies per service tier.

Where in this repo:
- [observability/opentelemetry/](../../observability/opentelemetry/)
- [observability/otel/](../../observability/otel/)

### Alerting and notifications
What it is: Routing actionable events to response channels.

Why it matters: Monitoring without response paths has little operational value.

Beginner view:
- Route critical alerts to one on-call destination.

Intermediate view:
- Use severity routing, deduplication, and escalation policies.

Where in this repo:
- [notifications/](../../notifications/)

---

## 16) SLO And Reliability Engineering Concepts

### SLI, SLO, and SLA
What it is:
- SLI: Metric used to measure reliability.
- SLO: Target level for that metric.
- SLA: External contractual commitment.

Why it matters: Creates objective reliability targets and tradeoff decisions.

Beginner view:
- Start with one availability SLO per service.

Intermediate view:
- Add latency and correctness SLOs and error budget policies.

Where in this repo:
- [observability/prometheus/slos/](../../observability/prometheus/slos/)
- [docs/golden-paths/slo-driven-development.md](../golden-paths/slo-driven-development.md)

### Error budget
What it is: Allowed unreliability before reliability work must be prioritized.

Why it matters: Aligns product velocity with operational risk.

Beginner view:
- Track monthly burn against target.

Intermediate view:
- Define policy actions at burn thresholds and review quarterly.

Where in this repo:
- [docs/runbooks/slo-quarterly-review.md](../runbooks/slo-quarterly-review.md)

### Multi-window burn-rate alerting
What it is: Alerting on short and long windows to detect both fast and slow budget burn.

Why it matters: Reduces noise and catches meaningful degradation sooner.

Beginner view:
- Use standard burn-rate tiers as baseline.

Intermediate view:
- Tune thresholds per service criticality and historical behavior.

Where in this repo:
- [observability/prometheus/alerts/](../../observability/prometheus/alerts/)
- [observability/prometheus/recording-rules/](../../observability/prometheus/recording-rules/)

---

## 17) Service Catalog And Ownership Concepts

### Service catalog
What it is: Git-native registry of services, owners, lifecycle, and operational metadata.

Why it matters: Clarifies ownership and speeds incident routing.

Beginner view:
- Register every production service and owning team.

Intermediate view:
- Enforce registration in CI and admission policy.

Where in this repo:
- [catalog/](../../catalog/)
- [docs/golden-paths/service-catalog.md](../golden-paths/service-catalog.md)

### Team ownership and CODEOWNERS generation
What it is: Mapping teams to owned paths and review responsibilities.

Why it matters: Ensures correct reviewers and accountability.

Beginner view:
- Keep ownership files current as teams evolve.

Intermediate view:
- Generate CODEOWNERS from catalog metadata to avoid drift.

Where in this repo:
- [catalog/scripts/generate-codeowners.py](../../catalog/scripts/generate-codeowners.py)
- [.github/CODEOWNERS](../../.github/CODEOWNERS)

### Catalog validation
What it is: Schema and policy validation of service/team definitions.

Why it matters: Prevents broken ownership metadata and missing fields.

Beginner view:
- Validate every catalog change in CI.

Intermediate view:
- Add strict mode and URL/metadata checks for production-quality entries.

Where in this repo:
- [catalog/scripts/validate-catalog.py](../../catalog/scripts/validate-catalog.py)
- [.github/workflows/validate-catalog.yml](../../.github/workflows/validate-catalog.yml)

---

## 18) FinOps Concepts

### FinOps operating loop
What it is: Continuous cycle of visibility, optimization, governance, and verification.

Why it matters: Cost control becomes part of engineering, not a monthly surprise.

Beginner view:
- Measure top cost drivers first, then fix largest obvious waste.

Intermediate view:
- Run recurring optimization loops with policy guardrails and PR automation.

Where in this repo:
- [finops/](../../finops/)
- [docs/golden-paths/finops-optimization.md](../golden-paths/finops-optimization.md)

### Cost allocation and labels
What it is: Labeling resources for team, service, environment, and cost center attribution.

Why it matters: Unallocated cost cannot be governed effectively.

Beginner view:
- Enforce minimum required labels for every workload.

Intermediate view:
- Use chargeback or showback with policy and alerting.

Where in this repo:
- [finops/policies/](../../finops/policies/)

### Rightsizing
What it is: Matching CPU and memory requests/limits to actual workload usage.

Why it matters: Overprovisioning wastes budget and can hide capacity risk.

Beginner view:
- Start with non-critical namespaces and review recommended reductions.

Intermediate view:
- Automate safe patch generation with reduction caps and review gates.

Where in this repo:
- [finops/scripts/analyze-rightsizing.py](../../finops/scripts/analyze-rightsizing.py)
- [finops/scripts/generate-optimization-pr.py](../../finops/scripts/generate-optimization-pr.py)

### Infracost in CI/CD
What it is: Cost diff estimation for Terraform changes in pull requests.

Why it matters: Adds cost visibility before infrastructure merge.

Beginner view:
- Show monthly delta in PR comments.

Intermediate view:
- Add policy gates by budget thresholds or percentage increase.

Where in this repo:
- [finops/infracost/](../../finops/infracost/)
- [finops/cicd/](../../finops/cicd/)

### Budget and anomaly alerting
What it is: Alerts for threshold breaches and unusual spend behavior.

Why it matters: Early detection prevents end-of-month surprises.

Beginner view:
- Start with 80, 100, and 120 percent budget thresholds.

Intermediate view:
- Add baseline deviation alerts by workload and service class.

Where in this repo:
- [finops/prometheus/](../../finops/prometheus/)
- [finops/config/budgets.yaml](../../finops/config/budgets.yaml)

---

## 19) Backup, Recovery, And Resilience Concepts

### Disaster recovery (DR)
What it is: Plan and procedures to restore critical service after major incidents.

Why it matters: Reliability includes recovery time and data recovery guarantees.

Beginner view:
- Define RTO and RPO for critical systems.

Intermediate view:
- Run scheduled restore drills and document evidence.

Where in this repo:
- [docs/guides/disaster-recovery.md](disaster-recovery.md)
- [docs/runbooks/](../runbooks/)

### Kubernetes backup
What it is: Backup and restore of cluster resources and persistent data references.

Why it matters: Enables faster recovery from accidental deletion or corruption.

Beginner view:
- Schedule recurring backups and test restore path.

Intermediate view:
- Add namespace-scoped restore and cross-region backup strategy.

Where in this repo:
- [backup/velero/](../../backup/velero/)

### Database backup and point-in-time restore
What it is: Automated snapshots and restore to exact time windows.

Why it matters: Critical for data integrity and incident recovery.

Beginner view:
- Enable managed backup retention in each cloud.

Intermediate view:
- Validate PITR and failover procedures in regular game days.

Where in this repo:
- [backup/terraform/](../../backup/terraform/)

---

## 20) ADRs And Architectural Decision Records

### ADRs
What it is: Lightweight documents capturing why a technical decision was made.

Why it matters: Reduces repeated debates and preserves context.

Beginner view:
- Record decision, context, alternatives, and consequences.

Intermediate view:
- Keep ADRs updated when strategy evolves and link related implementation paths.

Where in this repo:
- [docs/decisions/](../decisions/)

---

## 21) Concept Progression Path (Beginner To Intermediate)

Follow this order if you are learning the platform end to end:

1. Local workflow and pre-commit.
2. CI templates and test/security gates.
3. Container build and artifact basics.
4. Infrastructure provisioning with Terraform.
5. Kubernetes packaging with Kustomize or Helm.
6. GitOps reconciliation with Argo CD or Flux.
7. Secrets and identity federation (OIDC).
8. Policy enforcement with Kyverno and Conftest.
9. Observability setup with metrics, logs, traces, and alerts.
10. SLO definition, burn-rate alerting, and error budget policy.
11. Service catalog registration and ownership automation.
12. FinOps optimization loop and cost governance.
13. Runbooks, DR drills, and continuous improvement.

---

## 22) Quick Concept Index

| Concept | Primary location |
|---|---|
| Pre-commit hooks | [.pre-commit-config.yaml](../../.pre-commit-config.yaml) |
| CI templates | [ci/](../../ci/) |
| CD targets | [cd/targets/](../../cd/targets/) |
| Terraform IaC | [terraform/](../../terraform/) |
| Pulumi IaC | [cd/pulumi/](../../cd/pulumi/) |
| Kubernetes manifests and overlays | [cd/kubernetes/](../../cd/kubernetes/) |
| Helm charts | [cd/helm/](../../cd/helm/) |
| GitOps controllers | [cd/gitops/](../../cd/gitops/) |
| SAST and dependency scans | [ci-security/](../../ci-security/) |
| Runtime security and compliance | [secops/](../../secops/) |
| Policy as code | [policy/](../../policy/) |
| Secrets lifecycle and ESO | [secrets/](../../secrets/) |
| Metrics, logs, traces | [observability/](../../observability/) |
| SLOs and burn-rate alerts | [observability/prometheus/](../../observability/prometheus/) |
| Alert routing | [notifications/](../../notifications/) |
| Service catalog and ownership | [catalog/](../../catalog/) |
| FinOps governance and automation | [finops/](../../finops/) |
| Backup and DR | [backup/](../../backup/) and [docs/runbooks/](../runbooks/) |

---

## 23) Recommended Next Reads

1. [docs/golden-paths/platform-onboarding.md](../golden-paths/platform-onboarding.md)
2. [docs/golden-paths/kubernetes-microservice.md](../golden-paths/kubernetes-microservice.md)
3. [docs/golden-paths/slo-driven-development.md](../golden-paths/slo-driven-development.md)
4. [docs/golden-paths/service-catalog.md](../golden-paths/service-catalog.md)
5. [docs/golden-paths/finops-optimization.md](../golden-paths/finops-optimization.md)

