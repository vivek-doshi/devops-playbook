# SLO Reference

Use this directory as the canonical SLO definition and implementation reference.

Start here for end-to-end implementation:

- [docs/golden-paths/slo-driven-development.md](../../../docs/golden-paths/slo-driven-development.md)

---

## Four Burn-Rate Tiers

| Tier | Burn rate | Windows | Response |
|---|---|---|---|
| Tier 1 | 14.4x | 1h AND 5m | Critical page |
| Tier 2 | 6x | 6h AND 30m | Critical page |
| Tier 3 | 3x | 24h AND 2h | Warning ticket |
| Tier 4 | 1x | 72h AND 6h | Info warning |

These values follow the Google SRE Workbook multi-window model and should not be changed.

---

## Recording Rule Naming Convention

All SLO recording rules must follow:

`slo:<service>:<metric>:<window>`

Examples:

- `slo:api_gateway:availability_error_ratio:1h`
- `slo:api_gateway:availability_burn_rate:6h`
- `slo:api_gateway:availability_error_budget_remaining:30d`

---

## Active SLO Discovery

List all active SLO PrometheusRule resources:

```bash
kubectl get prometheusrule -A -l slo=true
```

---

## Check Current Error Budget

```bash
kubectl exec -n monitoring <prometheus-pod> -- \
  promtool query instant http://localhost:9090 'slo:<service>:error_budget_remaining:30d'
```

---

## Quarterly Review Cadence

SLOs are reviewed quarterly with service + platform + stakeholder attendance.

Runbook:

- [docs/runbooks/slo-quarterly-review.md](../../../docs/runbooks/slo-quarterly-review.md)

---

## Directory Contents

| File | Purpose |
|---|---|
| `slo-schema.yaml` | Canonical SLO definition schema teams copy first |
| `my-service-availability-slo.yaml` | Example availability SLO |
| `my-service-latency-slo.yaml` | Example latency SLO |
| `availability-slo.yaml` | Existing PrometheusRule pattern (legacy style) |
| `latency-slo.yaml` | Existing PrometheusRule pattern (legacy style) |

---

## Related Assets

- [observability/prometheus/recording-rules/slo-burn-rates.yaml](../recording-rules/slo-burn-rates.yaml)
- [observability/prometheus/alerts/slo-burn-rate-alerts.yaml](../alerts/slo-burn-rate-alerts.yaml)
- [observability/prometheus/dashboards/slo-status-configmap.yaml](../dashboards/slo-status-configmap.yaml)
- [docs/runbooks/slo-breach-response.md](../../../docs/runbooks/slo-breach-response.md)

