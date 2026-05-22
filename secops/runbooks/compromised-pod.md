# Compromised Pod Incident Response Runbook

**Requirements:** 10.1-10.8

**Structure:** Detection -> Immediate Actions -> Investigation -> Remediation -> Post-Incident

**Related Runbooks:**
- secops/runbooks/secret-exposure.md (if credentials were exposed)
- secops/runbooks/node-compromise.md (if node escape is suspected)

**Related Tools:**
- secops/runtime/falco/rules/custom-rules.yaml
- secops/runtime/audit-logging/audit-policy.yaml (audit logs in Loki)

---

## Severity Classification

| Falco Rule | Severity | Response Time |
|-----------|----------|---------------|
| Privilege Escalation via UID/GID Change | CRITICAL | 15 minutes |
| Cryptocurrency Miner Detected | CRITICAL | 15 minutes |
| Container Proc Mount Access | CRITICAL | 15 minutes |
| Namespace Enter in Container | CRITICAL | 15 minutes |
| Terminal Shell in Production Container | HIGH | 30 minutes |
| Sensitive File Access in Container | HIGH | 30 minutes |
| kubectl Executed in Container | HIGH | 30 minutes |
| Unexpected Outbound Connection | MEDIUM | 2 hours |

---

## Detection

**Requirement 10.2** — Identify the compromised pod from Falco alerts.

### 1. Confirm the Alert

Falco alerts arrive in PagerDuty (CRITICAL/HIGH) or Slack (MEDIUM).

```bash
# Check recent Falco alerts in Alertmanager
curl -s http://kube-prometheus-stack-alertmanager.monitoring:9093/api/v1/alerts \
  | jq '.data[] | select(.labels.source == "falco-runtime-security")'
```

Key fields from the alert:
- `labels.pod` — Pod name
- `labels.namespace` — Kubernetes namespace
- `labels.rule` — Falco rule that fired
- `labels.priority` — CRITICAL / ERROR / WARNING
- `startsAt` — Timestamp

### 2. Query Falco Events in Loki

```logql
# Last hour of events for this pod
{source="falco-runtime-security", pod="<POD_NAME>"} | json
  | line_format "{{.priority}} {{.rule}} user={{.user}} cmd={{.output}}"
```

---

## Immediate Actions (First 15 Minutes)

### Step 1: Capture Pod State

**Requirement 10.3** — Capture forensic evidence before any changes.

```bash
POD_NAME="<POD_NAME>"
NAMESPACE="<NAMESPACE>"
EVIDENCE_DIR="/tmp/inc-$(date +%s)"
mkdir -p ${EVIDENCE_DIR}

# Full pod spec
kubectl get pod ${POD_NAME} -n ${NAMESPACE} -o yaml > ${EVIDENCE_DIR}/pod-spec.yaml

# Events
kubectl get events -n ${NAMESPACE} \
  --field-selector involvedObject.name=${POD_NAME} \
  > ${EVIDENCE_DIR}/events.txt

# Process list
kubectl exec -n ${NAMESPACE} ${POD_NAME} -- ps auxf \
  > ${EVIDENCE_DIR}/processes.txt 2>&1 || true

# Network connections
kubectl exec -n ${NAMESPACE} ${POD_NAME} -- ss -tulnp \
  > ${EVIDENCE_DIR}/network.txt 2>&1 || true

# Container logs
kubectl logs ${POD_NAME} -n ${NAMESPACE} --all-containers \
  > ${EVIDENCE_DIR}/logs.txt 2>&1 || true
```

### Step 2: Isolate Pod with NetworkPolicy

**Requirement 10.5** — Isolate the pod using NetworkPolicy before termination.

```bash
# Deny all ingress and egress for this pod
# Match pod by its existing labels
POD_LABELS=$(kubectl get pod ${POD_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.metadata.labels}' | jq -r 'to_entries[] | "\(.key): \"\(.value)\""')

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-${POD_NAME}
  namespace: ${NAMESPACE}
spec:
  podSelector:
    matchLabels:
$(echo "${POD_LABELS}" | sed 's/^/      /')
  policyTypes: [Ingress, Egress]
  # No rules = deny all
EOF

echo "Pod ${POD_NAME} isolated. No ingress or egress traffic permitted."
```

### Step 3: Notify Stakeholders

```bash
NODE=$(kubectl get pod ${POD_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.nodeName}')
IMAGE=$(kubectl get pod ${POD_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].image}')

echo "INCIDENT: Compromised pod detected"
echo "Pod: ${POD_NAME} | Namespace: ${NAMESPACE} | Node: ${NODE}"
echo "Image: ${IMAGE}"
echo "Notify: Security team, Platform team, Application owner"
```

---

## Investigation (Next 1-2 Hours)

### Step 4: Preserve Audit Logs from Loki

**Requirement 10.4** — Preserve audit logs for the affected namespace and time window.

```logql
# All API operations in the namespace (Grafana)
{source="k8s-audit", namespace="<NAMESPACE>"} | json
  | line_format "{{.requestReceivedTimestamp}} user={{.user_username}} {{.verb}} {{.resource}} {{.objectRef_name}} http={{.responseStatus_code}}"
```

```logql
# Secret access events
{source="k8s-audit", namespace="<NAMESPACE>"} | json
  | resource="secrets" | verb=~"get|create|update|patch"
```

