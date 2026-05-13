# CIS Kubernetes Benchmark v1.8 Control Mapping
# Requirements: 9.1, 9.4, 9.5, 9.6

This document maps CIS Kubernetes Benchmark v1.8 controls to the kube-bench test IDs,
corresponding Kyverno policies, and audit log requirements for this reference implementation.

## Overview

| Section | Area | Controls |
|---------|------|----------|
| 1.x | Control Plane - API Server | 1.1–1.2 |
| 2.x | etcd | 2.1–2.7 |
| 3.x | Control Plane - Controller Manager | 3.1–3.2 |
| 4.x | Control Plane - Scheduler | 4.1–4.2 |
| 5.x | Worker Nodes | 5.1–5.7 |
| 6.x | Kubernetes Policies | 6.1–6.10 |

## How to Run

```bash
# One-time scan
kubectl apply -f secops/compliance/kube-bench-job.yaml
kubectl wait -n secops --for=condition=complete job/kube-bench-scan --timeout=300s

# View results
kubectl get configmap -n secops -l scan-type=cis-benchmark -o name

# Scheduled weekly scan (Sundays 02:00 UTC)
kubectl apply -f secops/compliance/kube-bench-cronjob.yaml
```

---

## Section 1: Control Plane Components

### 1.1 Master Node Configuration Files

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 1.1.1 | API server pod spec file permissions | `1.1.1` | Node OS configuration |
| 1.1.2 | API server pod spec file ownership | `1.1.2` | Node OS configuration |
| 1.1.3 | Controller manager pod spec file permissions | `1.1.3` | Node OS configuration |
| 1.1.4 | Controller manager pod spec file ownership | `1.1.4` | Node OS configuration |
| 1.1.5 | Scheduler pod spec file permissions | `1.1.5` | Node OS configuration |
| 1.1.6 | Scheduler pod spec file ownership | `1.1.6` | Node OS configuration |
| 1.1.7 | etcd pod spec file permissions | `1.1.7` | Node OS configuration |
| 1.1.8 | etcd pod spec file ownership | `1.1.8` | Node OS configuration |
| 1.1.9 | Container network interface file permissions | `1.1.9` | Node OS configuration |
| 1.1.10 | Container network interface file ownership | `1.1.10` | Node OS configuration |
| 1.1.11 | etcd data directory permissions | `1.1.11` | etcd configuration |
| 1.1.12 | etcd data directory ownership | `1.1.12` | etcd configuration |

### 1.2 API Server

| Control | Description | kube-bench ID | Kyverno Policy | Audit Log |
|---------|-------------|---------------|----------------|-----------|
| 1.2.1 | Disable anonymous authentication | `1.2.1` | — | secops/runtime/audit-logging/audit-policy.yaml (§ unauthenticated) |
| 1.2.2 | Do not use basic authentication | `1.2.2` | — | — |
| 1.2.3 | Do not use token-based authentication | `1.2.3` | — | — |
| 1.2.4 | Use HTTPS only | `1.2.4` | — | — |
| 1.2.5 | Ensure kubelet authentication uses certificates | `1.2.5` | — | — |
| 1.2.6 | Ensure kubelet certificate validation | `1.2.6` | — | — |
| 1.2.7 | Do not permit access to the service account | `1.2.7` | policy/kyverno/restrict-service-account.yaml | audit-policy.yaml |
| 1.2.8 | Ensure RBAC is enabled | `1.2.8` | — | audit-policy.yaml (§ RBAC ops) |
| 1.2.9 | Ensure admission control plugin EventRateLimit | `1.2.9` | — | — |
| 1.2.10 | Do not use AlwaysAdmit | `1.2.10` | — | — |
| 1.2.11 | Ensure AlwaysPullImages plugin | `1.2.11` | — | secops/supply-chain/cosign-verify-policy.yaml |
| 1.2.12 | Ensure SecurityContextDeny not used | `1.2.12` | — | — |
| 1.2.13 | Ensure NodeRestriction admission controller | `1.2.13` | — | — |
| 1.2.14 | Disable service account key file configuration | `1.2.14` | — | — |
| 1.2.15 | Ensure service account lookup is enabled | `1.2.15` | — | — |
| 1.2.16 | Ensure PodSecurity admission controller | `1.2.16` | policy/kyverno/ | — |
| 1.2.17 | Ensure audit logging is enabled | `1.2.17` | — | **secops/runtime/audit-logging/audit-policy.yaml** |
| 1.2.18 | Ensure audit log max age is 30 days | `1.2.18` | — | audit-policy.yaml (--audit-log-maxage=30) |
| 1.2.19 | Ensure audit log backup count | `1.2.19` | — | audit-policy.yaml (--audit-log-maxbackup=10) |
| 1.2.20 | Ensure audit log max size | `1.2.20` | — | audit-policy.yaml (--audit-log-maxsize=100) |
| 1.2.21 | Restrict request timeout | `1.2.21` | — | — |
| 1.2.22 | Ensure service account token max expiration | `1.2.22` | — | — |
| 1.2.23 | Ensure TLS ciphers are secure | `1.2.23` | — | — |
| 1.2.24 | Ensure etcd TLS is enabled | `1.2.24` | — | — |
| 1.2.25 | Ensure API server uses only approved TLS versions | `1.2.25` | — | — |

