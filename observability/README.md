# Observability Stack

This directory groups the three observability pillars used by most production Kubernetes platforms:

- Metrics: Prometheus and Alertmanager collect cluster and application health data, evaluate alerts, and drive Slack/PagerDuty notifications.
- Logs: Loki stores application and cluster logs for correlation during incidents and post-incident review.
- Traces: OpenTelemetry captures distributed request flow so teams can see where latency and failures are introduced.

Recommended installation order:

1. Prometheus first, because alerting and baseline cluster visibility should exist before layering on more telemetry.
2. Loki second, so incident responders can pivot from alerts into logs without changing tools.
3. Tempo third, to provide the trace storage backend that the OTel collector targets (the collector config exports to `otlp/tempo` by default).
4. OpenTelemetry last, after metrics, logs, and trace storage are all stable.

Sub-directories:

- [Prometheus](prometheus/README.md) for metrics, alerts, and Grafana dashboards.
- [Loki](loki/README.md) for log aggregation guidance.
- [Tempo](tempo/README.md) for distributed trace storage, Helm values, and Grafana datasource configuration.
- [OpenTelemetry](otel/README.md) for traces and collector patterns.

In this repo's environment model, keep environment-specific differences in separate values or overlays instead of hardcoding them into shared manifests. Follow the same dev, staging, and production separation described in `docs/guides/environment-strategy.md`.