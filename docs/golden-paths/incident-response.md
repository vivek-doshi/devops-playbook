# Golden Path — Incident Response

> **An opinionated, end-to-end workflow that guides developers from idea → production**

This is an **ops path**, not a build path. It is the standard procedure for diagnosing and resolving production incidents across all services that use this playbook.

---

## When to use this path

- A PagerDuty alert has fired and you are the on-call engineer
- A user reports that a production service is degraded or down
- You need to coordinate a multi-team response to an outage

---

## Severity levels

| Severity | Definition | Initial response time |
|---------|------------|----------------------|
| SEV-1 | Total service outage — no users can access the system | Immediate — wake on-call |
| SEV-2 | Partial outage — significant percentage of users affected | Within 15 minutes |
| SEV-3 | Degraded performance or non-critical feature failure | Within 1 hour |
| SEV-4 | Minor issue, workaround available | Next business day |

---

## Response flow

```
Alert fires (PagerDuty)
       ↓
Acknowledge + join incident channel
       ↓
Assess severity → assign Incident Commander
       ↓
Triage (diagnose root cause)
       ↓
Mitigate (stop the bleeding — rollback / scale / redirect)
       ↓
Resolve (confirm service is healthy)
       ↓
Post-incident review within 48 h
```

---

## Phase 1 — Acknowledge and assemble

### 1.1 Acknowledge the alert

Acknowledge in PagerDuty within 5 minutes to stop escalation.

Alert routing config: [`notifications/pagerduty-notify.yml`](../../notifications/pagerduty-notify.yml)

### 1.2 Open an incident channel

Create a dedicated Slack channel: `#inc-YYYY-MM-DD-<service-name>`

Post the incident record immediately:

```
**Service:** <name>
**Severity:** SEV-X
**Started:** HH:MM UTC
**Incident Commander:** @name
**Current status:** Investigating
**User impact:** <what users are seeing>
```

### 1.3 Assign roles

| Role | Responsibility |
|------|---------------|
| Incident Commander | Coordinates response, controls comms, makes go/no-go calls |
| Technical Lead | Diagnoses and executes fixes |
| Comms Lead | Updates status page and stakeholders (SEV-1/2 only) |

One person can hold multiple roles for SEV-3/4.

Before assigning roles, confirm ownership in the service catalog entry (`catalog/services/<service-name>.yaml`) and use `metadata.owner`, `spec.oncall.pagerduty_service`, and `spec.oncall.slack_channel` as the source of truth for responder routing.

---

## Phase 2 — Triage

### 2.1 Check health at each layer

Work top-down: user-facing → Kubernetes → infrastructure.

```bash
# Is the service returning errors?
curl -I https://my-service.example.com/health

# What does Kubernetes think?
kubectl get pods -n <namespace> -l app=<service>
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20

# Check rollout status
kubectl rollout status deployment/<name> -n <namespace>

# Check all deployments in a namespace for rollout issues
kubectl get deployments -n <namespace> \
  -o custom-columns='NAME:.metadata.name,DESIRED:.spec.replicas,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas'
```

### 2.2 Use the relevant runbook

Every alert links to a runbook. Start there before doing anything else.

| Symptom | Runbook |
|---------|---------|
| Pod restarting repeatedly | [`docs/runbooks/podcrashloobackoff.md`](../runbooks/podcrashloobackoff.md) |
| Other symptoms | [`docs/runbooks/template.md`](../runbooks/template.md) — use this to write a new one |

### 2.3 Read the logs

```bash
# Current container logs
kubectl logs -n <namespace> -l app=<service> --tail=100

# Previous container (if currently crashed)
kubectl logs -n <namespace> <pod-name> --previous

# Follow logs across all pods for a service
kubectl logs -n <namespace> -l app=<service> -f --max-log-requests=10

# Aggregated logs in Grafana Loki
# Query: {app="<service>", namespace="<namespace>"} | json | level="error"
# Dashboard: observability/loki/dashboards/log-explorer.json
```

