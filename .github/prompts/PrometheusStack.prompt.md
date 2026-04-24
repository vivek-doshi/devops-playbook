---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Prometheus, Alertmanager, and Grafana Helm values and alert rules for observability of workloads deployed by this repo.'
---

# Prometheus Observability Stack Generator

You are a senior SRE. Generate Helm values and alerting rules for the `kube-prometheus-stack` chart that are tuned for the workloads and deployment patterns in this repo.

## Context

Read these files first:
- `cd/kubernetes/_base/deployment.yaml` — understand resource limits, health check paths
- `cd/kubernetes/_base/hpa.yaml` — understand scaling thresholds
- `cd/helm/webapp/values.yaml` — understand the webapp structure
- `notifications/slack-notify.yml` — understand how alerts should route to Slack
- `notifications/pagerduty-notify.yml` — understand PagerDuty integration pattern
- `docs/guides/environment-strategy.md` — understand environment separation

## Your deliverables

### 1. `observability/prometheus/values.yaml`

Helm values for `kube-prometheus-stack` (chart version 55.x) that configure:

**Prometheus:**
- Retention: 30 days, 50Gi storage
- Scrape interval: 30s (add comment: matches the health check intervals in base deployment)
- Additional scrape configs for any service with the label `monitoring: "true"`
- Resource requests/limits appropriate for a production cluster
- `serviceMonitorSelectorNilUsesHelmValues: false` — add a comment explaining this allows ServiceMonitors outside the chart's namespace

**Alertmanager:**
- Route tree:
  - `severity: critical` → PagerDuty (receiver named `pagerduty-critical`)
  - `severity: warning` → Slack (receiver named `slack-warnings`)
  - Default route → Slack
- Slack receiver template using the webhook pattern from `notifications/slack-notify.yml`
- PagerDuty receiver using the integration key pattern from `notifications/pagerduty-notify.yml`
- Group-by: `[alertname, namespace, severity]`
- Group wait: 30s, group interval: 5m, repeat interval: 4h
- All receiver credentials referenced via `${SLACK_WEBHOOK_URL}` and `${PAGERDUTY_KEY}` environment variable substitution — add a comment pointing to `docs/guides/secrets-management.md`

**Grafana:**
- Enable persistence (10Gi)
- Default dashboards: enable all built-in Kubernetes dashboards
- Admin password via secret reference (not hardcoded)
- Ingress enabled with a `# <-- CHANGE THIS` on the hostname
- Sidecar for dashboard provisioning from ConfigMaps (label: `grafana_dashboard: "1"`)

### 2. `observability/prometheus/alerts/pod-alerts.yaml`

A PrometheusRule resource with the following alert groups:

**Group: `pod.rules`**
- `PodCrashLoopBackOff` — fires when a pod has restarted more than 5 times in 15 minutes, severity: critical
- `PodOOMKilled` — fires when a container was OOM killed, severity: warning
- `PodNotReady` — fires when a pod has been not-ready for more than 5 minutes, severity: warning
- `ContainerHighCPU` — fires when CPU usage exceeds 80% of limit for 10 minutes, severity: warning
- `ContainerHighMemory` — fires when memory usage exceeds 85% of limit for 5 minutes, severity: warning

Each alert must have:
- `summary` annotation: one sentence
- `description` annotation: includes the pod name and namespace using label templating
- `runbook_url` annotation: placeholder `https://runbooks.example.com/<alert-name>` with a `# <-- CHANGE THIS` comment
- Correct `severity` label matching the Alertmanager routing above

### 3. `observability/prometheus/alerts/deployment-alerts.yaml`

A PrometheusRule resource for deployment health:
- `DeploymentReplicasMismatch` — available replicas < desired for more than 10 minutes, severity: warning
- `DeploymentRolloutStuck` — deployment has an unavailable replica for more than 15 minutes, severity: critical
- `HpaMaxReplicasReached` — HPA is at max replicas, suggesting the app may need manual scaling review, severity: warning
- `HpaMetricsMissing` — HPA cannot retrieve metrics (often indicates metrics-server issue), severity: critical

### 4. `observability/prometheus/README.md`

A guide covering:
- Installation: `helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -f values.yaml`
- How to access Grafana locally via port-forward
- How to add a new alert: the three files to edit and what each does
- How to silence an alert in Alertmanager
- How to add a ServiceMonitor for a new application
- A link to the official chart docs for advanced configuration

### 5. `observability/README.md`

A top-level overview of the entire observability stack (Prometheus, Loki, OTel) explaining:
- The three pillars: metrics, logs, traces
- Which tool handles which pillar
- The recommended order to install the stack
- Links to each sub-directory README

## Style rules

- All YAML must be valid and include comments explaining non-obvious values
- Alert expressions (PromQL) must include inline comments explaining the query logic
- Values that teams must change are marked `# <-- CHANGE THIS`
- Storage sizes and retention periods must have comments explaining the sizing rationale
- The values file must include commented-out sections for common production additions (Thanos, remote write) so teams can enable them without starting from scratch