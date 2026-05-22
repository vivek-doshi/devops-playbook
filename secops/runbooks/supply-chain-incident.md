# Supply Chain Incident Response Runbook

**Requirements:** 12.1-12.8

This runbook guides incident responders through investigating unsigned or tampered
container images detected by Kyverno supply chain policies.

**Related Runbooks:**
- secops/runbooks/compromised-pod.md (if a compromised image was deployed)

**Related Tools:**
- secops/supply-chain/cosign-verify-policy.yaml
- secops/supply-chain/sbom-policy.yaml
- secops/supply-chain/slsa-verify.yaml
- security/container-scanning/

---

## Severity Classification

| Scenario | Severity | Response Time |
|----------|----------|---------------|
| Unsigned image deployed to production | CRITICAL | Immediate |
| Tampered image (signature mismatch) | CRITICAL | Immediate |
| Image without SBOM attestation | HIGH | 1 hour |
| Image without SLSA provenance | HIGH | 1 hour |
| Policy violation in audit mode | MEDIUM | 4 hours |
| CI/CD pipeline compromise suspected | CRITICAL | Immediate |

---

## Detection

**Requirement 12.2** — Identify the unsigned or tampered image from Kyverno alerts.

### 1. Identify the Policy Violation

Kyverno policy violations appear in:
- PolicyReport resources (always)
- Kubernetes admission denial events (enforce mode)
- Kyverno controller logs

```bash
# Check recent Kyverno policy violations
kubectl get policyreport -A -o json | jq \
  '.items[] | select(.results[]?.result == "fail") |
  {namespace: .metadata.namespace, violations: [.results[] | select(.result == "fail") |
  {policy: .policy, rule: .rule, message: .message}]}'

# Check cluster-wide violations
kubectl get clusterpolicyreport -o json | jq \
  '.items[] | select(.results[]?.result == "fail")'

# Check Kyverno admission events
kubectl get events -A --field-selector reason=PolicyViolation \
  --sort-by='.lastTimestamp' | tail -20

# Check which policy fired
kubectl get events -A | grep -i "verify-image\|verify-sbom\|verify-slsa"
```

### 2. Identify the Image

```bash
# Get the violating image from PolicyReport
NAMESPACE="<NAMESPACE>"
kubectl get policyreport -n ${NAMESPACE} -o json | jq -r \
  '.items[] | .results[] | select(.result == "fail") |
  "Policy: \(.policy)\nRule: \(.rule)\nMessage: \(.message)\n"'

# Image reference will be in the message field
IMAGE="<IMAGE_REFERENCE>"
```

---

## Immediate Actions (First 15 Minutes)

### Step 1: Verify Whether the Image Was Deployed

**Requirement 12.3** — Check if the unsigned/tampered image is already running.

```bash
IMAGE="<IMAGE_REFERENCE>"

# Search all namespaces for running pods using this image
echo "=== Running pods using image: ${IMAGE} ==="
kubectl get pods -A -o json | jq -r \
  --arg img "${IMAGE}" \
  '.items[] | select(.spec.containers[].image == $img or .spec.initContainers[]?.image == $img) |
  "\(.metadata.namespace)/\(.metadata.name): \(.status.phase)"'

# If pods are found running in production, treat as compromised pod
# See: secops/runbooks/compromised-pod.md
```

```bash
# If pods are found, immediately isolate them:
# (Replace with actual namespace/pod names found above)
POD_NAME="<POD_NAME>"
NAMESPACE="<NAMESPACE>"

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: quarantine-unsigned-image-pod
  namespace: ${NAMESPACE}
spec:
  podSelector:
    matchLabels:
      $(kubectl get pod ${POD_NAME} -n ${NAMESPACE} -o jsonpath='{.metadata.labels}' \
        | jq -r 'to_entries[] | "\(.key): \"\(.value)\""')
  policyTypes: [Ingress, Egress]
EOF
```

### Step 2: Quarantine the Image

**Requirement 12.7** — Add the image to a deny list.

