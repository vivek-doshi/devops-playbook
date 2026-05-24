# Runbook: SLO Burn-Rate Breach Response

---

## Overview

| Field | Value |
|-------|-------|
| **Alert name** | `SLOBurnRateCritical` / `SLOBurnRateHigh` / `SLOBurnRateMedium` / `SLOBurnRateLow` |
| **Severity** | critical / warning / info |
| **Team** | Service team + platform on-call |
| **SLO impact** | Direct - indicates active error budget consumption |
| **Typical duration before page** | Tier-based (2m, 15m, 1h, 3h) |
| **False positive rate** | Low when recording rules are healthy |

---

## Symptoms

This alert family indicates your service is consuming error budget faster than allowed.

- Tier 1 means immediate user-impact risk and rapid budget exhaustion.
- Tier 2 means sustained elevated risk that will become an outage if ignored.
- Tier 3 and Tier 4 indicate a reliability trend that needs proactive correction.

---

## Severity Triage

| Alert tier | Burn rate | Time to exhaustion | Immediate action |
|---|---|---|---|
| Critical (Tier 1) | >= 14.4x | ~2 hours | Page, open incident channel NOW |
| High (Tier 2) | >= 6x | ~5 days | Page, investigate within 15 minutes |
| Medium (Tier 3) | >= 3x | ~10 days | Ticket, investigate within 1 hour |
| Low (Tier 4) | >= 1x | End of month | Review in next standup |

---

## Investigation Steps

1. Check SLO dashboard and compare current error ratio against SLO target.
2. Identify failing request classes:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# In Prometheus UI:
http_requests_total{job="<service>", status_code=~"5.."}
```

3. Correlate with recent deployments:

```bash
kubectl rollout history deployment/<name> -n <namespace>
```

4. Check pod health and restart symptoms:
   - [docs/runbooks/podcrashloobackoff.md](podcrashloobackoff.md)
5. Check error budget remaining. If below 10%, escalate to SEV-1 regardless of current burn-rate tier.

---

## Mitigation Options

- Roll back deployment if a recent release caused the burn.
- Scale up if the burn is load-related.
- Disable feature flag if burn is isolated to one feature path.
- If budget remaining is less than 10%:
  - Halt non-critical deployments for this service
  - Allow only rollbacks and critical fixes

These align to incident-response Phase 3 actions in [docs/golden-paths/incident-response.md](../golden-paths/incident-response.md).

---

## Immediate Commands (first 5 minutes)

```bash
# Check current burn and budget
kubectl -n monitoring exec -it <prometheus-pod> -- \
  promtool query instant http://localhost:9090 'slo:api_gateway:availability_burn_rate:1h'

kubectl -n monitoring exec -it <prometheus-pod> -- \
  promtool query instant http://localhost:9090 'slo:api_gateway:availability_error_budget_remaining:30d'

# Correlate with rollout
kubectl rollout history deployment/<name> -n <namespace>
kubectl get pods -n <namespace>
```

---

## Resolution

- Verify alert clears in Alertmanager.
- Verify burn-rate windows fall below threshold.
- Confirm user-facing metrics recover.

---

## Post-Incident

- Record incident details and alert tier timeline.
- Add findings to quarterly SLO review inputs.
- Update SLO policy if this breach exposed policy gaps.
