# Golden Path - SLO-Driven Development

> An opinionated workflow that defines reliability targets, alerts on risk, and closes the loop with quarterly review.

---

## When to use this path

- Your service is deployed and exposes Prometheus metrics.
- You need a production-grade reliability target with burn-rate alerting.
- You want a repeatable reliability planning cadence.

Not the right path?

- Need Prometheus stack setup first: use Step 8 in [docs/golden-paths/platform-onboarding.md](platform-onboarding.md).

---

## Prerequisites

| Requirement | Why | How to verify |
|---|---|---|
| Prometheus stack running | Recording rules and alerts are Prometheus resources | `kubectl get pods -n monitoring -l app=kube-prometheus-stack` |
| Service exposes /metrics | SLOs require Prometheus metrics | `curl http://<service>:<port>/metrics | grep http_requests_total` |
| Alertmanager configured | Alerts need routing destination | `kubectl get secret alertmanager-config -n monitoring` |
| PagerDuty or Slack configured | Alert routing path required | `notifications/pagerduty-notify.yml` or `notifications/slack-notify.yml` |

---

## Flow

```
define SLO (schema) -> write recording rules -> define burn-rate alerts
-> deploy dashboard -> connect alert routing -> test with synthetic load
-> run first quarterly review -> refine targets
```

---

## Step 1 - Define your SLO

Copy and fill schema:

```bash
cp observability/prometheus/slos/slo-schema.yaml \
   observability/prometheus/slos/<your-service>-slo.yaml
```

Reference example files:

- [observability/prometheus/slos/my-service-availability-slo.yaml](../../observability/prometheus/slos/my-service-availability-slo.yaml)
- [observability/prometheus/slos/my-service-latency-slo.yaml](../../observability/prometheus/slos/my-service-latency-slo.yaml)

---

## Step 2 - Write recording rules

```bash
cp observability/prometheus/recording-rules/slo-burn-rates.yaml \
   observability/prometheus/recording-rules/<your-service>-slo-burn-rates.yaml
kubectl apply -f observability/prometheus/recording-rules/<your-service>-slo-burn-rates.yaml
```

Replace `api-gateway` with your service identifier.

---

## Step 3 - Write burn-rate alerts

```bash
cp observability/prometheus/alerts/slo-burn-rate-alerts.yaml \
   observability/prometheus/alerts/<your-service>-slo-burn-rate-alerts.yaml
kubectl apply -f observability/prometheus/alerts/<your-service>-slo-burn-rate-alerts.yaml
```

---

## Step 4 - Deploy SLO dashboard

```bash
cp observability/prometheus/dashboards/slo-status-configmap.yaml \
   observability/prometheus/dashboards/<your-service>-slo-status-configmap.yaml
kubectl apply -f observability/prometheus/dashboards/<your-service>-slo-status-configmap.yaml
```

---

## Step 5 - Wire alert routing

Update PagerDuty routing in [notifications/pagerduty-notify.yml](../../notifications/pagerduty-notify.yml) with your service/team keys.

---

## Step 6 - Test alerts safely

Temporarily tighten target to force a controlled alert, verify routing, then restore target.

---

## Step 7 - Establish error budget policy

Create:

`docs/slo-policies/<service>-error-budget-policy.yaml`

Use the template in [docs/runbooks/slo-quarterly-review.md](../runbooks/slo-quarterly-review.md).

---

## Step 8 - Schedule quarterly review

Create recurring meeting and attach [docs/runbooks/slo-quarterly-review.md](../runbooks/slo-quarterly-review.md).

---

## SLO Target Selection Guide

Most teams choose 99.9% by default. This is often incorrect.

Use these questions first:

1. What is user impact of 1 minute downtime?
2. What is current measured availability baseline?
3. Can team sustain on-call burden at tighter target?

Guardrail: never set target above measured baseline. 99.99% allows only 4.3 minutes/month and can be exhausted by one poorly tuned rollout.

---

## Compliance Mapping

SLO recording rules and alert history provide evidence for:

- SOC 2 CC7.2 (monitoring system operations)
- SOC 2 CC7.4 (detection and response)

Reference: [secops/compliance/control-library/soc2-controls.yaml](../../secops/compliance/control-library/soc2-controls.yaml)

---

## Guardrails

| Rule | Enforced by |
|---|---|
| SLO target must not exceed measured baseline | Code review, quarterly review process |
| All four burn-rate tiers required | `slo-burn-rate-alerts.yaml` template |
| Recording rules required (no direct metric in alerts) | Alert-rule review plus template comments |
| Error budget policy documented before production | Quarterly review checklist |
| PagerDuty routing verified before first deploy | Step 6 test procedure |
