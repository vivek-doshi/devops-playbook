# Runbook: SLO Quarterly Review

---

## Overview

| Field | Value |
|-------|-------|
| **Purpose** | Reliability planning session, not incident response |
| **Cadence** | Quarterly |
| **Duration** | 60 minutes |
| **Output** | Target decision + updated error-budget policy |
| **Participants** | Service team, platform engineer, stakeholder (product or engineering manager) |

---

## Inputs Required

Gather before the meeting:

```bash
# Error budget remaining snapshot
kubectl exec -n monitoring <prometheus-pod> -- \
  promtool query instant http://localhost:9090 'slo:<service>:error_budget_remaining:30d'
```

- Alert history by tier and MTTR from Alertmanager/Grafana.
- Incident log for SLO violations from [docs/golden-paths/incident-response.md](../golden-paths/incident-response.md).

---

## Agenda (60 minutes)

1. 10 min - Review error budget consumption: did we use more or less than expected?
2. 10 min - Review alert history: were severity and timing accurate?
3. 15 min - Review incidents: causes and remediation status.
4. 15 min - Decision: tighten, maintain, or relax target.
5. 10 min - Update error-budget policy and owners.

---

## Error Budget Policy Template

```yaml
# docs/slo-policies/<service>-error-budget-policy.yaml
service: api-gateway
slo_target: 99.9%
error_budget_monthly_minutes: 43.8

policy:
  below_50_percent_remaining:
    action: normal operations, proceed with planned changes
  below_25_percent_remaining:
    action: pause non-critical feature work, prioritize reliability improvements
    owner: engineering manager
  below_10_percent_remaining:
    action: halt all deployments except rollbacks and critical fixes
    owner: engineering director approval required
  exhausted:
    action: incident response, all hands on reliability
    escalation: VP Engineering
```

---

## Decision Criteria

- Tighten target (for example 99.9% to 99.95%) only if:
  - budget remained above 80% consistently
  - service is business-critical
  - team has capacity to sustain additional on-call burden
- Maintain target by default when budget usage and response quality are healthy.
- Relax target (for example 99.9% to 99.5%) only if:
  - budget is exhausted repeatedly despite mitigation effort
  - brief outages are acceptable to business
  - reliability work needs temporary feature-delivery balance

---

## Exit Checklist

- [ ] Target decision documented
- [ ] Error budget policy updated in docs/slo-policies/
- [ ] Follow-up actions assigned with owners and dates
- [ ] Next quarterly review scheduled