```bash
IMAGE="<IMAGE_REFERENCE>"
IMAGE_DIGEST=$(cosign triangulate ${IMAGE} 2>/dev/null | head -1 || echo "unable-to-resolve")

echo "=== Quarantine Image: ${IMAGE} ==="
echo "Digest: ${IMAGE_DIGEST}"

# Add to Kyverno deny list policy
cat <<EOF | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: deny-quarantined-images
  annotations:
    incident-response: "true"
    quarantine-reason: "Supply chain incident - unsigned/tampered image"
    quarantine-date: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: deny-quarantined-image
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "Image ${IMAGE} is quarantined due to supply chain security incident. Contact the security team."
        deny:
          conditions:
            any:
              - key: "{{ request.object.spec.containers[].image }}"
                operator: AnyIn
                value:
                  - "${IMAGE}"
EOF

echo "Image quarantined. All new pods using this image will be rejected."
```

### Step 3: Notify Stakeholders

```bash
echo "=== Incident Notification ==="
echo ""
echo "IMMEDIATE:"
echo "  [ ] Security team notified"
echo "  [ ] Platform/DevOps team notified"
echo "  [ ] Application development team notified (image owners)"
echo "  [ ] CI/CD pipeline owners notified (pipeline may be compromised)"
echo ""
echo "WITHIN 1 HOUR:"
echo "  [ ] Engineering management notified"
echo "  [ ] Container registry admin notified (to prevent image pull)"
```

---

## Investigation (Next 1-2 Hours)

### Step 4: Query Audit Logs for Deployment Attempts

**Requirement 12.4** — Identify who attempted to deploy the image.

```logql
# Grafana LogQL: Pod creation attempts with this image
{source="k8s-audit", resource="pods"} | json
  | verb="create"
  | line_format "{{.requestReceivedTimestamp}} user={{.user_username}} ns={{.objectRef_namespace}} pod={{.objectRef_name}} http={{.responseStatus_code}}"
```

```bash
# Check kubectl config of the user who deployed
echo "=== Deployment Attempt Investigation ==="
echo "1. Identify the user from audit logs (user.username field)"
echo "2. Check their RBAC permissions:"
echo "   kubectl auth can-i create pods --as=<USERNAME> -n <NAMESPACE>"
echo "3. Was this a CI/CD pipeline service account?"
echo "   Check: .github/workflows/ for the workflow that created this image"
```

### Step 5: Verify Image Signature and Provenance

```bash
IMAGE="<IMAGE_REFERENCE>"

echo "=== Image Verification ==="

# 1. Check cosign signature
echo "--- Cosign Signature ---"
cosign verify ${IMAGE} \
  --certificate-identity-regexp="https://github.com/.*/github/workflows/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  2>&1

# 2. Check SBOM attestation
echo ""
echo "--- SBOM Attestation ---"
cosign verify-attestation ${IMAGE} --type spdx 2>&1 | head -20

# 3. Check SLSA provenance
echo ""
echo "--- SLSA Provenance ---"
cosign verify-attestation ${IMAGE} --type slsaprovenance 2>&1 | head -20

# 4. Check Rekor transparency log
echo ""
echo "--- Rekor Transparency Log ---"
rekor-cli search --email noreply@github.com --rekor_server https://rekor.sigstore.dev 2>&1 | head -10
```

### Step 6: Scan Image for Malware

**Requirement 12.5** — Scan the image for malware.

```bash
IMAGE="<IMAGE_REFERENCE>"

echo "=== Malware Scan: ${IMAGE} ==="

# Trivy comprehensive scan
trivy image ${IMAGE} --severity CRITICAL,HIGH --format json > /tmp/trivy-scan.json
cat /tmp/trivy-scan.json | jq '.Results[] | select(.Vulnerabilities != null) |
  .Vulnerabilities[] | select(.Severity == "CRITICAL") |
  {pkg: .PkgName, vuln: .VulnerabilityID, title: .Title}'

# Check for known malware signatures
echo ""
echo "Running malware detection..."
# Option 1: ClamAV
docker run --rm -v /var/lib/docker:/var/lib/docker:ro clamav/clamav:latest \
  clamscan --recursive /var/lib/docker/overlay2 2>/dev/null || true

# Option 2: Falco image scan (if available)
# security/container-scanning/scan-image.sh ${IMAGE}

echo ""
echo "Check security/container-scanning/ for additional scanning tools"
```

