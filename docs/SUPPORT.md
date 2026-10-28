# Support boundary

This repository is a **reference-template library**, not a turnkey production platform. Assets labelled `TEMPLATE`, placeholder domains, example credentials, and `my-*` names require an owning team to configure and validate them before deployment.

Supported repository contracts are the checks in `.github/workflows/repo-quality.yml` and `.github/workflows/golden-path.yml`: the Kubernetes base/overlay, the `webapp` chart, Terraform configuration syntax, catalog schema, policy contracts, alert runbook links, and documented version baseline.

Cloud account provisioning, real application images, external alert endpoints, and organization-specific identity configuration are intentionally outside this repository's support boundary.
