# Notifications

This folder provides notification routing templates for observability, incidents, and governance alerts.

## Purpose

Use `notifications/` to standardize alert delivery channels across teams and environments.

## What's Inside

- `slack-notify.yml`
- `teams-notify.yml`
- `pagerduty-notify.yml`
- `datadog-notify.yml`
- `grafana-notify.yml`

## Use This Component Alone

- Configure one destination for alert delivery.
- Validate alert payload formatting and severity routing.

## Use This Component With Others

- With `observability/`: Route Prometheus and Grafana alerts.
- With `secops/`: Route security incidents by severity.
- With `finops/`: Route budget and anomaly alerts to owners.

## Quick Start

1. Copy the destination template that matches your channel.
2. Replace webhook URLs and routing metadata using secret references.
3. Attach to Alertmanager or platform-specific alerting config.
4. Trigger a test alert and confirm delivery.

Never commit live webhook URLs or tokens.
