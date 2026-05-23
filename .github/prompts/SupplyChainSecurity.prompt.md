---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Generate a complete supply chain security implementation: Cosign image signing, SLSA provenance, SBOM generation, Kyverno admission policies, and the golden path guide — wired end-to-end into existing CI/CD patterns in this repo.'
---

# Supply Chain Security Implementation Generator

You are a senior platform security engineer with deep expertise in SLSA, Sigstore, and Kubernetes admission control. Your task is to generate a complete, production-grade supply chain security implementation for this repository.

## Mandatory context reads (do these before writing any file)

Read these files first — your output must be consistent with the patterns they establish:

- `secops/supply-chain/cosign-verify-policy.yaml` — existing Kyverno image signature policy; extend, do not replace
- `secops/supply-chain/slsa-verify.yaml` — existing SLSA provenance policy; extend, do not replace
- `secops/supply-chain/sbom-policy.yaml` — existing SBOM attestation policy; extend, do not replace
- `ci/github-actions/_shared/reusable-docker-build.yml` — understand the existing build pattern; your signing workflow hooks into this
- `ci/github-actions/_shared/reusable-security-scan.yml` — mirror this file's structure and header format exactly
- `ci-security/container-scanning/trivy-scan.yml` — understand how SARIF upload is done; your SBOM workflow follows this pattern
- `cd/kubernetes/_base/deployment.yaml` — your policies enforce standards shown here
- `policy/kyverno/README.md` — understand how Kyverno docs are structured
- `docs/golden-paths/kubernetes-microservice.md` — mirror the golden path format exactly (prerequisites table, flow diagram, step structure, guardrails table, responsibilities table)
- `.github/copilot-instructions.md` — follow all repo-level authoring rules
- `.ai/instructions/engineering-principles.md` — apply all principles
- `.ai/instructions/security-rules.md` — apply all security rules
- `.ai/context/terminology.md` — use canonical terms

## What you are building

A complete supply chain security system with three layers:

1. **CI layer** — sign images, generate SBOM, record SLSA provenance as part of every build
2. **Admission layer** — Kyverno policies that verify signatures, SBOM, and SLSA before any workload runs
3. **Golden path** — an end-to-end guide that connects both layers for teams adopting this

## Your deliverables

### 1. `ci/github-actions/_shared/reusable-supply-chain.yml`

A reusable GitHub Actions workflow called by any image-building pipeline. It runs after the Docker image is pushed and performs three jobs in sequence.

**Job 1: sign-image**

Uses `sigstore/cosign-installer` at a pinned version. Signs the image using keyless signing with GitHub OIDC. Records the signature in the Sigstore Rekor transparency log. References `ci/github-actions/_shared/reusable-docker-build.yml` as the caller pattern — use the same `image-name` and `image-tag` inputs. Requires `id-token: write` permission. Add a comment explaining that keyless signing means no private key is stored anywhere — the certificate is short-lived and tied to the GitHub Actions OIDC identity.

**Job 2: generate-sbom**

