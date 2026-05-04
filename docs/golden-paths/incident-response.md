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

```
notifications/pagerduty-notify.yml   ← alert routing config
```

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
bash scripts/k8s-rollout-check.sh <namespace> <deployment>
```

Script: [`scripts/k8s-rollout-check.sh`](../../scripts/k8s-rollout-check.sh)

### 2.2 Use the relevant runbook

Every alert should link to a runbook. Start there.

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

# Aggregated logs in Grafana Loki
# observability/loki/ — query: {app="<service>", namespace="<namespace>"}
```

### 2.4 Check recent changes

A deployment or config change in the last 30 minutes is the most common root cause.

```bash
# Check recent rollout history
kubectl rollout history deployment/<name> -n <namespace>

# Check what changed in Git
git log --oneline --since="30 minutes ago" main
```

### 2.5 Check infrastructure health

| What | Where |
|------|-------|
| Node health | `kubectl get nodes` |
| Persistent volumes | `kubectl get pv,pvc -n <namespace>` |
| Cloud provider status | AWS Health Dashboard / Azure Status / GCP Status |
| Database | Check Prometheus alert for `PostgresDown` or `RDSConnectionErrors` |

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
kubectl rollout undo deployment/<name> -n <namespace> --to-revision=<N>
```

### Option B — Scale up

If the issue is capacity (too many requests, node pressure):

```bash
kubectl scale deployment/<name> -n <namespace> --replicas=<N>
```

### Option C — Redirect traffic

If one region or availability zone is failing, update your ingress or load balancer to redirect to a healthy region. Refer to your environment-specific networking config in `terraform/`.

### Option D — Disable the feature

If the issue is isolated to a specific feature, disable it via a feature flag or config map update:

```bash
kubectl edit configmap <name> -n <namespace>
# or apply a patched overlay from cd/kubernetes/_overlays/<env>/
```

### Option E — Restore from backup (data corruption only)

Follow: [docs/guides/disaster-recovery.md](../guides/disaster-recovery.md)

Velero backup manifests: [`backup/velero/namespace-backup.yaml`](../../backup/velero/namespace-backup.yaml)

---

## Phase 4 — Resolve

Once the service is healthy and user impact has ended:

```bash
# Confirm all pods are running and ready
kubectl get pods -n <namespace> -l app=<service>

# Confirm health endpoint returns 200
curl -I https://my-service.example.com/health

# Check error rate has returned to baseline in Prometheus/Grafana
# observability/prometheus/dashboards/ → your service dashboard
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

Commit the new runbook to `docs/runbooks/` and link it from the relevant Prometheus alert annotation so the next engineer on-call sees it immediately.

### What not to do

- Do not name individuals as the cause
- Do not skip the PIR because the fix was simple
- Do not close action items without an assignee and due date

---

## Common scenarios quick-reference

| Scenario | First command | Likely fix |
|----------|--------------|-----------|
| All pods in CrashLoopBackOff | `kubectl logs <pod> --previous` | Rollback or fix config |
| OOMKilled pods | `kubectl describe pod <pod>` — look for `OOMKilled` | Increase memory limit |
| ImagePullBackOff | `kubectl describe pod <pod>` — look for registry error | Fix image tag or registry credentials |
| Zero ready replicas | `kubectl get endpoints <svc>` | Check readiness probe |
| Database connection refused | `kubectl exec -it <pod> -- nc -zv <db-host> 5432` | Check secret, network policy, DB health |
| Disk pressure on node | `kubectl describe node <node>` | `docker system prune` or drain node |
| Certificate expired | `kubectl describe certificate -n <namespace>` | Check cert-manager, renew manually |

Cert-manager config: [`cd/kubernetes/cert-manager/`](../../cd/kubernetes/cert-manager/)

---

## Tools and files used in incident response

| File | Purpose |
|------|---------|
| [`scripts/k8s-rollout-check.sh`](../../scripts/k8s-rollout-check.sh) | Check rollout health across all deployments in a namespace |
| [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/) | Alert rule definitions |
| [`observability/prometheus/dashboards/`](../../observability/prometheus/dashboards/) | Grafana dashboards |
| [`notifications/pagerduty-notify.yml`](../../notifications/pagerduty-notify.yml) | PagerDuty alert routing |
| [`notifications/slack-notify.yml`](../../notifications/slack-notify.yml) | Slack alert routing |
| [`backup/velero/namespace-backup.yaml`](../../backup/velero/namespace-backup.yaml) | Namespace restore source |
| [`docs/guides/disaster-recovery.md`](../guides/disaster-recovery.md) | Cluster and database recovery |
| [`docs/runbooks/template.md`](../runbooks/template.md) | New runbook template |

---

## Responsibilities

| Role | Owns |
|------|------|
| On-call engineer | Phases 1–4: acknowledge, triage, mitigate, resolve |
| Service owner / tech lead | Phase 5: post-incident review, action items |
| Platform team | Maintains runbooks, alert routing, backup schedules |
