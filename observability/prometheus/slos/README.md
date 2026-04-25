# SLO Alerting Rules

Service Level Objectives (SLOs) formalize reliability targets — what "good enough" means for a service — and the recording rules and alerts in this directory automatically calculate and enforce them.

## What Is an SLO?

An **SLO** is a target for a service-level indicator (SLI). Common SLIs:

| SLI | Measures | Example SLO |
|-----|----------|-------------|
| Availability | Fraction of requests that succeed | 99.9% of requests return non-5xx |
| Latency | Fraction of requests below a threshold | 99% of requests complete in < 500ms |
| Error rate | Fraction of requests that fail | < 0.1% of requests return 5xx |

An **error budget** is the inverse of the SLO: how much unreliability is allowed.

| SLO Target | Error Budget (per 30 days) | Error Budget (per year) |
|------------|---------------------------|------------------------|
| 99% | 7h 18m | 3d 15h 39m |
| 99.5% | 3h 39m | 1d 19h 49m |
| 99.9% | 43m 49s | 8h 45m |
| 99.95% | 21m 54s | 4h 22m |
| 99.99% | 4m 22s | 52m 35s |

## Multi-Window Burn Rate

Standard threshold alerts fire only when the current error rate exceeds the SLO. This has two problems:
- A sustained low-level error rate can exhaust the error budget silently before any alert fires
- A brief spike fires the alert even though the budget impact is negligible

**Multi-window burn rate** solves this by measuring how fast the error budget is being consumed (the burn rate) over multiple time windows simultaneously.

A **burn rate** of `N` means the error budget will be exhausted in `(1/N) × budget_period`. For a 30-day window:

| Burn rate | Budget exhausted in |
|-----------|---------------------|
| 1× | 30 days (normal) |
| 2× | 15 days |
| 6× | 5 days |
| 14× | ~50 hours |
| 36× | ~20 hours |

The **two-window requirement** (e.g., `5-minute AND 1-hour` for fast burns) prevents false positives: a short spike can have a high 5-minute burn rate without raising the 1-hour rate.

```
Alert tier         Short window    Long window    Burn rate   Severity
──────────────     ────────────    ───────────    ─────────   ────────
SLOFastBurnCrit    5m              1h             14×         critical (page)
SLOFastBurnWarn    30m             6h             6×          warning  (ticket)
SLOSlowBurnWarn    6h              3d             3×          warning  (ticket)
```

For the full methodology see [Google SRE Workbook Chapter 5 — Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/).

## Files in This Directory

| File | SLI | SLO |
|------|-----|-----|
| `availability-slo.yaml` | Fraction of non-5xx requests | 99.9% |
| `latency-slo.yaml` | Fraction of requests < 500ms | 99% |

## How to Deploy

These files are `PrometheusRule` custom resources. Apply them with:

```bash
kubectl apply -f observability/prometheus/slos/availability-slo.yaml
kubectl apply -f observability/prometheus/slos/latency-slo.yaml
```

Or add them to your kustomization:

```yaml
# In kustomization.yaml
resources:
  - availability-slo.yaml
  - latency-slo.yaml
```

The namespace must have the `prometheus: kube-prometheus` label so the Prometheus Operator discovers the rules:

```bash
kubectl label namespace monitoring prometheus=kube-prometheus
```

## Customising the SLO Target

The `SLO_TARGET` is embedded in `expr` fields as a numeric literal. To change the target (e.g., from 99.9% to 99.5%):

1. Change all `0.999` occurrences in `availability-slo.yaml` to `0.995`
2. Update the burn-rate thresholds in the alert expressions proportionally
3. Update the `SLO_TARGET` annotation on each PrometheusRule for documentation

The easiest approach is to use Sloth (`sloth.dev`) or Pyrra (`pyrra.dev`), which generate these YAML files from a simpler SLO spec. The files in this directory were written manually following the same algebra so the output is identical.

## Grafana Dashboard

The recording rules in these files produce metrics in the form:
- `slo:sli_error:ratio_rate5m` — 5-minute error ratio
- `slo:sli_error:ratio_rate1h` — 1-hour error ratio
- etc.

Import the **Kubernetes / SLO (Multi-Window)** dashboard from Grafana's dashboard gallery (ID `14348`) to visualise these metrics out of the box.

## Related Files

- [`observability/prometheus/alerts/slo-rules.yaml`](../alerts/slo-rules.yaml) — combined SLO rules (alternative single-file layout)
- [`docs/runbooks/`](../../../docs/runbooks/) — runbooks for each alert
- [`observability/README.md`](../../README.md) — observability stack overview
