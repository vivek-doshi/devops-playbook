# cert-manager

This directory provides ready-to-apply cert-manager ClusterIssuer configurations for all three common scenarios: Let's Encrypt (staging and production) and self-signed for local development.

## Why cert-manager?

Manual TLS certificate management is error-prone and breaks without warning when certificates expire. cert-manager automates:
- **Issuance**: requests a certificate from Let's Encrypt, your own CA, or generates self-signed certs
- **Renewal**: automatically renews certificates 30 days before expiry
- **Distribution**: stores the certificate in a Kubernetes Secret that Ingress resources reference

## Quick Start

### 1. Install cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --version v1.14.0
```

Verify the install:

```bash
kubectl get pods -n cert-manager
# cert-manager-*        Running
# cert-manager-cainjector-*   Running
# cert-manager-webhook-*      Running
```

### 2. Apply issuers

```bash
# Apply all issuers at once
kubectl apply -k cd/kubernetes/cert-manager/

# Or apply individually
kubectl apply -f cd/kubernetes/cert-manager/namespace.yaml
kubectl apply -f cd/kubernetes/cert-manager/cluster-issuer-selfsigned.yaml
kubectl apply -f cd/kubernetes/cert-manager/cluster-issuer-staging.yaml
kubectl apply -f cd/kubernetes/cert-manager/cluster-issuer-prod.yaml
```

### 3. Annotate an Ingress to trigger certificate issuance

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging   # Change to letsencrypt-prod when ready
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - my-app.example.com                  # <-- CHANGE THIS
      secretName: my-app-tls                  # cert-manager will create this Secret
  rules:
    - host: my-app.example.com               # <-- CHANGE THIS
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

### 4. Verify certificate issuance

```bash
# Watch the Certificate resource
kubectl get certificate my-app-tls -n default
# READY=True when issued; READY=False while pending

# Debug a failed issuance
kubectl describe certificate my-app-tls -n default
kubectl describe certificaterequest -n default
kubectl describe order -n default
kubectl describe challenge -n default
```

## Issuer Reference

| Issuer name | Use case | Trusted by browsers? |
|-------------|----------|----------------------|
| `letsencrypt-staging` | Testing — validate the ACME flow | No (Fake LE Root) |
| `letsencrypt-prod` | Production internet-facing services | Yes |
| `selfsigned` | Bootstrap CA or one-off test certs | No |
| `local-ca` | Local dev — sign all services with one CA | No (add to OS trust store) |

## Choosing HTTP-01 vs DNS-01

| Scenario | Challenge type |
|----------|---------------|
| Public-facing domain with Ingress on port 80 | HTTP-01 (default) |
| Wildcard certificates (`*.example.com`) | DNS-01 only |
| Ingress not publicly reachable (private cluster) | DNS-01 only |
| Multiple Ingress controllers | DNS-01 (avoids per-controller config) |

See `cluster-issuer-prod.yaml` for commented DNS-01 examples for AWS Route 53, Azure DNS, and Google Cloud DNS.

## Troubleshooting

```bash
# Check ClusterIssuer is Ready
kubectl get clusterissuer

# Check pending Certificates
kubectl get certificate -A

# Follow the issuance chain (Certificate → CertificateRequest → Order → Challenge)
kubectl describe certificate <name> -n <namespace>

# cert-manager controller logs
kubectl logs -n cert-manager \
  $(kubectl get pod -n cert-manager -l app=cert-manager -o name) | tail -50

# Common issues:
# - Challenge FAILED: port 80 blocked by firewall, or DNS not propagated yet
# - Too Many Requests: hit Let's Encrypt rate limits — use staging first
# - Webhook errors: namespace label cert-manager.io/disable-validation not set
```

## Related Files

- [`local-dev/kind/`](../../local-dev/kind/) — local cluster setup
- [`cd/kubernetes/_base/`](../_base/) — deployment templates that reference the TLS Secret
