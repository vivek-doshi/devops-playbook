# Node Compromise Incident Response Runbook
# Requirements: 13.1–13.8
#
# This runbook guides incident responders through safely removing a compromised
# Kubernetes node while preserving forensic evidence.
#
# Related Runbooks:
#   - secops/runbooks/compromised-pod.md (for pods on the compromised node)
# Related Tools:
#   - secops/runtime/falco/ (Falco may have detected the initial compromise)
#   - secops/runtime/audit-logging/ (audit logs in Loki)

---

## Severity Classification

| Indicator | Severity | Response Time |
|-----------|----------|---------------|
| Container escape to host confirmed | CRITICAL | Immediate |
| Unauthorized root access to node | CRITICAL | Immediate |
| Kernel exploit detected | CRITICAL | Immediate |
| Unexpected cron jobs on host | HIGH | 30 minutes |
| Suspicious outbound connection from node | HIGH | 30 minutes |
| Unexpected kernel module loaded | HIGH | 30 minutes |

---

## Detection

**Requirement 13.2** — Confirm node compromise indicators.

### 1. Identify the Compromised Node

```bash
NODE_NAME="<NODE_NAME>"

# Check Falco alerts for this node
# Grafana LogQL:
# {source="falco-runtime-security", node="${NODE_NAME}"} | json | priority=~"CRITICAL|ERROR"

# Check node status
kubectl get node ${NODE_NAME} -o wide
kubectl describe node ${NODE_NAME}

# Check recent events on this node
kubectl get events -A --field-selector \
  involvedObject.name=${NODE_NAME},involvedObject.kind=Node \
  --sort-by='.lastTimestamp'
```

### 2. Identify Indicators of Compromise

Common indicators on a compromised node:
- Unexpected processes running as root
- New kernel modules loaded
- Modified system binaries (check with `rpm -Va` or `debsums`)
- Unexpected cron jobs or systemd services
- New network connections from the node IP
- SSH authorized_keys modifications
- Container escape artifacts (e.g., `/proc/sysrq-trigger` access)

---

## Immediate Actions (First 15 Minutes)

### Step 1: Cordon the Node

**Requirement 13.2** — Cordon the node to prevent new pod scheduling.

```bash
NODE_NAME="<NODE_NAME>"

# Immediately cordon - prevent new pods from scheduling
kubectl cordon ${NODE_NAME}

echo "Node ${NODE_NAME} cordoned. No new pods will be scheduled."
echo "Existing pods will continue running until manually evicted."

# Verify cordon
kubectl get node ${NODE_NAME}
```

### Step 2: Capture Forensic Evidence BEFORE Draining

**Requirement 13.3** — Capture forensic evidence from the node.

```bash
NODE_NAME="<NODE_NAME>"
INCIDENT_ID="INC-$(date +%Y%m%d-%H%M%S)"
EVIDENCE_DIR="/tmp/${INCIDENT_ID}/node-${NODE_NAME}"
mkdir -p ${EVIDENCE_DIR}

# Get node IP for SSH access
NODE_IP=$(kubectl get node ${NODE_NAME} -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
echo "Node IP: ${NODE_IP}"
echo "Evidence directory: ${EVIDENCE_DIR}"

echo "=== SSH into node for forensic capture ==="
echo "Command: ssh -i <KEY> <USER>@${NODE_IP}"
echo ""
echo "Run the following on the NODE (not from kubectl):"
echo ""

cat << 'FORENSIC_COMMANDS'
# On the compromised node - run as root:

# 1. Save current process list
ps auxf > /tmp/processes-$(date +%s).txt

# 2. Save network connections
ss -tulnp > /tmp/network-$(date +%s).txt
netstat -tulnp >> /tmp/network-$(date +%s).txt

# 3. Save kernel modules
lsmod > /tmp/kernel-modules-$(date +%s).txt

# 4. Save currently logged-in users
who > /tmp/who-$(date +%s).txt
last -n 50 > /tmp/last-logins-$(date +%s).txt

# 5. Save cron jobs
for user in $(cut -f1 -d: /etc/passwd); do
  crontab -u ${user} -l 2>/dev/null && echo "--- user: ${user} ---"
done > /tmp/crontabs-$(date +%s).txt
cat /etc/cron.d/* > /tmp/cron-d-$(date +%s).txt 2>/dev/null || true
cat /etc/crontab > /tmp/crontab-$(date +%s).txt 2>/dev/null || true

# 6. Check for unauthorized SSH keys
find /root /home -name authorized_keys -exec cat {} \; 2>/dev/null > /tmp/ssh-keys-$(date +%s).txt

# 7. Check recently modified files (last 24 hours)
find / -newer /proc/1 -not -path '/proc/*' -not -path '/sys/*' \
  -not -path '/run/*' -not -path '/tmp/*' 2>/dev/null \
  > /tmp/modified-files-$(date +%s).txt

# 8. Capture system logs
journalctl --since "24 hours ago" > /tmp/journal-$(date +%s).txt

# 9. Check kernel logs for exploit indicators
dmesg > /tmp/dmesg-$(date +%s).txt

# 10. Capture container runtime state
crictl ps -a > /tmp/containers-$(date +%s).txt 2>/dev/null || \
  docker ps -a > /tmp/containers-$(date +%s).txt 2>/dev/null || true

# 11. Check for new systemd services
systemctl list-units --state=active --type=service > /tmp/services-$(date +%s).txt

# Compress all evidence
tar -czf /tmp/forensics-$(date +%s).tar.gz /tmp/*.txt 2>/dev/null

echo "Evidence captured. Transfer to secure storage before draining."
FORENSIC_COMMANDS
```

