# FinOps — Prometheus API Query Examples

> This guide provides common queries for retrieving cost metrics via the Prometheus API.

---

## 1. Metric Names and Labels

The FinOps metrics exporter (`export-metrics.py`) and recording rules expose the following core metrics:

| Metric | Labels | Description |
|--------|--------|-------------|
| `finops_namespace_cost_hourly` | `namespace`, `cluster_name`, `cost_center` | Current hourly cost |
| `finops_budget_threshold` | `cost_center` | Configured monthly budget |
| `finops_budget_current_spend` | `cost_center` | Aggregated spend for current month |
| `finops_budget_hourly_threshold` | `cost_center` | Hourly burn rate allowed by budget |

---

## 2. Example Queries

### A. Total hourly cost per cost center
```promql
sum by (cost_center) (finops_namespace_cost_hourly)
```

### B. Budget utilization percentage
```promql
(finops_budget_current_spend / finops_budget_threshold) * 100
```

### C. Top 5 most expensive namespaces
```promql
topk(5, sum by (namespace) (finops_namespace_cost_hourly))
```

### D. Cost anomaly detection (current vs 7d average)
```promql
(
  sum by (namespace) (finops_namespace_cost_hourly) 
  - sum by (namespace) (avg_over_time(finops_namespace_cost_hourly[7d]))
) / sum by (namespace) (avg_over_time(finops_namespace_cost_hourly[7d])) * 100
```

---

## 3. Retrieving Data via Curl

### Query instant value
```bash
curl -G "http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query" \
  --data-urlencode "query=sum by (cost_center) (finops_namespace_cost_hourly)" | jq
```

### Query range (last 24 hours)
```bash
START=$(date -u -d "24 hours ago" +%Y-%m-%dT%H:%M:%SZ)
END=$(date -u +%Y-%m-%dT%H:%M:%SZ)

curl -G "http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query_range" \
  --data-urlencode "query=sum(finops_namespace_cost_hourly)" \
  --data-urlencode "start=$START" \
  --data-urlencode "end=$END" \
  --data-urlencode "step=1h" | jq
```

---

## 4. Python Integration

```python
import requests
import time

PROMETHEUS_URL = "http://prometheus.monitoring.svc.cluster.local:9090"

def get_cost_center_spend(cost_center):
    query = f'finops_budget_current_spend{{cost_center="{cost_center}"}}'
    response = requests.get(
        f"{PROMETHEUS_URL}/api/v1/query",
        params={"query": query}
    )
    result = response.json().get("data", {}).get("result", [])
    if result:
        return float(result[0]["value"][1])
    return 0.0

print(f"Engineering spend: ${get_cost_center_spend('engineering'):.2f}")
```

---

## 5. Metadata and Filtering

### Filter by cluster
```promql
sum(finops_namespace_cost_hourly{cluster_name="production"})
```

### Aggregate by cloud provider
```promql
sum by (cloud_provider) (finops_namespace_cost_hourly)
```
