# Runbook Template: Alert Response

Use this template for alerts defined in `observability/prometheus/alerts/`.

Naming convention for new runbooks:
- `docs/runbooks/<alertname>.md`
- Use lowercase and no spaces.

After creating the runbook, update the alert annotation with a hosted `runbook_url`.

---

## Overview

| Field | Value |
|-------|-------|
| **Alert name** | `<AlertName>` |
| **Severity** | critical / warning / info |
| **Team** | platform / backend / frontend / data |
| **SLO impact** | Describe whether this contributes to SLO burn |
| **Typical time to page** | Example: fires within 5 minutes |
| **False positive rate** | low / medium / high and known causes |

---

## What This Alert Means

Write one short paragraph for responders who did not author the alert.
Focus on observed system behavior, not only PromQL syntax.

---

## User-Facing Impact

Describe impact in user terms.

Examples:
- Users cannot complete checkout due to 500 responses.
- API latency increased, but requests still succeed.
- No user impact yet; current rate will exhaust budget in six hours.

---

## Immediate Steps (First 5 Minutes)

```bash
# 1. Confirm alert is still firing
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
# Open http://localhost:9093 and find <AlertName>

# 2. Check pod health
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>

# 3. Check recent logs
kubectl logs -n <namespace> -l app=<app-name> --tail=100

# 4. Validate metric directly
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090 and run alert expression
```

---

## Diagnosis Checklist

- [ ] Recent deployment regression?
- [ ] Upstream dependency outage?
- [ ] CPU or memory exhaustion?
- [ ] Node pressure (`MemoryPressure`, `DiskPressure`)?
- [ ] HPA at max replicas?
- [ ] Certificate or secret expiration?
- [ ] Cloud provider incident?
- [ ] ConfigMap or runtime configuration drift?

---

## Likely Causes

### 1. `<Cause>`

Symptoms:
- Add expected logs/metrics signs.

Resolution:
```bash
# Add concrete remediation commands
```

### 2. `<Cause>`

Symptoms:
- Add expected logs/metrics signs.

Resolution:
```bash
# Add concrete remediation commands
```

---

## Grafana Deep-Dive

```text
# Loki
{namespace="<namespace>", app="<service>"} |= "error"

# Tempo
{ resource.service.name = "<service>" && status = error }

# Prometheus
sum(rate(http_requests_total{job="<service>", code=~"5.."}[5m]))
/
sum(rate(http_requests_total{job="<service>"}[5m]))
```

---

## Escalation

| Condition | Action |
|-----------|--------|
| Cause unknown after 15 minutes | Escalate to owning team |
| User-facing impact confirmed | Open incident and notify on-call channel |
| Data loss risk | Escalate to security/data owner immediately |
| No recovery in 30 minutes | Engage cloud/platform support |

---

## Resolution

After mitigation:
1. Confirm alert clears in Alertmanager.
2. Confirm metric returns below threshold.
3. Remove temporary workarounds or track them with follow-up tickets.

Use short-lived silences only for planned maintenance windows.

---

## Post-Incident Actions

- [ ] Update this runbook with lessons learned.
- [ ] Create follow-up ticket for temporary fixes.
- [ ] Tune threshold or duration if alert quality is poor.
- [ ] Run blameless postmortem for significant user impact.

---

## Related

- Related alerts and runbooks.
- Architecture references.
- SLO definitions and policies.