### Step 3: Preserve Audit Logs from Loki

**Requirement 13.4** — Preserve audit logs for all pods that ran on the node.

```bash
NODE_NAME="<NODE_NAME>"

echo "=== Audit Log Preservation ==="
echo ""
echo "1. All API operations for pods on this node (last 24 hours):"
echo "   Grafana LogQL:"
cat << 'EOF'
{source="k8s-audit"}
  | json
  | line_format "{{.requestReceivedTimestamp}} user={{.user_username}} {{.verb}} {{.resource}} {{.objectRef_namespace}}/{{.objectRef_name}}"
EOF

echo ""
echo "2. Get all pods that ran on this node:"

# Current pods
kubectl get pods -A --field-selector spec.nodeName=${NODE_NAME} \
  -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"' \
  > /tmp/pods-on-node-${NODE_NAME}.txt
echo "Current pods on node: $(wc -l < /tmp/pods-on-node-${NODE_NAME}.txt)"
cat /tmp/pods-on-node-${NODE_NAME}.txt

echo ""
echo "3. For each pod listed, query audit logs in Loki:"
echo "   {source=\"k8s-audit\", namespace=\"<NS>\"} | json | objectRef_name=\"<POD_NAME>\""
```

---

## Investigation (Next 1-2 Hours)

### Step 4: Drain the Node

**Requirement 13.5** — Drain the node to migrate workloads safely.

```bash
NODE_NAME="<NODE_NAME>"

# Drain with eviction - migrate pods to healthy nodes
# Use --force only if pods are not managed by a controller
kubectl drain ${NODE_NAME} \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=60 \
  --timeout=5m

echo "Node ${NODE_NAME} drained. All manageable pods migrated."

# Verify all pods have been rescheduled
echo "Pods still on node (daemonsets only):"
kubectl get pods -A --field-selector spec.nodeName=${NODE_NAME}
```

### Step 5: Take Disk Snapshot for Forensic Analysis

**Requirement 13.6** — Snapshot the node disk for forensic analysis.

```bash
NODE_NAME="<NODE_NAME>"

echo "=== Disk Snapshot for Forensic Analysis ==="
echo ""
echo "Cloud-specific snapshot procedures:"
echo ""
echo "AWS EC2:"
echo "  INSTANCE_ID=\$(aws ec2 describe-instances --filters 'Name=private-dns-name,Values=${NODE_NAME}' \\"
echo "    --query 'Reservations[0].Instances[0].InstanceId' --output text)"
echo "  VOLUME_ID=\$(aws ec2 describe-instances --instance-id \${INSTANCE_ID} \\"
echo "    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)"
echo "  aws ec2 create-snapshot --volume-id \${VOLUME_ID} \\"
echo "    --description 'Forensic snapshot - incident ${INCIDENT_ID}' \\"
echo "    --tag-specifications 'ResourceType=snapshot,Tags=[{Key=incident,Value=${INCIDENT_ID}}]'"
echo ""
echo "GCP:"
echo "  INSTANCE=\$(kubectl get node ${NODE_NAME} -o jsonpath='{.spec.providerID}' | awk -F/ '{print \$NF}')"
echo "  ZONE=\$(gcloud compute instances list --filter=name=\${INSTANCE} --format='value(zone)')"
echo "  gcloud compute disks snapshot \${INSTANCE} --zone=\${ZONE} \\"
echo "    --snapshot-names=forensic-${INCIDENT_ID,,}"
echo ""
echo "Azure:"
echo "  az snapshot create --resource-group <RG> --name forensic-${INCIDENT_ID} \\"
echo "    --source \$(az vm show -n ${NODE_NAME} -g <RG> --query 'storageProfile.osDisk.managedDisk.id' -o tsv)"
```

### Step 6: Terminate and Replace the Node

**Requirement 13.7** — Terminate and replace the compromised node.

