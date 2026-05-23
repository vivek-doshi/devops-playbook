# Golden Path - Supply Chain Security

> **An opinionated, end-to-end workflow that guides developers from idea -> production**

---

## When to use this path

- You are building container images for Kubernetes workloads.
- You must satisfy supply chain controls such as SOC 2 CC6.8, SLSA Level 2+, or internal provenance policy.
- You want signing, SBOM, provenance, and admission verification wired as a standard path.

Not the right path? See [Kubernetes Microservice](kubernetes-microservice.md) Step 5 if you only need baseline container scanning without full provenance attestations.

---

## Prerequisites

| Requirement | Why it is required | Reference |
|---|---|---|
| cosign CLI | Verify signatures and attestations locally | https://docs.sigstore.dev/cosign/installation/ |
| GitHub Actions OIDC federation configured | Required before keyless signing can mint OIDC-backed certificates | [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md) |
| Kyverno installed in cluster | Admission verification and PolicyReport compliance output | [policy/kyverno/README.md](../../policy/kyverno/README.md) |

---

## Flow

```text
code commit -> build image -> sign image (cosign keyless)
           -> generate SBOM (spdx-json) -> attach SBOM attestation
           -> generate SLSA provenance -> attach provenance attestation
           -> push all to registry -> Kyverno verifies at admission
           -> PolicyReport records compliance
```

---

## Step 1 - Configure OIDC federation

Complete OIDC setup first. Without this, keyless signing cannot issue short-lived signing certificates.

Guide: [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md)

---

## Step 2 - Install Kyverno and apply supply chain policies

Apply the policy bundle from [secops/supply-chain/](../../secops/supply-chain/):

- [secops/supply-chain/cosign-verify-policy.yaml](../../secops/supply-chain/cosign-verify-policy.yaml)
- [secops/supply-chain/sbom-policy.yaml](../../secops/supply-chain/sbom-policy.yaml)
- [secops/supply-chain/slsa-verify.yaml](../../secops/supply-chain/slsa-verify.yaml)

```bash
kubectl apply -f secops/supply-chain/
```

---

## Step 3 - Wire reusable supply chain workflow into pipeline

Use the integration example at [ci/github-actions/dotnet/supply-chain-integration.yml](../../ci/github-actions/dotnet/supply-chain-integration.yml), then repeat by stack.

Reusable workflows:
- [ci/github-actions/_shared/reusable-supply-chain.yml](../../ci/github-actions/_shared/reusable-supply-chain.yml)
- [ci/github-actions/_shared/reusable-supply-chain-verify.yml](../../ci/github-actions/_shared/reusable-supply-chain-verify.yml)

---

## Step 4 - Start in audit mode

Label namespaces for migration-safe rollout:

```bash
kubectl label namespace <namespace> policy.kyverno.io/supply-chain=audit --overwrite
```

---

## Step 5 - Verify signature is recorded

```bash
cosign verify <image> \
  --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

---

## Step 6 - Verify SBOM attestation

```bash
cosign verify-attestation \
  --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --type spdx <image>
```

---

## Step 7 - Verify SLSA provenance

```bash
cosign verify-attestation \
  --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --type slsaprovenance <image>
```

---

## Step 8 - Graduate to enforce mode

Remove the audit label after violations are remediated:

```bash
kubectl label namespace <namespace> policy.kyverno.io/supply-chain-
```

---

## Step 9 - Monitor compliance

```bash
kubectl get policyreport -A
```

Also deploy the weekly reporter at [secops/supply-chain/supply-chain-status.yaml](../../secops/supply-chain/supply-chain-status.yaml).

---

## Guardrails

| Rule | Enforced by |
|---|---|
| No unsigned images in production | `cosign-verify-policy.yaml` (Enforce mode) |
| No images without SBOM in production | `sbom-policy.yaml` (Enforce mode) |
| No images without SLSA provenance in production | `slsa-verify.yaml` (Enforce mode) |
| Supply chain tool versions pinned to SHA | Code review + `reusable-supply-chain.yml` |
| Keyless signing only - no private keys stored | OIDC-only workflow design |
| Audit mode available for migration | Namespace label `policy.kyverno.io/supply-chain=audit` |

---

## Responsibilities

| Role | Responsibilities |
|---|---|
| Developer | Wires the reusable workflow and validates signature/SBOM/provenance attestations |
| Platform team | Installs Kyverno, applies policies, and graduates namespaces from audit to enforce |
| Security team | Reviews policy changes, monitors Rekor-backed verification posture, and tracks compliance |

---

## Related paths

- [Kubernetes Microservice](kubernetes-microservice.md) Step 5 - baseline scanning path.
- [Platform Onboarding](platform-onboarding.md) Step 7 - team platform enablement sequence.
- [docs/guides/secrets-management.md](../guides/secrets-management.md) - secret handling baseline.