### 1.3 Controller Manager

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 1.3.1 | Ensure terminated-pod-gc-threshold is set | `1.3.1` | Cluster configuration |
| 1.3.2 | Ensure profiling is disabled | `1.3.2` | API server flags |
| 1.3.3 | Ensure use of service account credentials | `1.3.3` | Cluster configuration |
| 1.3.4 | Ensure service account private key file | `1.3.4` | Cluster configuration |
| 1.3.5 | Ensure root-ca-file is set | `1.3.5` | Cluster configuration |
| 1.3.6 | Ensure RotateKubeletServerCertificate | `1.3.6` | Cluster configuration |
| 1.3.7 | Ensure bind-address is limited | `1.3.7` | Cluster configuration |

### 1.4 Scheduler

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 1.4.1 | Ensure profiling is disabled | `1.4.1` | Scheduler flags |
| 1.4.2 | Ensure bind-address is limited | `1.4.2` | Scheduler configuration |

---

## Section 2: etcd

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 2.1 | Ensure etcd uses TLS | `2.1` | etcd configuration |
| 2.2 | Ensure etcd client certificate authentication | `2.2` | etcd configuration |
| 2.3 | Ensure etcd is encrypted at rest | `2.3` | EncryptionConfiguration |
| 2.4 | Ensure etcd peer TLS | `2.4` | etcd peer configuration |
| 2.5 | Ensure etcd peer certificate authentication | `2.5` | etcd peer configuration |
| 2.6 | Ensure etcd auto-compaction retention | `2.6` | etcd configuration |
| 2.7 | Ensure etcd backup | `2.7` | Backup procedures |

---

## Section 3: Control Plane Configuration

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 3.1.1 | Ensure client certificate authentication not used | `3.1.1` | Authentication configuration |
| 3.2.1 | Ensure audit logging minimal configuration | `3.2.1` | **secops/runtime/audit-logging/audit-policy.yaml** |
| 3.2.2 | Ensure audit policy covers key security concerns | `3.2.2` | **secops/runtime/audit-logging/audit-policy.yaml** |

---

## Section 4: Worker Nodes

### 4.1 Worker Node Configuration Files

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 4.1.1 | kubelet service file permissions | `4.1.1` | Node OS configuration |
| 4.1.2 | kubelet service file ownership | `4.1.2` | Node OS configuration |
| 4.1.3 | Proxy kubeconfig file permissions | `4.1.3` | Node OS configuration |
| 4.1.4 | Proxy kubeconfig file ownership | `4.1.4` | Node OS configuration |
| 4.1.5 | kubelet kubeconfig file permissions | `4.1.5` | Node OS configuration |
| 4.1.6 | kubelet kubeconfig file ownership | `4.1.6` | Node OS configuration |
| 4.1.7 | Certificate authority file permissions | `4.1.7` | Node OS configuration |
| 4.1.8 | Client certificate authority file ownership | `4.1.8` | Node OS configuration |
| 4.1.9 | kubelet config.yaml permissions | `4.1.9` | Node OS configuration |
| 4.1.10 | kubelet config.yaml ownership | `4.1.10` | Node OS configuration |

### 4.2 Kubelet

| Control | Description | kube-bench ID | Implementation |
|---------|-------------|---------------|----------------|
| 4.2.1 | Ensure anonymous auth is disabled | `4.2.1` | Kubelet configuration |
| 4.2.2 | Ensure authorization mode is not AlwaysAllow | `4.2.2` | Kubelet configuration |
| 4.2.3 | Ensure client CA file is configured | `4.2.3` | Kubelet configuration |
| 4.2.4 | Ensure read-only port is disabled | `4.2.4` | Kubelet configuration |
| 4.2.5 | Ensure streaming connection timeout | `4.2.5` | Kubelet configuration |
| 4.2.6 | Ensure protect-kernel-defaults | `4.2.6` | Kubelet configuration |
| 4.2.7 | Ensure node restriction admission | `4.2.7` | Kubelet configuration |
| 4.2.8 | Ensure hostname override is not set | `4.2.8` | Kubelet configuration |
| 4.2.9 | Ensure eventRecordQPS is set | `4.2.9` | Kubelet configuration |
| 4.2.10 | Ensure TLS cert and key configured | `4.2.10` | Kubelet configuration |
| 4.2.11 | Ensure only approved cipher suites | `4.2.11` | Kubelet configuration |
| 4.2.12 | Ensure RotateKubeletServerCertificate enabled | `4.2.12` | Kubelet configuration |
| 4.2.13 | Ensure Kubelet uses only approved TLS versions | `4.2.13` | Kubelet configuration |

