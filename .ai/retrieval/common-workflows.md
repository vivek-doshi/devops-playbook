# Common Workflows

Standard retrieval paths for frequent engineering tasks.

## 1. Build and Deploy a Kubernetes Microservice

1. docs/golden-paths/kubernetes-microservice.md
2. docker/<stack>/Dockerfile*
3. ci/<platform>/<stack>/
4. terraform/<cloud-k8s-target>/
5. cd/targets/<cloud-k8s-target>/
6. cd/kubernetes/_base and _overlays
7. security/, policy/, finops/policies/ checks

## 2. Build and Deploy a Serverless App

1. docs/golden-paths/serverless-app.md
2. ci/<platform>/<stack>/
3. terraform/aws-lambda or cloud equivalent target
4. cd/targets/aws-lambda/
5. security/secret-detection and dependency-audit

## 3. Deliver a Frontend SPA

1. docs/golden-paths/frontend-spa.md
2. docker/react or docker/angular
3. ci/<platform>/react or angular
4. cd/targets/azure-app-service (or chosen platform)
5. observability/ and notifications/

## 4. Add Security and Compliance Gates

1. security/README.md
2. security/sast, dependency-audit, container-scanning, secret-detection
3. policy/ and secops/
4. ci templates for integration

## 5. Enable Cost Governance

1. finops/README.md
2. finops/policies/
3. finops/cicd/
4. finops/prometheus/ and finops/dashboards/
5. finops/scripts/

## 6. Incident Response Handling

1. docs/golden-paths/incident-response.md
2. secops/runbooks/
3. observability/ logs and alerts
4. notifications/ integration files
