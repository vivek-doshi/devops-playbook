# Runbook: `PodCrashLoopBackOff`

---

## Overview

| Field | Value |
|-------|-------|
| **Alert name** | `PodCrashLoopBackOff` |
| **Severity** | critical |
| **Team** | Platform / owning service team |
| **SLO impact** | Yes — if the crashing pod is a service-tier pod, errors will contribute to availability SLO burn |
| **Typical duration before page** | 5 minutes (fires after 3+ restarts in a rolling window) |
| **False positive rate** | Low — occasional single restarts do not fire this alert |

---

## What This Alert Means

A pod has restarted more than 5 times in the last 15 minutes (see `pod-alerts.yaml`).
Kubernetes is repeatedly starting the container, the container crashes almost immediately,
and Kubernetes backs off with an exponential delay before retrying.
The pod will not accept traffic until it stays up long enough for the readiness probe to pass.

---

## User-Facing Impact

Traffic to the affected service may be partially or fully dropped, depending on how many
replicas are healthy. Kubernetes will not route new connections to a crashing pod, so if all
replicas are crashing, the service is down.

---

## Immediate Steps (first 5 minutes)

```bash
# 1. Find the crashing pod and note the restart count
kubectl get pods -n <namespace> -l app=<app-name>

# 2. Read the last crash reason
kubectl describe pod <pod-name> -n <namespace>
# Look for: Last State, Exit Code, Reason

# 3. Read the logs from the previous (crashed) container — not the current one
kubectl logs <pod-name> -n <namespace> --previous

# 4. Check if other replicas are healthy and serving traffic
kubectl get endpoints -n <namespace> <service-name>
```

---

## Diagnosis Checklist

- [ ] **Exit code 1 or 2?** Application process crashed — check application logs above.
- [ ] **Exit code 137?** Killed by OOM killer — check memory limits: `kubectl describe pod`.
- [ ] **Exit code 132 or 139?** Segfault — likely a binary or native dependency issue; escalate to dev team.
- [ ] **Recent deployment?** `kubectl rollout history deployment/<name> -n <namespace>`. Roll back if confirmed: `kubectl rollout undo deployment/<name> -n <namespace>`.
- [ ] **ConfigMap or Secret missing?** `kubectl describe pod` will show `CreateContainerConfigError` if env vars cannot be resolved.
- [ ] **Image pull failure?** Check for `ImagePullBackOff` alongside the CrashLoopBackOff.
- [ ] **Liveness probe too aggressive?** If the process starts slowly, the liveness probe may kill it before it's ready. Increase `initialDelaySeconds` in the Deployment spec.

---

## Likely Causes

### 1. OOM kill (Exit code 137)

**Symptoms:** `kubectl describe pod` shows `OOMKilled` in `Last State > Reason`.

**Resolution:**
```bash
# Check current memory usage trend in Prometheus/Grafana
# Temporarily increase memory limit:
kubectl set resources deployment/<name> -n <namespace> \
  --limits=memory=512Mi          # <-- CHANGE THIS to a suitable value
# File a ticket to right-size the limit based on observed usage
```

### 2. Application crash on startup (Exit code 1)

**Symptoms:** Application logs show a fatal error (missing config, DB unreachable, etc.).

**Resolution:**
```bash
# Read the previous container's logs
kubectl logs <pod-name> -n <namespace> --previous | tail -50

# If a database connection failed — check if the DB pod is up:
kubectl get pods -n <namespace> -l app=<db-name>

# If a required env var is missing:
kubectl describe pod <pod-name> -n <namespace> | grep -A10 "Environment"
```

### 3. Misconfigured startup/liveness probe

**Symptoms:** Pod restarts are very frequent and logs show the application starting successfully before the kill.

**Resolution:**
```bash
# View the probe config
kubectl get deployment <name> -n <namespace> -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'
# Increase initialDelaySeconds:
kubectl edit deployment <name> -n <namespace>
# Adjust spec.template.spec.containers[0].livenessProbe.initialDelaySeconds
```

---

## Grafana Deep-Dive

```
# Loki — logs from the crashing pod (last 30 minutes)
{namespace="<namespace>", pod="<pod-name>"}

# Prometheus — restart rate over last 30 minutes
rate(kube_pod_container_status_restarts_total{namespace="<namespace>"}[30m]) * 60

# Container memory pressure (approaching OOM)
container_memory_working_set_bytes{namespace="<namespace>", container!=""}
/
container_spec_memory_limit_bytes{namespace="<namespace>", container!=""}
```

---

## Escalation

| Condition | Action |
|-----------|--------|
| All replicas crashing | Open incident immediately; notify #incidents |
| Rolling restart not resolving | Escalate to the owning service team |
| OOM with no clear memory leak | Escalate to platform team to review resource quotas |
| Cannot roll back (first deployment) | Escalate to dev team to fix the image |

---

## Resolution

```bash
# Confirm alert has cleared — no pod should have restart count > 5 in 15m:
kubectl get pods -n <namespace>                 # RESTARTS column should be stable

# After rollback, confirm the new ReplicaSet is healthy:
kubectl rollout status deployment/<name> -n <namespace>
```

---

## Post-Incident Actions

- [ ] Confirm root cause was captured in the incident timeline
- [ ] If OOM: right-size memory limits and add a `PodMemoryPressure` alert if not present
- [ ] If startup probe misconfigured: open a PR to fix `initialDelaySeconds`
- [ ] If a dependency was unavailable: confirm circuit-breaker or retry logic is in place

---

## Related

- [`PodMemoryPressure`](./podmemorypressure.md) — early warning before OOM kills
- [`DeploymentReplicasMismatch`](./deploymentreplicasmismatch.md) — fires when pods can't reach desired count
- [`SloFastBurn`](./slofastburn.md) — fires when this crash contributes to error budget burn
- [template.md](./template.md) — blank runbook template
