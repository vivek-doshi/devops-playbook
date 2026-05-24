# Architecture Overview

## System-Level Architecture

This repository is organized as a reference architecture for software delivery lifecycle controls.
It spans development, build, test, security scanning, deployment, runtime operations, reliability engineering, service ownership governance, incident response, and cost optimization.

## High-Level Layers

### 1. Build And Packaging Layer

- docker/ defines production and development image patterns.
- compose/ and local-dev/ provide reproducible local runtime environments.

### 2. Continuous Integration Layer

- ci/ contains platform-specific pipeline templates.
- quality/ and ci-security/ provide linting, testing, SAST, dependency, IaC, and container scanning integrations.

### 3. Delivery And Deployment Layer

- cd/ contains deployment targets for cloud platforms, Kubernetes manifests, Helm charts, and GitOps definitions.
- terraform/ and cd/pulumi/ provide infrastructure provisioning blueprints.

### 4. Runtime Governance Layer

- policy/ and secops/ define policy enforcement and runtime security operations.
- observability/ and notifications/ define telemetry collection, SLO alerting, and incident routing.

### 5. Service Ownership And Reliability Layer

- catalog/ defines Git-native service and team inventory, ownership metadata, and routing details.
- observability/prometheus/slos/, recording-rules/, and alerts/ implement SLO-driven operations.
- docs/runbooks/ and docs/golden-paths/ provide breach response and reliability workflows.

### 6. Cost And Operational Excellence Layer

- finops/ provides label governance, budget alerts, rightsizing analysis, reserved-capacity planning, cross-cloud normalization, dashboards, and CI/CD cost estimation patterns.

## Reference Flow

1. Choose a golden path and baseline templates.
2. Build and test with CI templates and quality controls.
3. Apply security and policy checks pre-deploy.
4. Provision or update infrastructure via Terraform or Pulumi.
5. Deploy workloads through CD targets or GitOps.
6. Register/validate service ownership metadata in catalog.
7. Operate with observability, SLO runbooks, security runbooks, and FinOps controls.

## Canonical Source Areas

- docs/ for architectural and procedural guidance.
- cd/, ci/, terraform/, ci-security/, secops/, finops/, catalog/ for executable patterns.