```bash
NODE_NAME="<NODE_NAME>"

# Delete the node from Kubernetes (marks it for replacement)
kubectl delete node ${NODE_NAME}

echo "Node ${NODE_NAME} removed from Kubernetes cluster."
echo ""
echo "Cloud-specific node termination:"
echo ""
echo "AWS (Auto Scaling Group):"
echo "  INSTANCE_ID=\$(aws ec2 describe-instances --filters 'Name=private-dns-name,Values=${NODE_NAME}' \\"
echo "    --query 'Reservations[0].Instances[0].InstanceId' --output text)"
echo "  # Terminate and allow ASG to replace:"
echo "  aws autoscaling terminate-instance-in-auto-scaling-group \\"
echo "    --instance-id \${INSTANCE_ID} --should-decrement-desired-capacity false"
echo ""
echo "GCP (Managed Instance Group):"
echo "  gcloud compute instance-groups managed delete-instances <MIG_NAME> \\"
echo "    --instances=${NODE_NAME} --zone=<ZONE>"
echo ""
echo "After termination, verify new node joins cluster:"
echo "  watch kubectl get nodes"
```

### Step 7: Analyze Node Image for Vulnerabilities

**Requirement 13.8** — Analyze the node image for vulnerabilities or misconfigurations.

```bash
echo "=== Node Image Analysis ==="
echo ""
echo "1. Identify the node OS and kernel version from saved evidence"
echo "   (from /tmp/processes-*.txt or journalctl output)"
echo ""
echo "2. Check for known kernel exploits:"
echo "   trivy vm <DISK_SNAPSHOT_ID>  # If using Trivy for VM scanning"
echo "   # Or: kube-bench run on a fresh node with the same image"
echo ""
echo "3. Run kube-bench against the node image:"
echo "   kubectl apply -f secops/compliance/kube-bench-job.yaml"
echo "   # This checks CIS Benchmark compliance of the current node configuration"
echo ""
echo "4. Check if the node AMI/image has published CVEs:"
echo "   # AWS: Check Security Bulletins for the EKS-optimized AMI version"
echo "   # GCP: Check GKE release notes for OS patch versions"
echo "   # Azure: Check AKS node pool OS image security updates"
echo ""
echo "5. Review Falco detections for container escape patterns:"
echo "   Grafana LogQL: {source=\"falco-runtime-security\", node=\"${NODE_NAME}\"}"
echo "     | json | tags=~\"escape|namespace|privilege_escalation\""
```

---

## Post-Incident

### Step 8: Document the Incident

```markdown
# Incident Report: Node Compromise

**Incident ID:** INC-YYYYMMDD-HHMMSS
**Date:** YYYY-MM-DD  
**Severity:** CRITICAL
**Status:** Resolved

## Compromised Node
- Node: [node name]
- IP: [node IP]
- OS: [OS version]
- Kernel: [kernel version]
- Node pool/ASG: [identifier]

## Timeline
- HH:MM - Compromise detected (source: Falco/external)
- HH:MM - Node cordoned
- HH:MM - Forensic evidence captured
- HH:MM - Audit logs preserved in Loki
- HH:MM - Node drained
- HH:MM - Disk snapshot taken
- HH:MM - Node terminated
- HH:MM - Replacement node verified healthy

## Forensic Evidence
- Evidence archive: /tmp/INC-xxx/forensics-*.tar.gz
- Disk snapshot: [cloud snapshot ID]
- Audit logs: Loki (queries documented above)

## Affected Pods
[List all pods that ran on the compromised node]
[Were any pods compromised? → See compromised-pod.md]

## Root Cause
[How was the node compromised? Container escape / direct SSH / kernel exploit?]

## Impact
- Pods affected: [number]
- Data accessed: [none/list]
- Container escapes: [yes/no]

## Remediation
- [x] Node cordoned and drained
- [x] Forensic evidence preserved
- [x] Node terminated and replaced
- [ ] Root cause patched in node image
- [ ] CIS Benchmark scan run on replacement node

## Lessons Learned
[What vulnerability enabled this compromise and how was it fixed?]
```

### Step 9: Retrospective Checklist

- [ ] Was Falco running on the compromised node and did it detect the attack?
- [ ] Was the node cordoned within 15 minutes of detection?
- [ ] Was forensic evidence captured before node drain/termination?
- [ ] Was a disk snapshot taken for forensic preservation?
- [ ] Were all pods on the compromised node reviewed for compromise?
- [ ] Was the root cause identified and patched in the node image?
- [ ] Was a CIS Benchmark scan run on the replacement node?
- [ ] Have Falco rules been updated to detect this attack pattern earlier?
- [ ] Is a post-incident review meeting scheduled within 5 business days?
