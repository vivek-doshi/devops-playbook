# SecOps - Operational Security for Kubernetes

## Overview

The SecOps feature provides operational security workflows and runtime controls for Kubernetes environments. This feature complements the existing shift-left security scanning in the `security/` folder by adding runtime threat detection, compliance auditing, supply chain verification at admission time, and incident response runbooks.

### Purpose

SecOps addresses the gap between pre-deployment security scanning (shift-left) and runtime security operations:

- **Shift-Left Security** (`security/` folder): Pre-deployment scanning including container scanning, secret detection, SAST, dependency auditing, and IaC scanning. These tools catch vulnerabilities before code reaches production.

- **Runtime Security** (`secops/` folder): Runtime threat detection, admission control for supply chain verification, compliance scanning, and incident response. These tools monitor and enforce security policies during runtime and provide structured incident response procedures.

### Scope

**In Scope:**
- Runtime threat detection using Falco with eBPF-based system call monitoring
- Kubernetes API audit logging with Loki integration
- Supply chain verification at admission time using Kyverno and Cosign
- CIS Kubernetes Benchmark compliance scanning with kube-bench
- Incident response runbooks for common security scenarios
- Integration with existing observability (Loki, Prometheus) and notification (Slack, PagerDuty) infrastructure

**Out of Scope:**
- Pre-deployment security scanning (covered by `security/` folder)
- Network policy generation (covered by `cd/kubernetes/_base/network-policies/`)
- Secret management and rotation (covered by `security/secret-rotation/`)
- Container image building and signing (covered by CI/CD pipelines)

## Architecture

```
secops/
├── runtime/                    # Runtime threat detection and audit logging
│   ├── falco/                 # Falco runtime security monitoring
│   │   ├── values.yaml        # Helm chart values for Falco deployment
│   │   └── rules/             # Custom Falco detection rules
│   │       ├── custom-rules.yaml    # Custom detection rules
│   │       └── alerts.yaml          # Alertmanager integration config
│   └── audit-logging/         # Kubernetes API audit logging
│       ├── audit-policy.yaml  # Kubernetes audit policy
│       └── loki-shipper.yaml  # Promtail configuration for shipping logs to Loki
├── supply-chain/              # Supply chain verification policies
│   ├── cosign-verify-policy.yaml    # Image signature verification
│   ├── sbom-policy.yaml             # SBOM attestation verification
│   └── slsa-verify.yaml             # SLSA provenance verification
├── compliance/                # Compliance scanning and control mapping
│   ├── kube-bench-job.yaml          # One-time CIS Benchmark scan
│   ├── kube-bench-cronjob.yaml      # Scheduled CIS Benchmark scan
│   └── controls/              # Compliance control mapping documentation
│       ├── cis-kubernetes.md        # CIS Kubernetes Benchmark mapping
│       ├── soc2.md                  # SOC2 control mapping
│       └── iso27001.md              # ISO 27001 control mapping
└── runbooks/                  # Incident response runbooks
    ├── compromised-pod.md           # Compromised pod response
    ├── secret-exposure.md           # Credential leak response
    ├── supply-chain-incident.md     # Supply chain attack response
    └── node-compromise.md           # Node compromise response
```

## Integration with Existing Infrastructure

SecOps integrates seamlessly with existing infrastructure:

### Observability Stack
- **Loki** (`observability/loki/`): Kubernetes audit logs are shipped to Loki for centralized log storage with 30-day retention
- **Prometheus** (`observability/prometheus/`): Falco exports metrics to Prometheus for monitoring alert rates and performance
- **Grafana**: Query audit logs and view Falco metrics through existing Grafana dashboards

### Notification Channels
- **Alertmanager**: All security alerts (Falco, kube-bench) are routed through Alertmanager
- **PagerDuty** (`notifications/pagerduty-notify.yml`): Critical and high-severity alerts trigger PagerDuty incidents
- **Slack** (`notifications/slack-notify.yml`): Medium-severity alerts and compliance scan summaries are sent to Slack

### Policy Engine
- **Kyverno** (`policy/kyverno/`): Supply chain verification policies leverage existing Kyverno installation for admission control

