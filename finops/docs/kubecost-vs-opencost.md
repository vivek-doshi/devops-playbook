# Kubecost vs OpenCost — Comparison and Selection Guide

> **Use this document to decide which cost monitoring tool to deploy.**

---

## Quick Decision

| Choose | If... |
|--------|-------|
| **OpenCost** | You want a free, CNCF-standard tool; single cluster; OSS-first culture |
| **Kubecost Free** | You need a richer UI and multi-namespace reporting; still free |
| **Kubecost Enterprise** | Multi-cluster, SSO, enterprise support, advanced reporting are required |

---

## Feature Comparison

| Feature | OpenCost | Kubecost Free | Kubecost Enterprise |
|---------|----------|---------------|---------------------|
| Kubernetes cost allocation | ✅ | ✅ | ✅ |
| Namespace/workload breakdown | ✅ | ✅ | ✅ |
| AWS pricing integration | ✅ | ✅ | ✅ |
| Azure pricing integration | ✅ | ✅ | ✅ |
| GCP pricing integration | ✅ | ✅ | ✅ |
| Prometheus metrics export | ✅ | ✅ | ✅ |
| Web UI | Minimal | Rich | Rich |
| Multi-cluster | ❌ | ❌ | ✅ |
| SAML/SSO | ❌ | ❌ | ✅ |
| Savings insights | Basic | Good | Advanced |
| Budget alerts (native) | ❌ | ✅ | ✅ |
| Anomaly detection (native) | ❌ | ✅ | ✅ |
| Team-based access control | ❌ | ❌ | ✅ |
| API for custom integrations | ✅ | ✅ | ✅ |
| CNCF project | ✅ | ❌ | ❌ |
| License | Apache 2.0 | Business Source | Commercial |
| Price | Free | Free | Contact sales |

---

## OpenCost

**Website**: https://www.opencost.io
**CNCF**: Sandbox project
**Built by**: Originally by Kubecost, donated to CNCF

### Strengths
- Fully open source (Apache 2.0)
- CNCF-standard data model (`OpenCost Specification`)
- Lightweight — lower memory footprint
- Ideal for organizations with existing Prometheus/Grafana stack
- Strong API for custom integrations

### Weaknesses
- Minimal built-in UI
- No native budget alerting (use Prometheus rules — as provided in this repo)
- No multi-cluster support
- Less mature documentation

### When to choose OpenCost
- Single cluster, OSS-first culture
- Already have Prometheus + Grafana
- Want to avoid vendor lock-in
- Budget is a concern

### Helm install
```bash
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm upgrade --install opencost opencost/opencost \
  --namespace finops \
  --values finops/helm/opencost-values.yaml
```

---

## Kubecost

**Website**: https://www.kubecost.com
**Built on**: OpenCost (Kubecost contributed the core to CNCF)

### Strengths
- Rich, polished web UI
- Native budget alerts and savings recommendations
- Built-in anomaly detection
- Better cloud provider billing integration out of the box
- Enterprise: multi-cluster, SSO, RBAC

### Weaknesses
- Free tier limited to single cluster + 15 days data retention
- Enterprise features require commercial license
- Larger memory footprint (~500Mi)
- Vendor-controlled roadmap

### When to choose Kubecost
- Need a polished UI for FinOps practitioners who are not engineers
- Multi-cluster is required (Enterprise)
- SSO/RBAC is required (Enterprise)
- Want support SLA

### Helm install
```bash
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm upgrade --install kubecost kubecost/cost-analyzer \
  --namespace finops \
  --values finops/helm/kubecost-values.yaml
```

---

## This Repository's Approach

This FinOps reference architecture is **tool-agnostic**:

- Prometheus alerting rules work with both tools (both expose the same metrics)
- Grafana dashboards use generic `kubecost_*` metric names (OpenCost exposes compatible metrics)
- Scripts query the Kubecost/OpenCost API — the same endpoint format is used by both
- Installation script supports `--tool kubecost` or `--tool opencost`

**Recommendation for new deployments**: Start with **OpenCost** for simplicity and CNCF alignment. Migrate to **Kubecost** if enterprise features become necessary.

---

## Migration Path: OpenCost → Kubecost

Since Kubecost is built on OpenCost, migration is straightforward:

1. Install Kubecost alongside OpenCost in the same namespace
2. Point Kubecost to the same Prometheus instance
3. Verify cost data matches between tools
4. Update the `KUBECOST_URL` env variable in scripts and CronJob
5. Uninstall OpenCost: `helm uninstall opencost -n finops`

The migration typically takes < 1 hour with no data loss (historical data is in Prometheus, not in either tool).