### 2.4 Check recent changes

A deployment or config change in the last 30 minutes is the most common root cause.

```bash
# Check recent rollout history
kubectl rollout history deployment/<name> -n <namespace>

# Show what changed between revisions
kubectl rollout history deployment/<name> -n <namespace> --revision=<N>

# Check what changed in Git in the last hour
git log --oneline --since="1 hour ago" main

# Check recent ArgoCD syncs
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd | grep -A 20 "History:"
```

### 2.5 Check infrastructure health

| What | Command |
|------|---------|
| Node health | `kubectl get nodes -o wide` |
| Node conditions | `kubectl describe node <node> \| grep -A 10 Conditions` |
| Persistent volumes | `kubectl get pv,pvc -n <namespace>` |
| cert-manager certificates | `kubectl get certificate -n <namespace>` |
| Database connectivity | `kubectl exec -it <pod> -n <namespace> -- nc -zv <db-host> 5432` |

Check cloud provider status pages directly for region-level incidents:
- AWS: https://health.aws.amazon.com
- Azure: https://status.azure.com
- GCP: https://status.cloud.google.com

Disaster recovery procedures (cluster loss, database corruption):
[docs/guides/disaster-recovery.md](../guides/disaster-recovery.md)

---

## Phase 3 — Mitigate

The goal of mitigation is to **stop user impact as fast as possible**, before the root cause is fully understood.

### Option A — Roll back the deployment

If a recent deployment is the cause, roll back immediately:

```bash
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

To roll back to a specific revision:

```bash
# List revisions
kubectl rollout history deployment/<name> -n <namespace>

# Roll back to a specific one
kubectl rollout undo deployment/<name> -n <namespace> --to-revision=<N>
```

> **Note:** Rolling back the Deployment only reverts the app. If a schema migration ran, you must also run the rollback Job. See [docs/guides/database-migrations.md](../guides/database-migrations.md).

### Option B — Scale up

If the issue is capacity (too many requests, node pressure):

```bash
kubectl scale deployment/<name> -n <namespace> --replicas=<N>

# Or patch the HPA max temporarily
kubectl patch hpa <name> -n <namespace> -p '{"spec":{"maxReplicas":<N>}}'
```

### Option C — Redirect traffic

If one region or availability zone is failing, update your ingress or load balancer to redirect to a healthy region. Refer to your environment-specific Terraform config in `terraform/` for networking resources.

### Option D — Disable the feature

If the issue is isolated to a specific feature, disable it via a feature flag or ConfigMap update:

```bash
# Edit the ConfigMap directly (temporary — commit the change after the incident)
kubectl edit configmap <name> -n <namespace>

# Or apply a patched overlay
kubectl apply -k cd/kubernetes/_overlays/<env>/
```

### Option E — Restore from backup (data corruption only)

Follow: [docs/guides/disaster-recovery.md](../guides/disaster-recovery.md)

```bash
# List available Velero backups
velero backup get

# Describe a backup before restoring
velero backup describe <backup-name> --details

# Restore a namespace
velero restore create \
  --from-backup <backup-name> \
  --include-namespaces <namespace>

# Monitor restore progress
velero restore describe <restore-name> --details
```

Velero backup manifests: [`backup/velero/namespace-backup.yaml`](../../backup/velero/namespace-backup.yaml)

---

## Phase 4 — Resolve

Once the service is healthy and user impact has ended:

```bash
# Confirm all pods are running and ready
kubectl get pods -n <namespace> -l app=<service>

# Confirm health endpoint returns 200
curl -I https://my-service.example.com/health

# Check that the HPA is not at max replicas (sign of sustained load)
kubectl get hpa -n <namespace>