Uses `anchore/sbom-action` at a pinned version to generate an SBOM in SPDX-JSON format. Attaches the SBOM as a cosign attestation using `cosign attest --type spdx`. Uploads the raw SBOM as a workflow artifact for audit purposes. Adds a comment explaining why SPDX-JSON was chosen over CycloneDX for this repo (Kyverno's `sbom-policy.yaml` expects the `https://spdx.dev/Document` predicate type).

**Job 3: generate-slsa-provenance**

Uses `slsa-framework/slsa-github-generator` at a pinned SHA (never a floating tag — add a comment explaining why SHAs are required for supply chain tools). Generates SLSA Level 3 provenance. Attaches provenance as a cosign attestation. Records in Rekor.

**Header**: Follow the exact TEMPLATE/WHEN TO USE/PREREQUISITES/SECRETS NEEDED/WHAT TO CHANGE/RELATED FILES/MATURITY header format used in `ci-security/container-scanning/trivy-scan.yml`. Mark MATURITY as Stable.

**All versions must be pinned to specific SHAs or tags. Add a comment on each: `# <-- UPDATE QUARTERLY`.**

### 2. `ci/github-actions/_shared/reusable-supply-chain-verify.yml`

A lightweight verification workflow that runs on pull requests to check that a referenced image (e.g. a base image being updated) already has a valid signature before it is used. Uses `cosign verify` with the expected certificate identity and OIDC issuer. Fails the PR if verification fails. Includes a `soft-fail` input that allows teams to start in audit mode. Add a comment explaining the relationship between this workflow and the Kyverno admission policies — CI verification is a shift-left check; Kyverno is the enforcement gate.

### 3. `ci/github-actions/dotnet/supply-chain-integration.yml`

A concrete example showing how to wire the reusable supply chain workflow into an existing pipeline. Calls `reusable-docker-build.yml` first, then calls `reusable-supply-chain.yml` using `needs:`. Add `# <-- COPY THIS PATTERN` comments at each integration point. Include a section comment: "Repeat this pattern for python, java, go, node — only the build step changes."

### 4. Update `secops/supply-chain/cosign-verify-policy.yaml`

Add a `ClusterPolicy` named `verify-image-signature-namespace-report` that generates a `PolicyReport` summary per namespace showing which pods have compliant vs non-compliant images. This is audit reporting, not enforcement — mode is always `Audit`. Add a comment: "Use `kubectl get policyreport -A` to see compliance across all namespaces. Wire this to a Grafana dashboard using the kube-state-metrics PolicyReport metrics."

Do not remove or change any existing rules. Add only.

### 5. `secops/supply-chain/supply-chain-status.yaml`

A Kubernetes `CronJob` that runs weekly and generates a supply chain compliance report. It uses `kubectl` to query `PolicyReport` resources across all namespaces and outputs a structured JSON summary. Stores the report in a `ConfigMap` named `supply-chain-compliance-report` in the `secops` namespace. Adds a comment explaining how to view the report: `kubectl get configmap supply-chain-compliance-report -n secops -o jsonpath='{.data.report}'`. Uses the `ci-deployer` RBAC role as a reference for what permissions the CronJob service account needs. Mark with `# <-- CHANGE THIS` on the image reference.

### 6. `docs/golden-paths/supply-chain-security.md`

A complete golden path in the exact format of `docs/golden-paths/kubernetes-microservice.md`.

**When to use this path**: teams building container images that deploy to Kubernetes and need to satisfy supply chain security requirements (SOC 2 CC6.8, SLSA Level 2+, or internal image provenance policies).

**Not the right path**: cross-reference `kubernetes-microservice.md` Step 5 for teams who only need basic container scanning without full provenance.

**Prerequisites table**: list cosign CLI, GitHub Actions OIDC federation already configured (link to `docs/guides/github-actions-oidc.md`), Kyverno installed (link to `policy/kyverno/README.md`).

**Flow**:
```
code commit → build image → sign image (cosign keyless)
           → generate SBOM (spdx-json) → attach SBOM attestation
           → generate SLSA provenance → attach provenance attestation
           → push all to registry → Kyverno verifies at admission
           → PolicyReport records compliance
```

**Steps** (numbered, each with the exact file to copy/edit):

1. Configure OIDC federation (link to `docs/guides/github-actions-oidc.md` — required first)
2. Install Kyverno and apply supply chain policies (files: `secops/supply-chain/`)
3. Wire `reusable-supply-chain.yml` into your build pipeline (example: `ci/github-actions/dotnet/supply-chain-integration.yml`)
4. Start in audit mode: apply namespace label `policy.kyverno.io/supply-chain=audit`
5. Verify signatures are being recorded: `cosign verify <image> --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' --certificate-oidc-issuer https://token.actions.githubusercontent.com`
6. Check SBOM attestation: `cosign verify-attestation --type spdx <image>`
7. Check SLSA provenance: `cosign verify-attestation --type slsaprovenance <image>`
8. Graduate to enforce mode: remove the audit label from the namespace
9. Monitor compliance: `kubectl get policyreport -A`

**Guardrails table** (matching the format in `kubernetes-microservice.md`):

| Rule | Enforced by |
|---|---|
| No unsigned images in production | `cosign-verify-policy.yaml` (Enforce mode) |
| No images without SBOM in production | `sbom-policy.yaml` (Enforce mode) |
| No images without SLSA provenance in production | `slsa-verify.yaml` (Enforce mode) |
| Supply chain tool versions pinned to SHA | Code review + `reusable-supply-chain.yml` |
| Keyless signing only — no private keys stored | OIDC-only workflow design |
| Audit mode available for migration | Namespace label `policy.kyverno.io/supply-chain=audit` |

**Responsibilities table**: Developer (wires workflow, validates attestations), Platform team (Kyverno install, policy graduation), Security team (policy review, Rekor monitoring).

**Related paths**: link to `kubernetes-microservice.md` Step 5, `platform-onboarding.md` Step 7, `docs/guides/secrets-management.md`.

### 7. `secops/supply-chain/README.md`

Update the existing README to include:
- A table showing all three policies, their enforcement modes, and the namespace label to use for audit mode
- The verification commands for each attestation type (signature, SBOM, SLSA)
- How to interpret `kubectl get policyreport -A` output
- The quarterly update cadence for pinned tool versions and where those pins live
- Link to the new golden path

### 8. Update `GETTING_STARTED.md`

Add a new row under the "🔒 I need security scanning" section:

| Supply chain security (signing, SBOM, SLSA) | [`docs/golden-paths/supply-chain-security.md`](docs/golden-paths/supply-chain-security.md) |

## Style rules

- Every YAML file must use the TEMPLATE header format from `ci-security/container-scanning/trivy-scan.yml`
- Every `# <-- CHANGE THIS` comment must explain *what* to change and *why*, not just flag the line
- Pin every external action to a specific version tag or SHA — never `@latest` or `@main` for supply chain tools (add an explicit comment explaining this)
- All cosign commands must include `--certificate-identity-regexp` and `--certificate-oidc-issuer` flags — bare `cosign verify <image>` is never acceptable (add a comment explaining the risk)
- Namespace label patterns must match exactly what is already in `cosign-verify-policy.yaml`
- The golden path must reference concrete file paths — no vague references like "your security config"
- MATURITY badges must match the convention: Stable for the policies (already exist), Beta for the new CronJob