---

## Section 5: Kubernetes Policies

| Control | Description | kube-bench ID | Kyverno Policy | Supply Chain Policy |
|---------|-------------|---------------|----------------|---------------------|
| 5.1.1 | Ensure RBAC is used | `5.1.1` | policy/kyverno/ | — |
| 5.1.2 | Minimize access to secrets | `5.1.2` | policy/kyverno/restrict-secrets.yaml | — |
| 5.1.3 | Minimize wildcard use in Roles | `5.1.3` | policy/kyverno/disallow-wildcard-rbac.yaml | — |
| 5.1.4 | Minimize access to create pods | `5.1.4` | policy/kyverno/ | — |
| 5.1.5 | Ensure default service accounts are not bound | `5.1.5` | policy/kyverno/ | — |
| 5.1.6 | Ensure service account tokens are not auto-mounted | `5.1.6` | policy/kyverno/disallow-automount-token.yaml | — |
| 5.2.1 | Minimize privileged containers | `5.2.1` | policy/kyverno/disallow-privileged.yaml | — |
| 5.2.2 | Minimize containers wishing to share host PID | `5.2.2` | policy/kyverno/restrict-host-pid.yaml | — |
| 5.2.3 | Minimize containers sharing host IPC | `5.2.3` | policy/kyverno/restrict-host-ipc.yaml | — |
| 5.2.4 | Minimize containers sharing host network | `5.2.4` | policy/kyverno/restrict-host-network.yaml | — |
| 5.2.5 | Minimize containers with allowPrivilegeEscalation | `5.2.5` | policy/kyverno/disallow-privilege-escalation.yaml | — |
| 5.2.6 | Minimize containers with root | `5.2.6` | policy/kyverno/require-non-root.yaml | — |
| 5.2.7 | Minimize containers with NET_RAW capability | `5.2.7` | policy/kyverno/restrict-net-raw.yaml | — |
| 5.2.8 | Minimize added capabilities | `5.2.8` | policy/kyverno/restrict-capabilities.yaml | — |
| 5.2.9 | Minimize seccomp not set to runtime/default | `5.2.9` | policy/kyverno/require-seccomp.yaml | — |
| 5.3.1 | Ensure network policies are used | `5.3.1` | cd/kubernetes/_base/network-policies/ | — |
| 5.3.2 | Minimize default deny network policies | `5.3.2` | cd/kubernetes/_base/network-policies/ | — |
| 5.4.1 | Prefer using Secrets as files | `5.4.1` | — | — |
| 5.4.2 | Consider external secret storage | `5.4.2` | secrets/ | — |
| 5.5.1 | Configure Image Provenance | `5.5.1` | — | **secops/supply-chain/cosign-verify-policy.yaml** |
| 5.7.1 | Create administrative boundaries using namespaces | `5.7.1` | — | — |
| 5.7.2 | Ensure Seccomp profiles are set to docker/default | `5.7.2` | policy/kyverno/require-seccomp.yaml | — |
| 5.7.3 | Apply Security Context to Pods and Containers | `5.7.3` | policy/kyverno/require-security-context.yaml | — |
| 5.7.4 | Default deny all network policies | `5.7.4` | cd/kubernetes/_base/network-policies/ | — |

---

## Cross-References

### Controls Addressed by SecOps Components

| SecOps Component | CIS Controls Addressed |
|------------------|------------------------|
| secops/runtime/audit-logging/audit-policy.yaml | 1.2.17–1.2.20, 3.2.1–3.2.2 |
| secops/runtime/falco/ | Runtime detection (not a scored CIS control) |
| secops/supply-chain/cosign-verify-policy.yaml | 5.5.1 |
| secops/supply-chain/sbom-policy.yaml | 5.5.1 (SBOM extension) |
| secops/supply-chain/slsa-verify.yaml | 5.5.1 (provenance extension) |
| secops/compliance/kube-bench-job.yaml | All controls (scanner) |
| secops/compliance/kube-bench-cronjob.yaml | All controls (continuous) |

### Audit Log Requirements Cross-Reference

The following CIS controls are implemented via audit policy rules in
`secops/runtime/audit-logging/audit-policy.yaml`:

- **1.2.17–1.2.20**: Audit logging enabled with appropriate retention
- **3.2.1**: Authentication failures logged at Metadata level
- **3.2.2**: Secret operations, pod/deployment operations, RBAC operations logged at appropriate levels

See `secops/runtime/audit-logging/audit-policy.yaml` for the complete audit policy.
