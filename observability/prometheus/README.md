# Prometheus Stack

This directory contains a production-oriented baseline for `kube-prometheus-stack` 55.x, plus custom alert rules tuned to the deployment patterns used elsewhere in this repo.

## Installation

Add the chart repository if you have not already done so:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Install the stack with the values in this directory:

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -f values.yaml
```

For staging and production, keep environment-specific hostnames, storage classes, and secret names in separate values files such as `values.staging.yaml` and `values.prod.yaml`.

## Access Grafana Locally

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Then open `http://localhost:3000` and log in with the admin credentials from the secret referenced in `values.yaml`.

## Add A New Alert

Edit these three files when you add or change alerts:

1. `alerts/pod-alerts.yaml` or `alerts/deployment-alerts.yaml`: add the PrometheusRule entry in the file that matches the scope of the alert.
2. `values.yaml`: update Alertmanager routing or receiver configuration if the new alert needs different severity handling or notification targets.
3. `README.md`: document the new alert so operators know where it lives and how it is intended to route.

Every alert should include a summary, a description with label templating, and a real runbook URL before it is promoted to production.

## Silence An Alert In Alertmanager

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
```

Open `http://localhost:9093`, create a silence, and match on labels such as `alertname`, `namespace`, and `severity`. Prefer narrow silences with explicit expiry times so production alerts do not disappear longer than intended.

## Add A ServiceMonitor For A New Application

This stack is configured to discover ServiceMonitors and PodMonitors across namespaces, and it also includes a scrape job for any Service labeled `monitoring: "true"`.

If you want a full ServiceMonitor resource for a new app, create a manifest like this:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: monitoring
spec:
  namespaceSelector:
    matchNames:
      - my-app-namespace
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: http
      interval: 30s
      path: /metrics
```

If your app exposes metrics through a Service instead of a ServiceMonitor, label the Service with `monitoring: "true"` and add the standard Prometheus annotations for the metrics port and path when they differ from `/metrics`.

## Advanced Configuration

For chart internals and full values documentation, see the official kube-prometheus-stack chart docs:

https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack