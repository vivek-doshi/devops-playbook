# Security Rules

Security baseline for code templates, IaC, CI/CD, runtime configuration, and incident response content.

## Non-Negotiable Rules

- Security by default in every template and workflow.
- No plaintext secrets in repository files, examples, or pipeline definitions.
- Use short-lived identity federation over static long-lived credentials.
- Apply least privilege for cloud roles, service accounts, and pipeline identities.
- Block releases on critical security findings unless formally risk-accepted.

## Supply Chain Security

- Scan dependencies and containers in CI.
- Prefer signed artifacts and verify provenance where supported.
- Pin critical tool and image versions to reduce drift and unexpected breakage.
- Keep SBOM and vulnerability scanning part of the standard pipeline flow.

## Runtime Security

- Enable runtime detection and audit logging for Kubernetes workloads.
- Use baseline policy enforcement for pod security and network isolation.
- Maintain and test incident runbooks for pod compromise, node compromise, secret exposure, and supply chain incidents.

## Governance And Evidence

- Keep compliance and security controls documented and auditable.
- Route alerts to owned channels with clear severity mapping.
- Record incident timelines, evidence locations, and remediation outcomes.

## Repo Alignment

- Follow templates in security/, secops/, policy/, secrets/, and notifications/.
- Keep security checks consistent across GitHub Actions, Azure Pipelines, GitLab CI, and Jenkins templates.
