# Secret Exposure Incident Response Runbook

**Requirements:** 11.1-11.8

This runbook guides incident responders through responding to credential leaks,
including immediate rotation, impact assessment, and recurrence prevention.

**Related Runbooks:**
- secops/runbooks/compromised-pod.md (if a pod was compromised to access the secret)

**Related Tools:**
- security/secret-rotation/ (credential rotation procedures)
- security/secret-detection/ (detection rules)
- secops/runtime/audit-logging/audit-policy.yaml (audit logs in Loki)

---

## Severity Classification

| Scenario | Severity | Response Time |
|----------|----------|---------------|
| Production DB password exposed | CRITICAL | Immediate |
| API key/token exposed in repo | HIGH | 30 minutes |
| Internal service credential exposed | HIGH | 1 hour |
| Non-production secret exposed | MEDIUM | 4 hours |
| Kubernetes Secret get/list by unexpected user | MEDIUM | 2 hours |

---

## Detection

**Requirement 11.2** — Identify which secret was exposed.

### 1. Identify the Exposure Source

Common detection signals:
- **GitGuardian/gitleaks alert**: Secret committed to repository
- **Falco alert**: `Sensitive File Access in Container` with `/var/run/secrets/`
- **Audit log anomaly**: Unexpected `get` on a Secret resource
- **Dependency scanner**: Secret found in code scan
- **External report**: Third-party disclosure

```bash
# Check Kubernetes audit logs for unexpected secret access
# Query in Grafana Loki:
```

```logql
# Secret read events in the last 24 hours
{source="k8s-audit", resource="secrets"} | json
  | verb=~"get|list"
  | user_username !~ "system:serviceaccount:.*"
  | line_format "{{.requestReceivedTimestamp}} user={{.user_username}} verb={{.verb}} secret={{.objectRef_name}} ns={{.objectRef_namespace}} http={{.responseStatus_code}}"
```

```bash
# Identify the secret
SECRET_NAME="<SECRET_NAME>"
NAMESPACE="<NAMESPACE>"

# Check what type of credential
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.data}' | jq 'keys[]'

# When was it last modified?
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.metadata.creationTimestamp}'
```

---

## Immediate Actions (First 15 Minutes)

### Step 1: Rotate the Exposed Credential

**Requirement 11.3** — Immediately rotate the exposed credential.

> **Priority**: Rotation must happen BEFORE investigation to minimize exposure window.

```bash
SECRET_NAME="<SECRET_NAME>"
NAMESPACE="<NAMESPACE>"

# Identify credential type and follow appropriate rotation procedure
# See security/secret-rotation/ for type-specific rotation scripts

# For database credentials:
# security/secret-rotation/rotate-db-credentials.sh ${SECRET_NAME} ${NAMESPACE}

# For API keys (GitHub, AWS, GCP, etc.):
# 1. Log into the service console
# 2. Revoke the exposed key IMMEDIATELY
# 3. Generate a new key
# 4. Update the Kubernetes Secret:
kubectl create secret generic ${SECRET_NAME} \
  -n ${NAMESPACE} \
  --from-literal=<KEY>=<NEW_VALUE> \
  --dry-run=client -o yaml | kubectl apply -f -

# For Kubernetes service account tokens:
# Delete the token secret (will be recreated)
# kubectl delete secret ${SECRET_NAME} -n ${NAMESPACE}

echo "Secret ${SECRET_NAME} rotated. Verify all consuming services are updated."
```

### Step 2: Find All Pods Using the Exposed Secret

**Requirement 11.5** — Identify all pods that mounted the exposed secret.

