# Supply Chain Security

This directory provides policy and reporting templates for image signing, SBOM attestation, and SLSA provenance verification at Kubernetes admission time.

## Policies and Modes

| Policy | Default mode | Audit mode label | Disabled mode label |
|---|---|---|---|
| [cosign-verify-policy.yaml](cosign-verify-policy.yaml) | Enforce | `policy.kyverno.io/supply-chain=audit` | `policy.kyverno.io/supply-chain=disabled` |
| [sbom-policy.yaml](sbom-policy.yaml) | Enforce | `policy.kyverno.io/sbom=audit` | `policy.kyverno.io/sbom=disabled` |
| [slsa-verify.yaml](slsa-verify.yaml) | Enforce | `policy.kyverno.io/slsa=audit` | `policy.kyverno.io/slsa=disabled` |

## Verification Commands

Always include certificate identity and issuer constraints when verifying, so trust is scoped to expected GitHub Actions identities.

```bash
# Signature verification
cosign verify <image> \
  --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# SBOM attestation verification
cosign verify-attestation --type spdx <image> \
  --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# SLSA provenance attestation verification
cosign verify-attestation --type slsaprovenance <image> \
  --certificate-identity-regexp 'https://github.com/YOUR-ORG/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Interpreting PolicyReport Output

Use:

```bash
kubectl get policyreport -A
```

Interpretation:
- `PASS` means the resource met policy conditions.
- `FAIL` means a policy violation was found (blocking only when policy mode is Enforce).
- `WARN` means a warning-level policy result.
- `ERROR` means policy execution encountered an error and should be investigated.
- `SKIP` means a rule did not apply to that resource.

For weekly roll-up reporting, apply [supply-chain-status.yaml](supply-chain-status.yaml).

## Quarterly Pin Update Cadence

Pinned versions for supply chain tools must be reviewed and updated quarterly.

Pins live in:
- [ci/github-actions/_shared/reusable-supply-chain.yml](../../ci/github-actions/_shared/reusable-supply-chain.yml)
- [ci/github-actions/_shared/reusable-supply-chain-verify.yml](../../ci/github-actions/_shared/reusable-supply-chain-verify.yml)
- [secops/supply-chain/supply-chain-status.yaml](supply-chain-status.yaml)

Track each pin marked with `# <-- UPDATE QUARTERLY` and validate compatibility before rollout.

## Golden Path

Adoption guide: [docs/golden-paths/supply-chain-security.md](../../docs/golden-paths/supply-chain-security.md)