### Security Tools
- **Secret Rotation** (`security/secret-rotation/`): Incident response runbooks reference existing secret rotation procedures
- **Container Scanning** (`security/container-scanning/`): Incident response runbooks reference existing container scanning tools for malware analysis

## Installation

### Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.x
- Existing infrastructure deployed:
  - Loki (`observability/loki/`)
  - Prometheus with Alertmanager (`observability/prometheus/`)
  - Kyverno (`policy/kyverno/`)
  - Notification channels configured (`notifications/`)

### 1. Deploy Falco Runtime Security Monitoring

Falco monitors container runtime behavior and detects suspicious activity using eBPF-based system call monitoring.

```bash
# Add Falco Helm repository
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Install Falco with custom configuration
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --values secops/runtime/falco/values.yaml

# Verify Falco is running
kubectl get pods -n falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50

# Test Falco detection (should trigger alert)
kubectl run test-shell --image=nginx --rm -it -- /bin/bash
```

**Configuration:**
- Custom detection rules: `secops/runtime/falco/rules/custom-rules.yaml`
- Alertmanager integration: `secops/runtime/falco/rules/alerts.yaml`
- Helm values: `secops/runtime/falco/values.yaml`

**Verification:**
- Check Falco is capturing events: `kubectl logs -n falco -l app.kubernetes.io/name=falco | grep "Falco initialized"`
- Verify Alertmanager connectivity: Check Alertmanager UI for Falco alerts after triggering test alert

### 2. Configure Kubernetes API Audit Logging

Kubernetes audit logging captures all API requests for security investigation and compliance.

**Note:** This requires control plane access and varies by Kubernetes distribution.

#### For kubeadm clusters:

```bash
# Copy audit policy to control plane nodes
scp secops/runtime/audit-logging/audit-policy.yaml control-plane-node:/etc/kubernetes/audit-policy.yaml

# Edit kube-apiserver manifest on control plane nodes
# Add these flags to /etc/kubernetes/manifests/kube-apiserver.yaml:
#   --audit-policy-file=/etc/kubernetes/audit-policy.yaml
#   --audit-log-path=/var/log/kubernetes/audit.log
#   --audit-log-maxage=30
#   --audit-log-maxbackup=10
#   --audit-log-maxsize=100

# Mount audit policy and log directory in kube-apiserver pod
# Add to volumeMounts:
#   - name: audit-policy
#     mountPath: /etc/kubernetes/audit-policy.yaml
#     readOnly: true
#   - name: audit-log
#     mountPath: /var/log/kubernetes
# Add to volumes:
#   - name: audit-policy
#     hostPath:
#       path: /etc/kubernetes/audit-policy.yaml
#       type: File
#   - name: audit-log
#     hostPath:
#       path: /var/log/kubernetes
#       type: DirectoryOrCreate

# kube-apiserver will automatically restart with new configuration
```

#### For managed Kubernetes (EKS, GKE, AKS):

- **EKS**: Enable CloudWatch audit logging in cluster configuration
- **GKE**: Enable Cloud Audit Logs in cluster configuration
- **AKS**: Enable Azure Monitor diagnostic settings for audit logs

#### Deploy Promtail log shipper:

```bash
# Deploy Promtail to ship audit logs to Loki
kubectl apply -f secops/runtime/audit-logging/loki-shipper.yaml

# Verify Promtail is running on control plane nodes
kubectl get pods -n secops -l app=promtail-audit

# Check Promtail is shipping logs
kubectl logs -n secops -l app=promtail-audit --tail=50
```

**Verification:**
- Query audit logs in Grafana: `{source="k8s-audit"}`
- Verify audit events are being captured: Create a test pod and query for the creation event

### 3. Deploy Supply Chain Verification Policies

Supply chain verification policies enforce that only signed container images with valid attestations are deployed.

**Prerequisites:**
- Container images must be signed with Cosign using keyless signing (GitHub Actions OIDC)
- Images must have SBOM attestations in SPDX-JSON format
- Images must have SLSA provenance attestations