### Step 7: Investigate CI/CD Pipeline

**Requirement 12.8** — Investigate the CI/CD pipeline for compromise.

```bash
echo "=== CI/CD Pipeline Investigation ==="
echo ""
echo "1. Check GitHub Actions workflow runs for the image repository:"
echo "   GitHub → Actions → Filter by workflow file"
echo "   Look for: unexpected workflow triggers, unusual commit SHAs"
echo ""
echo "2. Check workflow OIDC token claims:"
echo "   cosign verify-attestation ${IMAGE} --type slsaprovenance | jq '.payload | @base64d | fromjson'"
echo "   Verify: builder.id matches expected workflow path"
echo ""
echo "3. Check for unauthorized access to CI/CD secrets:"
echo "   GitHub → Settings → Secrets → Access log (if available)"
echo "   AWS → CloudTrail for CI/CD role actions"
echo ""
echo "4. Review recent commits to the source repository:"
echo "   git log --since='$(date -u -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)' --oneline"
echo ""
echo "5. Check for dependency confusion or typosquatting:"
echo "   trivy image ${IMAGE} --list-all-pkgs 2>/dev/null | grep -v '^[A-Z]'"
```

---

## Remediation

### Step 8: Remediate Based on Root Cause

```bash
echo "=== Remediation Actions ==="
echo ""
echo "IF image was never signed (legitimate but missing signature):"
echo "  1. Re-run CI/CD pipeline with Cosign signing step"
echo "  2. Remove quarantine policy once signed image is available"
echo "  3. Update CI/CD pipeline to enforce signing: see .github/workflows/"
echo ""
echo "IF image was tampered with after signing:"
echo "  1. Investigate registry access logs for unauthorized pushes"
echo "  2. Rotate registry access credentials"
echo "  3. Rebuild from known-good source code"
echo "  4. Delete tampered image tags from registry"
echo ""
echo "IF CI/CD pipeline was compromised:"
echo "  1. Rotate ALL CI/CD secrets immediately"
echo "  2. Review and revoke all OIDC tokens from the pipeline"
echo "  3. Rebuild the pipeline from scratch if necessary"
echo "  4. Conduct full audit of all images built during compromise window"
```

---

## Post-Incident

### Step 9: Document the Incident

```markdown
# Incident Report: Supply Chain Security Incident

**Incident ID:** INC-YYYYMMDD-HHMMSS
**Date:** YYYY-MM-DD
**Severity:** HIGH/CRITICAL
**Status:** Resolved

## Affected Image
- Image: [full image reference with digest]
- Registry: [registry URL]
- Repository: [source code repository]

## Timeline
- HH:MM - Kyverno policy violation detected
- HH:MM - Image quarantined
- HH:MM - Stakeholders notified
- HH:MM - Running pods identified [and isolated if applicable]
- HH:MM - Root cause identified
- HH:MM - Remediation complete

## Root Cause
[Was image unsigned, tampered, or built by compromised pipeline?]

## Impact
- Production pods running compromised image: [yes/no]
- Data accessed: [none/list]
- CI/CD pipeline compromised: [yes/no]

## Remediation
- [x] Image quarantined
- [x] Compromised pods isolated and replaced
- [x] CI/CD pipeline reviewed
- [ ] Secrets rotated (if pipeline compromised)
```

### Step 10: Retrospective Checklist

- [ ] Did Kyverno policy detect the violation before deployment (enforce mode)?
- [ ] If in audit mode: why was enforcement not enabled?
- [ ] Was the quarantine policy applied within 15 minutes?
- [ ] Was the CI/CD pipeline investigation complete?
- [ ] Have all images built during the compromise window been reviewed?
- [ ] Have the supply chain policies been reviewed and strengthened?
- [ ] Is a post-incident review meeting scheduled?
