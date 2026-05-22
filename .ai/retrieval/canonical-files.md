# Canonical Files

Primary files and directories that should be consulted first for most tasks.

## Repository-Level Canonical Files

- README.md: Primary repository purpose, capabilities, and quick links.
- GETTING_STARTED.md: Fast path from need to file.
- docs/ARCHITECTURE_DECISION_GUIDE.md: Canonical decision matrix.
- docs/golden-paths/: End-to-end preferred workflows.

## Domain Canonical Files

- CI/CD:
  - ci/README.md
  - cd/README.md
  - cd/targets/<platform>/
  - ci/github-actions/_shared/
- Infrastructure:
  - terraform/README.md
  - terraform/<target>/
  - cd/pulumi/README.md
- Kubernetes and runtime delivery:
  - cd/kubernetes/README.md
  - cd/helm/README.md
  - cd/gitops/argocd/
  - cd/gitops/flux/
- Security and policy:
  - security/README.md
  - policy/README.md
  - secops/README.md
- Cost governance:
  - finops/README.md
  - finops/docs/
  - finops/policies/
- Observability:
  - observability/README.md
  - notifications/

## Canonical Runbook Areas

- secops/runbooks/: Incident response runbooks.
- docs/runbooks/: Supporting operations and procedures.

## Canonical Selection Rules

- Prefer README and top-level decision guides before deep file reads.
- Prefer golden paths for implementation tasks.
- Prefer target-specific folders only after domain and architecture are identified.
- Prefer reusable shared templates before stack-specific one-off templates.
