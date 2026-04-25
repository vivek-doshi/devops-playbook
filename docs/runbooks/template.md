# Runbook: `<AlertName>`

<!-- TEMPLATE: WHEN TO USE
     Copy this file for each alert defined in observability/prometheus/alerts/.
     Name the file to match the alert name exactly (lowercase, no spaces):
       docs/runbooks/<alertname>.md
     Then update runbook_url in the PrometheusRule annotation to point to
     your hosted version of this file, e.g.:
       runbook_url: https://runbooks.example.com/<alertname>
     Replace every section below — delete any that do not apply.
-->

---

## Overview

| Field | Value |
|-------|-------|
| **Alert name** | `<AlertName>` |
| **Severity** | critical / warning |
| **Team** | <!-- platform / backend / frontend / data --> |
| **SLO impact** | <!-- Does this alert indicate SLO burn? Which one? --> |
| **Typical duration before page** | <!-- e.g. "fires within 5 minutes of incident start" --> |
| **False positive rate** | <!-- low / medium / high — and known causes --> |

---

## What This Alert Means

<!-- One paragraph aimed at a responder who did not write the alert. -->
<!-- Explain the system behaviour being detected, not just what the PromQL does. -->

---

## User-Facing Impact

<!-- What is the user experiencing right now? -->
<!-- Describe in terms of user actions, not system states. -->

Examples:
- "Users cannot complete checkout — payment requests are returning 500."
- "API response times have increased but requests are still succeeding."
- "No user impact yet, but the error budget will be exhausted in 6 hours if the rate holds."

---

## Immediate Steps (first 5 minutes)

These commands can be run without knowing the root cause. Copy, paste, adapt.

```bash
# 1. Confirm the alert is still firing and check labels
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
# Open http://localhost:9093 → Alerts tab → search for <AlertName>

# 2. Check pod health in the affected namespace
kubectl get pods -n <namespace>                          # <-- CHANGE THIS
kubectl describe pod <pod-name> -n <namespace>           # <-- CHANGE THIS

# 3. Tail recent logs for the affected service
kubectl logs -n <namespace> -l app=<app-name> --tail=100 # <-- CHANGE THIS
# or via Grafana: Explore → Loki → {app="<app-name>"}    # <-- CHANGE THIS

# 4. Check the relevant metric directly in Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090 and run:
# <paste the alert PromQL expression here>
```

---

## Diagnosis Checklist

Work through this list in order. Stop when you find the cause.

- [ ] **Recent deployment?** Check `kubectl rollout history deployment/<name> -n <namespace>`. If yes, consider rollback: `kubectl rollout undo deployment/<name> -n <namespace>`.
- [ ] **Upstream dependency down?** Check the dependency's health endpoint or status page.
- [ ] **Resource exhaustion?** Check CPU/memory: `kubectl top pods -n <namespace>`.
- [ ] **Node pressure?** Check `kubectl describe nodes` for `MemoryPressure` or `DiskPressure` conditions.
- [ ] **HPA at maximum replicas?** Check `kubectl get hpa -n <namespace>`.
- [ ] **Certificate or secret expired?** Check `kubectl get secrets -n <namespace>` and describe any TLS secrets.
- [ ] **Infrastructure incident?** Check the cloud provider status page (AWS / Azure / GCP).
- [ ] **Configuration change?** Check recent ConfigMap changes: `kubectl get configmap -n <namespace> -o yaml`.

---

## Likely Causes

<!-- Order by frequency. Each cause should have a one-line description and a resolution path. -->

### 1. `<Cause description>`

**Symptoms:** <!-- What else you'd see in logs, metrics, or the alert labels. -->

**Resolution:**
```bash
# Commands to resolve this cause
```

### 2. `<Cause description>`

**Symptoms:** <!-- ... -->

**Resolution:**
```bash
# ...
```

---

## Grafana Deep-Dive

Replace `<service>`, `<namespace>`, and time range as appropriate.

```
# Loki — recent errors for this service
{namespace="<namespace>", app="<service>"} |= "error" | logfmt   # <-- CHANGE THIS

# Tempo — find recent traces with errors from this service
{ resource.service.name = "<service>" && status = error }         # <-- CHANGE THIS

# Prometheus — error rate over last 15 minutes
sum(rate(http_requests_total{job="<service>", code=~"5.."}[5m]))  # <-- CHANGE THIS
/
sum(rate(http_requests_total{job="<service>"}[5m]))
```

---

## Escalation

| Condition | Action |
|-----------|--------|
| Unable to identify cause within 15 minutes | Escalate to <!-- team / person --> |
| User-facing impact confirmed | Notify <!-- #incident-channel --> and open incident |
| Data loss possible | Immediately notify <!-- security/data owner --> |
| Cannot roll back or resolve in 30 minutes | Engage cloud support |

---

## Resolution

Once the root cause is resolved:

```bash
# Verify the alert has cleared in Alertmanager
# Verify the metric has returned below the threshold in Prometheus

# If you applied a temporary workaround (e.g. increased replicas, silenced the alert),
# create a follow-up ticket before closing the incident.
```

Silence the alert during planned maintenance (prefer short windows with expiry):
```bash
# Silence via Alertmanager UI at http://localhost:9093 → New Silence
# Match on: alertname="<AlertName>", namespace="<namespace>"
# Set expiry to the end of the maintenance window
```

---

## Post-Incident Actions

- [ ] Update this runbook with any new diagnostic steps discovered during the incident
- [ ] File a ticket if a temporary workaround is still in place
- [ ] If this alert fired falsely, consider adjusting the `for:` duration or threshold
- [ ] Conduct a blameless post-mortem if user impact exceeded 15 minutes: [docs/decisions/](../decisions/)

---

## Related

<!-- Link to related alerts, runbooks, dashboards, and architecture docs. -->

- Related alert: [`<OtherAlertName>`](./<otheralertname>.md)
- Architecture: [`docs/guides/environment-strategy.md`](../guides/environment-strategy.md)
- SLO rules: [`observability/prometheus/alerts/slo-rules.yaml`](../../observability/prometheus/alerts/slo-rules.yaml)