```bash
# Deploy Kyverno supply chain policies
kubectl apply -f secops/supply-chain/cosign-verify-policy.yaml
kubectl apply -f secops/supply-chain/sbom-policy.yaml
kubectl apply -f secops/supply-chain/slsa-verify.yaml

# Verify policies are active
kubectl get clusterpolicy
kubectl describe clusterpolicy verify-image-signature
kubectl describe clusterpolicy verify-sbom-attestation
kubectl describe clusterpolicy verify-slsa-provenance

# Test policy enforcement (should be rejected if unsigned)
kubectl run test-unsigned --image=nginx:latest

# Configure namespace for audit mode (log violations, don't block)
kubectl label namespace development \
  policy.kyverno.io/supply-chain=audit \
  policy.kyverno.io/sbom=audit \
  policy.kyverno.io/slsa=audit

# Configure namespace to disable verification (for local development)
kubectl label namespace local-dev \
  policy.kyverno.io/supply-chain=disabled \
  policy.kyverno.io/sbom=disabled \
  policy.kyverno.io/slsa=disabled
```

**Enforcement Modes:**
- **Enforce** (default): Reject pods with unsigned images or missing attestations
- **Audit**: Log violations to PolicyReport but allow deployment (use namespace label `policy.kyverno.io/supply-chain=audit`)
- **Disabled**: Skip verification entirely (use namespace label `policy.kyverno.io/supply-chain=disabled`)

**Verification:**
- Check PolicyReports: `kubectl get policyreport -A`
- View policy violations: `kubectl describe policyreport -n <namespace>`

### 4. Deploy CIS Benchmark Compliance Scanning

CIS Benchmark scanning identifies security misconfigurations in Kubernetes clusters.

```bash
# Run one-time CIS Benchmark scan
kubectl apply -f secops/compliance/kube-bench-job.yaml

# Wait for scan to complete
kubectl wait --for=condition=complete job/kube-bench -n secops --timeout=300s

# View scan results
kubectl get configmap -n secops -l scan-type=cis-benchmark
kubectl get configmap kube-bench-results-$(date +%Y-%m-%d) -n secops -o jsonpath='{.data.results\.json}' | jq

# Deploy scheduled weekly scan
kubectl apply -f secops/compliance/kube-bench-cronjob.yaml

# Verify CronJob is scheduled
kubectl get cronjob -n secops
kubectl describe cronjob kube-bench-scheduled -n secops
```

**Scan Schedule:**
- Weekly scans run every Sunday at 02:00 UTC
- Last 3 scan results are retained
- Alerts are sent to Alertmanager when new failures are detected
- Summaries are sent to Slack on scan completion

**Verification:**
- Check scan results: `kubectl get configmap -n secops -l scan-type=cis-benchmark`
- View compliance dashboard in Grafana (if configured)

## Incident Response Runbooks

SecOps provides structured incident response procedures for common security scenarios:

- **[Compromised Pod](runbooks/compromised-pod.md)**: Response procedures for containers exhibiting suspicious behavior detected by Falco
- **[Secret Exposure](runbooks/secret-exposure.md)**: Response procedures for credential leaks or exposed secrets
- **[Supply Chain Incident](runbooks/supply-chain-incident.md)**: Response procedures for unsigned or tampered container images
- **[Node Compromise](runbooks/node-compromise.md)**: Response procedures for compromised Kubernetes nodes

Each runbook follows a consistent structure:
1. **Detection**: How to identify the incident from alerts
2. **Immediate Actions**: First 15 minutes - contain and preserve evidence
3. **Investigation**: Next 1-2 hours - analyze and determine scope
4. **Remediation**: Remove threat and patch vulnerabilities
5. **Post-Incident**: Document findings and improve detection

## Troubleshooting

### Falco Issues

**Problem: Falco pods in CrashLoopBackOff**

```bash
# Check Falco logs for errors
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100

# Common causes:
# 1. eBPF driver failed to load (kernel version incompatibility)
#    Solution: Check kernel version (4.14+ required), or use kernel module driver
# 2. Custom rules have syntax errors
#    Solution: Validate rules with `falco --validate` before deployment
# 3. Insufficient permissions
#    Solution: Verify Falco ServiceAccount has required RBAC permissions
```

