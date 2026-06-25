# Observability Stack

This folder contains metrics, logs, traces, and SLO assets for runtime operations.

## Purpose

Use `observability/` to establish production telemetry and actionable alerting.

## What's Inside

- `prometheus/`: metrics collection, recording rules, and alerts.
- `loki/`: centralized log aggregation patterns.
- `tempo/`: trace storage and query patterns.
- `otel/` and `opentelemetry/`: collector and instrumentation guidance.

## Use This Component Alone

- Deploy one observability pillar (metrics, logs, or traces).
- Define SLO burn-rate alerts for one critical service.

## Use This Component With Others

- With `notifications/`: route alerts to incident channels.
- With `docs/runbooks/`: connect alert responses to operational playbooks.
- With `secops/`: correlate security events with telemetry.
- With `finops/`: monitor cost and utilization anomalies.

## Recommended Install Order

1. Prometheus
2. Loki
3. Tempo
4. OpenTelemetry collector and instrumentation
