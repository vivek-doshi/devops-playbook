# Observability Stack

This directory groups the three observability pillars used by most production Kubernetes platforms:

- Metrics: Prometheus and Alertmanager collect cluster and application health data, evaluate alerts, and drive Slack/PagerDuty notifications.
- Logs: Loki stores application and cluster logs for correlation during incidents and post-incident review.
- Traces: OpenTelemetry captures distributed request flow so teams can see where latency and failures are introduced.

Recommended installation order:

1. Prometheus first, because alerting and baseline cluster visibility should exist before layering on more telemetry.
2. Loki second, so incident responders can pivot from alerts into logs without changing tools.
3. OpenTelemetry last, after metrics and logs are stable, because traces are most valuable once the core collection path is already trusted.

Sub-directories:

- [Prometheus](prometheus/README.md) for metrics, alerts, and Grafana dashboards.
- [Loki](loki/README.md) for log aggregation guidance.
- [OpenTelemetry](otel/README.md) for traces and collector patterns.

In this repo's environment model, keep environment-specific differences in separate values or overlays instead of hardcoding them into shared manifests. Follow the same dev, staging, and production separation described in `docs/guides/environment-strategy.md`.