**Problem: Falco not sending alerts to Alertmanager**

```bash
# Check Falco logs for HTTP errors
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep -i alertmanager

# Verify Alertmanager endpoint is reachable
kubectl exec -n falco -it <falco-pod> -- curl -v http://alertmanager.monitoring:9093/api/v1/alerts

# Check Alertmanager configuration
kubectl get configmap -n monitoring alertmanager-config -o yaml
```

**Problem: Too many false positive alerts**

```bash
# Review alert volume by rule
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep "Rule:" | sort | uniq -c | sort -rn

# Tune rules to reduce false positives:
# 1. Add exclusions for expected behavior in custom-rules.yaml
# 2. Adjust rule conditions to be more specific
# 3. Use namespace-based exclusions (e.g., exclude non-production namespaces)
```

### Audit Logging Issues

**Problem: Audit logs not appearing in Loki**

```bash
# Check Promtail is running on control plane nodes
kubectl get pods -n secops -l app=promtail-audit

# Check Promtail logs for errors
kubectl logs -n secops -l app=promtail-audit --tail=100

# Verify audit log file exists on control plane nodes
ssh control-plane-node "ls -lh /var/log/kubernetes/audit.log"

# Verify Loki endpoint is reachable
kubectl exec -n secops -it <promtail-pod> -- wget -O- http://loki.observability:3100/ready

# Check Loki for audit logs
# In Grafana, query: {source="k8s-audit"}
```

**Problem: Audit log volume too high**

```bash
# Check audit log size
ssh control-plane-node "du -h /var/log/kubernetes/audit.log*"

# Tune audit policy to reduce volume:
# 1. Exclude more read operations (get, list, watch)
# 2. Exclude system component requests
# 3. Use Metadata level instead of RequestResponse for less critical operations
# Edit secops/runtime/audit-logging/audit-policy.yaml and restart kube-apiserver
```

### Supply Chain Verification Issues

**Problem: Pods rejected due to signature verification failure**

```bash
# Check Kyverno policy reports
kubectl get policyreport -A
kubectl describe policyreport -n <namespace>

# Common causes:
# 1. Image not signed with Cosign
#    Solution: Sign image with `cosign sign` using keyless signing
# 2. Certificate identity doesn't match expected GitHub Actions workflow
#    Solution: Verify certificate subject matches workflow URL pattern
# 3. Rekor transparency log unavailable
#    Solution: Check Rekor status at https://status.sigstore.dev/

# Temporarily switch namespace to audit mode for troubleshooting
kubectl label namespace <namespace> policy.kyverno.io/supply-chain=audit --overwrite
```

**Problem: Kyverno webhook timeout**

```bash
# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=100

# Increase webhook timeout in policy
# Edit secops/supply-chain/cosign-verify-policy.yaml
# Set webhookTimeoutSeconds: 60 (default is 30)

# Check Rekor transparency log latency
curl -w "@curl-format.txt" -o /dev/null -s https://rekor.sigstore.dev/api/v1/log
```

### Compliance Scanning Issues

**Problem: kube-bench Job fails to complete**

```bash
# Check Job status
kubectl describe job kube-bench -n secops

# Check Job logs
kubectl logs -n secops job/kube-bench

# Common causes:
# 1. Insufficient permissions to access host filesystem
#    Solution: Verify Job has hostPath volumes mounted
# 2. Control plane node selector not matching
#    Solution: Adjust nodeSelector in kube-bench-job.yaml
# 3. kube-bench version incompatible with Kubernetes version
#    Solution: Update kube-bench image version
```

**Problem: CIS Benchmark scan shows many failures**

