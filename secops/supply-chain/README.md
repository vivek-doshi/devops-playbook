# Supply-chain policy rollout

Signature, SBOM, and SLSA policies are `Audit` by default. A namespace enters enforcement only when its owner applies all three labels:

```sh
kubectl label namespace <namespace> policy.kyverno.io/supply-chain=enforce
kubectl label namespace <namespace> policy.kyverno.io/sbom=enforce
kubectl label namespace <namespace> policy.kyverno.io/slsa=enforce
```

Use `disabled` only as a time-bound exception recorded in change management. Built-in Kubernetes images and `nginx`, `redis`, `postgres`, and `busybox` are temporary platform exceptions while their publisher trust roots are onboarded; review them quarterly.

Promote a namespace only after its PolicyReports are clean in audit mode and its images are digest-pinned, signed, and published with an SPDX SBOM and SLSA provenance.