```logql
# kubectl exec events (pod access)
{source="k8s-audit", namespace="<NAMESPACE>"} | json
  | requestURI=~".*/exec.*"
```

### Step 5: Collect Additional Forensic Evidence

```bash
# Filesystem changes (files modified since container start)
kubectl exec -n ${NAMESPACE} ${POD_NAME} -- find / -newer /proc/1/exe \
  -not -path '/proc/*' -not -path '/sys/*' \
  > ${EVIDENCE_DIR}/modified-files.txt 2>&1 || true

# Installed packages (detect unexpected tools)
kubectl exec -n ${NAMESPACE} ${POD_NAME} -- sh -c \
  'dpkg -l 2>/dev/null || rpm -qa 2>/dev/null || apk info 2>/dev/null' \
  > ${EVIDENCE_DIR}/packages.txt 2>&1 || true

# Environment variables (credential exposure check)
kubectl exec -n ${NAMESPACE} ${POD_NAME} -- env \
  > ${EVIDENCE_DIR}/env.txt 2>&1 || true
```

### Step 6: Analyze Container Image

**Requirement 10.6** — Analyze the container image for malware or backdoors.

```bash
IMAGE=$(kubectl get pod ${POD_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.spec.containers[0].image}')

# Vulnerability scan
trivy image ${IMAGE} --severity CRITICAL,HIGH

# Signature verification
cosign verify ${IMAGE} \
  --certificate-identity-regexp='https://github.com/.*' \
  --certificate-oidc-issuer='https://token.actions.githubusercontent.com'

# SLSA provenance
cosign verify-attestation ${IMAGE} --type slsaprovenance
```

---

## Remediation

### Step 7: Determine Credential Exposure

**Requirement 10.7** — Rotate credentials that may have been exposed.

```bash
# Secrets mounted by the pod
echo "=== Mounted Secrets ==="
kubectl get pod ${POD_NAME} -n ${NAMESPACE} \
  -o jsonpath='{range .spec.volumes[*]}{.name}: {.secret.secretName}{"\n"}{end}'

# Env vars that may contain credentials
echo "=== Credential-like Env Vars ==="
kubectl get pod ${POD_NAME} -n ${NAMESPACE} \
  -o jsonpath='{range .spec.containers[*].env[*]}{.name}{"\n"}{end}' \
  | grep -iE "password|token|key|secret|credential|auth"
```

```bash
# If credentials were exposed, follow:
# secops/runbooks/secret-exposure.md
```

### Step 8: Terminate and Replace the Pod

```bash
# Remove isolation policy
kubectl delete networkpolicy isolate-${POD_NAME} -n ${NAMESPACE}

# Force-delete the pod (Deployment controller will recreate)
kubectl delete pod ${POD_NAME} -n ${NAMESPACE} --grace-period=0 --force

# Verify replacement pod is healthy
DEPLOYMENT=$(kubectl get pod ${POD_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.metadata.ownerReferences[?(@.kind=="ReplicaSet")].name}' \
  | sed 's/-[^-]*$//')
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=300s
```

### Step 9: Update Detection Rules

**Requirement 10.8** — Update Falco rules if a new attack pattern was identified.

```bash
# Edit custom rules
# secops/runtime/falco/rules/custom-rules.yaml

# Apply updated rules (live reload via ConfigMap)
kubectl create configmap falco-custom-rules \
  --from-file=custom-rules.yaml=secops/runtime/falco/rules/custom-rules.yaml \
  -n falco-system --dry-run=client -o yaml | kubectl apply -f -

# Restart Falco to pick up changes
kubectl rollout restart daemonset/falco -n falco-system
```

---

## Post-Incident

### Step 10: Document the Incident

```markdown
# Incident Report: Compromised Pod

**Incident ID:** INC-YYYYMMDD-HHMMSS
**Date:** YYYY-MM-DD
**Severity:** HIGH/CRITICAL
**Status:** Resolved

## Timeline
- HH:MM - Falco alert triggered (rule: ...)
- HH:MM - Evidence captured
- HH:MM - Pod isolated with NetworkPolicy
- HH:MM - Stakeholders notified
- HH:MM - Root cause identified
- HH:MM - Pod terminated and replaced
- HH:MM - Credentials rotated (if applicable)

## Root Cause
[How was the container compromised?]

## Evidence
- Evidence dir: /tmp/inc-xxxxx/
- Audit logs: Loki query (above)

## Impact
- Pods affected: [list]
- Secrets accessed: [list or none]
- Credentials exposed: [yes/no]

## Remediation
- [x] Pod isolated and terminated
- [x] Replacement pod healthy
- [ ] Credentials rotated (if applicable)
- [ ] Falco rule updated
```

### Step 11: Retrospective Checklist

- [ ] Did Falco detect the attack within an acceptable time window?
- [ ] Was the isolation NetworkPolicy applied within 15 minutes?
- [ ] Was forensic evidence captured before pod termination?
- [ ] Were credentials rotated if exposed?
- [ ] Has the detection rule been updated for this attack pattern?
- [ ] Has the container image been patched and re-scanned?
- [ ] Have findings been shared with the application team?
- [ ] Is a post-incident review meeting scheduled within 5 business days?