```bash
# View detailed scan results
kubectl get configmap -n secops -l scan-type=cis-benchmark --sort-by=.metadata.creationTimestamp
kubectl get configmap <latest-result> -n secops -o jsonpath='{.data.results\.json}' | jq '.Controls[] | select(.tests[].status == "FAIL")'

# Prioritize remediation:
# 1. Review compliance control mapping: secops/compliance/controls/cis-kubernetes.md
# 2. Focus on scored tests (scored: true) first
# 3. Review remediation steps in kube-bench output
# 4. Some failures may be acceptable based on risk tolerance (document exceptions)
```

## Monitoring and Metrics

### Falco Metrics

Falco exports Prometheus metrics for monitoring:

- `falco_events_total`: Total number of events processed
- `falco_alerts_total`: Total number of alerts generated
- `falco_rules_matched_total`: Total number of rule matches by rule name
- `falco_drop_events_total`: Total number of dropped events (indicates performance issues)

**Grafana Dashboard:** Import Falco dashboard from [Falco Grafana dashboards](https://github.com/falcosecurity/falco/tree/master/examples/grafana)

### Audit Log Metrics

Query audit logs in Grafana using LogQL:

```logql
# Count of API requests by verb
sum by (verb) (count_over_time({source="k8s-audit"} [1h]))

# Failed authentication attempts
{source="k8s-audit"} |= "Forbidden" | json | response_code="403"

# Secret access events
{source="k8s-audit"} | json | resource="secrets"

# Pod creation events
{source="k8s-audit"} | json | verb="create" | resource="pods"
```

### Supply Chain Verification Metrics

Kyverno exports Prometheus metrics:

- `kyverno_policy_results_total`: Total policy results by policy, rule, and result (pass/fail)
- `kyverno_admission_requests_total`: Total admission requests processed
- `kyverno_admission_review_duration_seconds`: Admission review latency

**Grafana Dashboard:** Import Kyverno dashboard from [Kyverno Grafana dashboards](https://github.com/kyverno/kyverno/tree/main/charts/kyverno/dashboards)

### Compliance Scanning Metrics

CIS Benchmark scan results are stored as ConfigMaps with labels:

```bash
# Query scan results over time
kubectl get configmap -n secops -l scan-type=cis-benchmark --sort-by=.metadata.creationTimestamp

# Extract pass/fail counts
kubectl get configmap <result> -n secops -o jsonpath='{.data.results\.json}' | jq '.Totals'
```

## Security Considerations

### Falco Security

- Falco runs as privileged DaemonSet with host filesystem access (required for eBPF)
- Limit Falco RBAC permissions to read-only access to Kubernetes API
- Protect Falco configuration from tampering using admission policies
- Rotate Alertmanager TLS certificates regularly

### Audit Logging Security

- Audit logs contain sensitive information (usernames, IP addresses, resource names)
- Restrict access to audit logs using Loki RBAC
- Exclude secret values from audit logs (use Metadata level for Secret operations)
- Encrypt audit logs at rest and in transit

### Supply Chain Verification Security

- Kyverno policies enforce signature verification but don't prevent all supply chain attacks
- Verify certificate identity matches expected GitHub Actions workflow URL
- Monitor PolicyReports for audit mode violations (may indicate attack attempts)
- Regularly review and update allowed certificate identities

### Compliance Scanning Security

- kube-bench requires privileged access to control plane nodes
- Restrict access to scan results (may reveal security misconfigurations)
- Remediate critical and high-severity findings promptly
- Document accepted risks for findings that cannot be remediated

## Contributing

When adding new security controls:

1. **Detection Rules**: Add custom Falco rules to `secops/runtime/falco/rules/custom-rules.yaml`
2. **Supply Chain Policies**: Add Kyverno policies to `secops/supply-chain/`
3. **Incident Response**: Add runbooks to `secops/runbooks/` following the standard structure
4. **Compliance Mapping**: Update control mappings in `secops/compliance/controls/`

## References

- [Falco Documentation](https://falco.org/docs/)
- [Kyverno Documentation](https://kyverno.io/docs/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [kube-bench Documentation](https://github.com/aquasecurity/kube-bench)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [SLSA Framework](https://slsa.dev/)
- [Kubernetes Audit Logging](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)

## License

This configuration is part of the CI/CD Reference Architecture and follows the same license as the parent repository.