# Check error rate has returned to baseline
# Grafana: observability/prometheus/dashboards/slo-burn-rate-configmap.yaml
```

Post to the incident channel:

```
**Status:** RESOLVED
**Resolved at:** HH:MM UTC
**Duration:** X minutes
**Root cause (preliminary):** <one-line summary>
**Fix applied:** <what was done>
**Post-incident review:** scheduled for <date/time>
```

Close the PagerDuty incident.

---

## Phase 5 — Post-incident review

A post-incident review (PIR) is mandatory for SEV-1 and SEV-2. Recommended for SEV-3.

**Complete within 48 hours of resolution.**

### What a good PIR includes

1. **Timeline** — minute-by-minute log of what happened and what actions were taken
2. **Root cause** — the actual technical cause, not the symptom
3. **Contributing factors** — what made the impact worse or the response slower
4. **Action items** — specific, assigned, time-boxed follow-ups

### Write the runbook (if one didn't exist)

Use the template: [`docs/runbooks/template.md`](../runbooks/template.md)

Commit the new runbook to `docs/runbooks/` and link it from the relevant Prometheus alert annotation (`runbook_url`) so the next engineer on-call sees it immediately.

### What not to do

- Do not name individuals as the cause
- Do not skip the PIR because the fix was simple
- Do not close action items without an assignee and due date

---

## Common scenarios quick-reference

| Scenario | First command | Likely fix |
|----------|--------------|-----------|
| All pods in CrashLoopBackOff | `kubectl logs <pod> -n <ns> --previous` | Rollback or fix config/secret |
| OOMKilled pods | `kubectl describe pod <pod> -n <ns>` — look for `OOMKilled` | Increase memory limit in deployment |
| ImagePullBackOff | `kubectl describe pod <pod> -n <ns>` — look for registry error | Fix image tag or registry credentials |
| Zero ready replicas | `kubectl get endpoints <svc> -n <ns>` | Check readiness probe path and port |
| Database connection refused | `kubectl exec -it <pod> -n <ns> -- nc -zv <db-host> 5432` | Check secret, network policy, DB health |
| Disk pressure on node | `kubectl describe node <node>` | Drain and replace the node |
| Certificate expired | `kubectl describe certificate -n <ns>` | Check cert-manager, force renewal |
| HPA not scaling | `kubectl describe hpa <name> -n <ns>` | Check metrics-server, resource requests set |
| ArgoCD sync failed | `kubectl describe application <app> -n argocd` | Fix manifest error, re-sync |

Cert-manager config: [`cd/kubernetes/cert-manager/`](../../cd/kubernetes/cert-manager/)
SLO dashboards: [`observability/prometheus/dashboards/`](../../observability/prometheus/dashboards/)

---

## Tools and files used in incident response

| File | Purpose |
|------|---------|
| [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/) | Alert rule definitions |
| [`observability/prometheus/dashboards/`](../../observability/prometheus/dashboards/) | Grafana dashboards |
| [`observability/loki/dashboards/log-explorer.json`](../../observability/loki/dashboards/log-explorer.json) | Log explorer dashboard |
| [`notifications/pagerduty-notify.yml`](../../notifications/pagerduty-notify.yml) | PagerDuty alert routing |
| [`notifications/slack-notify.yml`](../../notifications/slack-notify.yml) | Slack alert routing |
| [`backup/velero/namespace-backup.yaml`](../../backup/velero/namespace-backup.yaml) | Namespace restore source |
| [`backup/velero/schedule.yaml`](../../backup/velero/schedule.yaml) | Scheduled backup config |
| [`docs/guides/disaster-recovery.md`](../guides/disaster-recovery.md) | Cluster and database recovery |
| [`docs/runbooks/template.md`](../runbooks/template.md) | New runbook template |
| [`cd/gitops/argocd/application.yaml`](../../cd/gitops/argocd/application.yaml) | ArgoCD app config |

---

## Responsibilities

| Role | Owns |
|------|------|
| On-call engineer | Phases 1–4: acknowledge, triage, mitigate, resolve |
| Service owner / tech lead | Phase 5: post-incident review, action items |
| Platform team | Maintains runbooks, alert routing, backup schedules |
