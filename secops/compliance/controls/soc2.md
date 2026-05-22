# SOC 2 Type II Control Mapping for Kubernetes
# Requirements: 9.2, 9.4, 9.5

This document maps SOC 2 Type II Trust Services Criteria (TSC) to CIS Kubernetes
Benchmark controls and SecOps implementation components. Use this for demonstrating
SOC 2 compliance coverage to auditors.

## Overview

SOC 2 Trust Services Criteria relevant to Kubernetes operations:

| Category | Code | Description |
|----------|------|-------------|
| Security | CC6 | Logical and Physical Access Controls |
| Security | CC7 | System Operations |
| Security | CC8 | Change Management |
| Availability | A1 | Availability |
| Confidentiality | C1 | Confidentiality |

---

## CC6: Logical and Physical Access Controls

### CC6.1 — Logical Access Security Software

> The entity implements logical access security software, infrastructure, and architectures
> over protected information assets to protect them from security events.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Access control to Kubernetes resources | 5.1.1 RBAC enabled | `5.1.1` | RBAC configuration |
| Minimize access to Secrets | 5.1.2 Minimize secret access | `5.1.2` | policy/kyverno/restrict-secrets.yaml |
| Prevent wildcard RBAC | 5.1.3 Minimize wildcards | `5.1.3` | policy/kyverno/disallow-wildcard-rbac.yaml |
| Service account token control | 5.1.6 Disable automount | `5.1.6` | policy/kyverno/disallow-automount-token.yaml |
| Admission control | 1.2.9–1.2.16 Admission plugins | `1.2.9`–`1.2.16` | Kubernetes API server config |

### CC6.2 — Authentication Controls

> Prior to issuing system credentials and granting system access, the entity registers
> and authorizes new internal and external users.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| No anonymous authentication | 1.2.1 Disable anonymous-auth | `1.2.1` | API server configuration |
| No basic auth | 1.2.2 No basic auth | `1.2.2` | API server configuration |
| Kubelet anonymous auth disabled | 4.2.1 Anonymous auth disabled | `4.2.1` | Kubelet configuration |
| Certificate-based authentication | 1.2.5–1.2.6 Kubelet cert auth | `1.2.5`, `1.2.6` | Kubelet configuration |

### CC6.3 — Role-Based Access Control

> The entity authorizes, modifies, or removes access to data, software, functions,
> and other protected information assets based on the individual's role.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Audit Log |
|---------------|----------------------|---------------|-----------|
| RBAC access reviews | 5.1.1 RBAC is used | `5.1.1` | audit-policy.yaml (RBAC operations logged) |
| Least-privilege access | 5.1.2–5.1.5 Minimize access | `5.1.2`–`5.1.5` | secops/runtime/audit-logging/audit-policy.yaml |
| RBAC change logging | 3.2.2 Audit policy coverage | `3.2.2` | **secops/runtime/audit-logging/audit-policy.yaml** |

### CC6.6 — System Boundary Protection

> The entity implements logical access security measures to protect against threats
> from sources outside its system boundaries.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Network policies | 5.3.1 Network policies used | `5.3.1` | cd/kubernetes/_base/network-policies/ |
| Default deny network policies | 5.3.2 Default deny | `5.3.2` | cd/kubernetes/_base/network-policies/ |
| API server TLS | 1.2.4 HTTPS only | `1.2.4` | API server configuration |
| etcd TLS | 2.1 etcd TLS | `2.1` | etcd configuration |
| Kubelet TLS | 4.2.10–4.2.11 Kubelet TLS | `4.2.10`, `4.2.11` | Kubelet configuration |

### CC6.7 — Data Transmission Controls

> The entity restricts the transmission of information to authorized internal and
> external users and processes.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Secret encryption at rest | 2.3 etcd encrypted at rest | `2.3` | EncryptionConfiguration |
| Secure secret storage | 5.4.1–5.4.2 Secret handling | `5.4.1`, `5.4.2` | secrets/ |
| TLS cipher enforcement | 1.2.23–1.2.25 Approved TLS | `1.2.23`–`1.2.25` | API server configuration |

### CC6.8 — Controls to Prevent Malware