```bash
SECRET_NAME="<SECRET_NAME>"
NAMESPACE="<NAMESPACE>"

echo "=== Pods mounting secret ${SECRET_NAME} ==="

# Find pods with this secret as a volume
kubectl get pods -n ${NAMESPACE} \
  -o json | jq -r --arg secret "${SECRET_NAME}" \
  '.items[] | select(.spec.volumes[]?.secret.secretName == $secret) | .metadata.name'

# Find pods with this secret as an env var source
kubectl get pods -n ${NAMESPACE} \
  -o json | jq -r --arg secret "${SECRET_NAME}" \
  '.items[] | select(.spec.containers[].env[]?.valueFrom.secretKeyRef.name == $secret) | .metadata.name'

# Check across all namespaces if secret is cluster-scoped
kubectl get pods -A \
  -o json | jq -r --arg secret "${SECRET_NAME}" \
  '.items[] | select(.spec.volumes[]?.secret.secretName == $secret) | "\(.metadata.namespace)/\(.metadata.name)"'
```

### Step 3: Notify Stakeholders

**Requirement 11.7** — Notify affected stakeholders.

```bash
echo "=== Incident Notification Checklist ==="
echo ""
echo "IMMEDIATE (within 15 min):"
echo "  [ ] Security team lead notified"
echo "  [ ] Platform/SRE on-call notified"
echo "  [ ] Application owner notified"
echo ""
echo "WITHIN 1 HOUR:"
echo "  [ ] Engineering management notified (if CRITICAL)"
echo "  [ ] Legal/compliance team notified (if PII/sensitive data involved)"
echo "  [ ] Third-party service provider notified (if their API key)"
echo ""
echo "WITHIN 24 HOURS:"
echo "  [ ] Formal incident report filed"
echo "  [ ] Regulatory notification if required (GDPR, SOC2, etc.)"
```

---

## Investigation (Next 1-2 Hours)

### Step 4: Query Audit Logs for Credential Usage

**Requirement 11.4** — Query audit logs to identify all API requests using the exposed credential.

```bash
# Time window: from credential creation/exposure to rotation
START_TIME="<EXPOSURE_START_TIME>"
END_TIME="<ROTATION_TIME>"
SECRET_NAME="<SECRET_NAME>"
NAMESPACE="<NAMESPACE>"

echo "=== Audit Log Queries for Secret Exposure Investigation ==="

echo "1. Who accessed this secret directly?"
cat << 'EOF'
# Grafana LogQL:
{source="k8s-audit", resource="secrets"}
  | json
  | objectRef_name="<SECRET_NAME>"
  | objectRef_namespace="<NAMESPACE>"
  | line_format "{{.requestReceivedTimestamp}} user={{.user_username}} verb={{.verb}} http={{.responseStatus_code}}"
EOF

echo ""
echo "2. Requests made using the service account that had the secret:"
SA_NAME=$(kubectl get pods -n ${NAMESPACE} -l <APP_LABEL> \
  -o jsonpath='{.items[0].spec.serviceAccountName}' 2>/dev/null || echo "check-manually")
cat << EOF
# Grafana LogQL:
{source="k8s-audit"}
  | json
  | user_username="system:serviceaccount:${NAMESPACE}:${SA_NAME}"
  | line_format "{{.requestReceivedTimestamp}} {{.verb}} {{.resource}} {{.objectRef_namespace}}/{{.objectRef_name}} http={{.responseStatus_code}}"
EOF

echo ""
echo "3. Unusual access patterns in the affected namespace:"
cat << 'EOF'
# Grafana LogQL:
{source="k8s-audit", namespace="<NAMESPACE>"}
  | json
  | user_username !~ "system:serviceaccount:<NAMESPACE>:.*"
  | user_username != "system:node:.*"
  | line_format "{{.requestReceivedTimestamp}} user={{.user_username}} {{.verb}} {{.resource}}"
EOF
```

### Step 5: Assess Unauthorized Access

**Requirement 11.6** — Assess whether the credential was used for unauthorized access.

