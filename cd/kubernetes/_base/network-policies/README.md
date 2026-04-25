# Network Policies

This directory provides a zero-trust NetworkPolicy baseline for Kubernetes namespaces. Start with `default-deny.yaml` and add only the allow policies your workload needs.

## Why NetworkPolicy?

By default, every pod in a Kubernetes cluster can reach every other pod across all namespaces. A compromised pod can pivot to the database, to other services, or even to the Kubernetes API. NetworkPolicy restricts pod-to-pod and pod-to-external traffic at the kernel level (via CNI), not just at the application level.

## Prerequisites

Your CNI plugin must support NetworkPolicy. Common options:

| CNI | NetworkPolicy support |
|-----|-----------------------|
| Calico | Full (ingress + egress) |
| Cilium | Full + extended (L7, FQDN) |
| Weave Net | Full |
| Flannel | **No** — install Calico as a network policy engine alongside Flannel |
| AWS VPC CNI | Partial (node-level policies since EKS 1.25 with `--enable-network-policy`) |
| Azure CNI | Full (requires Azure Network Policy Manager or Calico) |

## File Reference

| File | Purpose |
|------|---------|
| `default-deny.yaml` | Deny all ingress + egress — apply first in every namespace |
| `allow-egress-to-dns.yaml` | Permit DNS (port 53 UDP/TCP to kube-dns) — needed by all pods |
| `allow-ingress-from-ingress-controller.yaml` | Permit HTTP traffic from NGINX/Traefik ingress controller |
| `allow-egress-to-database.yaml` | Permit outbound TCP to PostgreSQL in the database namespace |
| `allow-prometheus-scrape.yaml` | Permit inbound TCP scrape from Prometheus in the monitoring namespace |

## Apply Order

```bash
# 1. Apply default-deny first (establishes zero-trust baseline)
kubectl apply -f cd/kubernetes/_base/network-policies/default-deny.yaml -n <namespace>

# 2. Apply allow policies — add only what your workload needs
kubectl apply -f cd/kubernetes/_base/network-policies/allow-egress-to-dns.yaml -n <namespace>
kubectl apply -f cd/kubernetes/_base/network-policies/allow-ingress-from-ingress-controller.yaml -n <namespace>
kubectl apply -f cd/kubernetes/_base/network-policies/allow-egress-to-database.yaml -n <namespace>
kubectl apply -f cd/kubernetes/_base/network-policies/allow-prometheus-scrape.yaml -n <namespace>

# Or via Kustomize (applies in declaration order — default-deny first):
kubectl apply -k cd/kubernetes/_base/network-policies/ -n <namespace>
```

## Verify a Policy

```bash
# List policies in a namespace
kubectl get networkpolicy -n <namespace>

# Describe a specific policy
kubectl describe networkpolicy default-deny-all -n <namespace>

# Test connectivity from a debug pod (Cilium clusters have a built-in tool)
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- \
  nc -zv my-app-service 8080
# Expected after default-deny: connection refused or timed out
# Expected after adding allow policy: connection succeeded
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Pod can't resolve hostnames | Missing `allow-egress-to-dns` | Apply `allow-egress-to-dns.yaml` |
| 502 from ingress | Missing `allow-ingress-from-ingress-controller` | Apply and check `podSelector` labels match your ingress controller |
| DB connection refused | Missing `allow-egress-to-database` | Apply and verify namespace label on DB namespace |
| Prometheus targets DOWN | Missing `allow-prometheus-scrape` | Apply and verify `monitoring` label on app pods |
| CNI doesn't enforce policies | Flannel without policy engine | Install Calico in policy-only mode |

## Common Extension Patterns

```yaml
# Allow egress to a specific external IP range (e.g., your SaaS API)
egress:
  - to:
      - ipBlock:
          cidr: 203.0.113.0/24  # <-- CHANGE THIS: your external service IP range
    ports:
      - protocol: TCP
        port: 443

# Allow inter-service communication within the same namespace
egress:
  - to:
      - podSelector:
          matchLabels:
            app: my-other-service
    ports:
      - protocol: TCP
        port: 8080
```