> The entity implements controls to prevent or detect and act upon the introduction
> of unauthorized or malicious software.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Image signature verification | 5.5.1 Image provenance | `5.5.1` | **secops/supply-chain/cosign-verify-policy.yaml** |
| SBOM attestation | 5.5.1 (extension) | N/A | **secops/supply-chain/sbom-policy.yaml** |
| SLSA provenance | 5.5.1 (extension) | N/A | **secops/supply-chain/slsa-verify.yaml** |
| Runtime threat detection | — | — | **secops/runtime/falco/** |
| Container scanning | — | — | security/container-scanning/ |

---

## CC7: System Operations

### CC7.1 — Infrastructure Change Detection

> To meet its objectives, the entity uses detection and monitoring procedures to
> identify changes to configurations that result in the introduction of new vulnerabilities.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| CIS Benchmark scanning | All sections | All | **secops/compliance/kube-bench-job.yaml** |
| Weekly automated scanning | — | — | **secops/compliance/kube-bench-cronjob.yaml** |
| Admission controller | 1.2.10–1.2.16 | `1.2.10`–`1.2.16` | Kyverno policies |
| Runtime security monitoring | — | — | **secops/runtime/falco/** |

### CC7.2 — Anomaly Detection

> The entity monitors system components and the operation of those controls on
> an ongoing basis to detect anomalies.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Runtime anomaly detection | — | — | **secops/runtime/falco/rules/custom-rules.yaml** |
| Audit log monitoring | 3.2.1–3.2.2 | `3.2.1`, `3.2.2` | **secops/runtime/audit-logging/** |
| Alert routing | — | — | **secops/runtime/falco/rules/alerts.yaml** |
| Alertmanager integration | — | — | notifications/pagerduty-notify.yml, notifications/slack-notify.yml |

### CC7.3 — Incident Evaluation

> The entity evaluates security events to determine whether they could or have
> resulted in a failure of the entity to meet its objectives.

| SOC 2 Control | Runbook |
|---------------|---------|
| Compromised pod response | **secops/runbooks/compromised-pod.md** |
| Secret exposure response | **secops/runbooks/secret-exposure.md** |
| Supply chain incident response | **secops/runbooks/supply-chain-incident.md** |
| Node compromise response | **secops/runbooks/node-compromise.md** |

### CC7.4 — Incident Response

> The entity responds to identified security incidents by executing a defined
> incident-response program.

| SOC 2 Control | Implementation |
|---------------|----------------|
| Documented response procedures | secops/runbooks/ (all runbooks) |
| Evidence preservation | secops/runbooks/compromised-pod.md (§ Forensic Evidence) |
| Stakeholder notification | secops/runbooks/secret-exposure.md (§ Notifications) |
| Post-incident review | All runbooks (§ Post-Incident) |

---

## CC8: Change Management

### CC8.1 — Infrastructure Change Control

> The entity authorizes, designs, develops or acquires, configures, documents,
> tests, approves, and implements changes to infrastructure, data, software, and
> procedures to meet its change management objectives.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Change audit logging | 3.2.2 Audit policy | `3.2.2` | **secops/runtime/audit-logging/audit-policy.yaml** |
| Deployment controls | — | — | secops/supply-chain/ |
| Supply chain verification | 5.5.1 | `5.5.1` | secops/supply-chain/cosign-verify-policy.yaml |

---

## C1: Confidentiality

### C1.1 — Identification and Maintenance of Confidential Information

> The entity identifies and maintains confidential information to meet the entity's
> objectives related to confidentiality.

| SOC 2 Control | CIS Benchmark Control | kube-bench ID | Implementation |
|---------------|----------------------|---------------|----------------|
| Secret access control | 5.1.2 Minimize secret access | `5.1.2` | RBAC + audit logging |
| Secret audit logging | 3.2.2 Secret operations | `3.2.2` | **secops/runtime/audit-logging/audit-policy.yaml** |
| Secret exposure response | — | — | **secops/runbooks/secret-exposure.md** |
| Secret rotation | — | — | security/secret-rotation/ |

---

## Audit Evidence Mapping

For SOC 2 audit purposes, the following evidence is available:

| Evidence Type | Source | Retention |
|---------------|--------|-----------|
| Kubernetes API audit logs | Loki (via secops/runtime/audit-logging/loki-shipper.yaml) | 30 days |
| CIS Benchmark scan results | ConfigMap (kube-bench-results-*) | 7 days per job |
| Kyverno policy violations | PolicyReport resources | Until pod deletion |
| Falco security alerts | Alertmanager + Loki | 30 days |
| Access control changes | Kubernetes audit log → Loki | 30 days |

### Grafana Query for SOC 2 Audit Evidence

```logql
# RBAC changes (CC6.3)
{source="k8s-audit", resource="clusterrolebindings"} | json | verb=~"create|update|patch|delete"

# Secret access events (C1.1)
{source="k8s-audit", resource="secrets"} | json | verb=~"create|update|patch|delete"

# Authentication failures (CC6.2)
{source="k8s-audit"} | json | user_username="system:anonymous"

# Pod creation events (CC8.1)
{source="k8s-audit", resource="pods"} | json | verb="create"
```