```bash
echo "=== Unauthorized Access Assessment Checklist ==="
echo ""
echo "For each consuming service, verify:"
echo ""
echo "DATABASE CREDENTIALS:"
echo "  [ ] Review database access logs for the exposed credential"
echo "  [ ] Check for queries matching unexpected data access patterns"
echo "  [ ] Look for data exfiltration indicators (large result sets, COPY commands)"
echo "  Example: SELECT * FROM pg_stat_activity WHERE usename = '<DB_USER>';"
echo ""
echo "API KEYS (GitHub, AWS, GCP, etc.):"
echo "  [ ] Review API provider's audit logs for the key"
echo "  [ ] Check for resource creation, deletion, or data access"
echo "  [ ] GitHub: Settings → Security → Access log"
echo "  [ ] AWS: CloudTrail filter by AccessKeyId"
echo "  [ ] GCP: Cloud Audit Logs filter by caller credentials"
echo ""
echo "KUBERNETES SERVICE ACCOUNT TOKENS:"
echo "  [ ] Review which Kubernetes API calls were made with this token"
echo "  [ ] Check for RBAC privilege escalation attempts"
echo "  [ ] Verify no new ClusterRoleBindings were created"
```

---

## Remediation

### Step 6: Remove Exposed Secret Versions

```bash
# Ensure old secret version is fully removed
kubectl delete secret ${SECRET_NAME} -n ${NAMESPACE} 2>/dev/null || true
kubectl create secret generic ${SECRET_NAME} \
  -n ${NAMESPACE} \
  --from-literal=<KEY>=<ALREADY_ROTATED_NEW_VALUE>

# Rolling restart all pods that used the old secret to pick up the new value
kubectl rollout restart deployment/<DEPLOYMENT_NAME> -n ${NAMESPACE}
kubectl rollout status deployment/<DEPLOYMENT_NAME> -n ${NAMESPACE} --timeout=300s
```

### Step 7: Update Secret Detection Rules

**Requirement 11.8** — Update secret detection rules to prevent recurrence.

```bash
# If the secret was committed to git:
# 1. Add pattern to security/secret-detection/rules/
# 2. Update pre-commit hooks in .pre-commit-config.yaml
# 3. Run retroactive scan:
#    gitleaks detect --source . --report-format json > secret-scan-results.json

# If the secret was exposed via environment variable:
# Add Kyverno policy to prevent env var secret injection:
# policy/kyverno/disallow-env-secrets.yaml

# If the secret was accessed via Kubernetes API:
# Review RBAC permissions for the accessing service account
echo "Update security/secret-detection/ patterns and re-run pipeline scans"
```

---

## Post-Incident

### Step 8: Document the Incident

```markdown
# Incident Report: Secret Exposure

**Incident ID:** INC-YYYYMMDD-HHMMSS
**Date:** YYYY-MM-DD
**Severity:** HIGH/CRITICAL
**Status:** Resolved

## Timeline
- HH:MM - Exposure detected (source: ...)
- HH:MM - Secret rotated in [service]
- HH:MM - Kubernetes Secret updated
- HH:MM - Consuming pods restarted
- HH:MM - Audit log investigation complete
- HH:MM - Unauthorized access: [confirmed/ruled out]

## Exposed Secret
- Secret Name: [kubernetes secret name]
- Credential Type: [database/API key/token]
- Namespace: [namespace]
- Exposure Method: [git commit / env var / k8s API access]
- Exposure Duration: [from X to Y]

## Impact Assessment
- Unauthorized access: [yes/no/under investigation]
- Data accessed: [none / list what was accessed]
- Services affected: [list]

## Remediation
- [x] Credential rotated in external service
- [x] Kubernetes Secret updated
- [x] Consuming pods restarted
- [ ] Detection rule updated

## Lessons Learned
[Root cause and prevention measures]
```

### Step 9: Retrospective Checklist

- [ ] Was the credential rotated within 15 minutes of detection?
- [ ] Were all consuming pods identified and restarted?
- [ ] Was unauthorized access confirmed or ruled out?
- [ ] Were all stakeholders notified within required timeframes?
- [ ] Has the secret detection rule been updated?
- [ ] Has the pre-commit hook been updated to prevent recurrence?
- [ ] Is a post-incident review scheduled?
