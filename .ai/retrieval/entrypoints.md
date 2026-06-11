# Entrypoints

Recommended first files to open by intent.

## Global Entrypoints

- README.md
- GETTING_STARTED.md
- docs/ARCHITECTURE_DECISION_GUIDE.md
- docs/golden-paths/

## By Task Type

- New service delivery:
  - docs/golden-paths/kubernetes-microservice.md
  - docs/golden-paths/serverless-app.md
  - docs/golden-paths/frontend-spa.md
- Pipeline setup:
  - ci/README.md
  - ci/github-actions/
  - ci/azure-pipelines/
  - ci/gitlab-ci/
- Cloud deployment:
  - cd/targets/
  - terraform/README.md
- Kubernetes patterns:
  - cd/kubernetes/README.md
  - cd/kubernetes/_base/
  - cd/kubernetes/_patterns/
- Security baseline:
  - ci-security/README.md
  - policy/README.md
  - secops/README.md
- FinOps baseline:
  - finops/README.md
  - finops/docs/

## Triage Entrypoint Order

1. docs/ARCHITECTURE_DECISION_GUIDE.md
2. matching docs/golden-paths/*
3. domain README
4. implementation template files
