# External Secrets

This directory provides patterns for pulling secrets from cloud-native secret stores into Kubernetes, without storing credentials in the cluster.

## Why External Secrets Operator?

Kubernetes Secrets are base64-encoded, not encrypted at rest by default. Storing sensitive values (DB passwords, API keys, TLS private keys) directly in a Secret or in a Git-tracked YAML is a security risk.

**External Secrets Operator (ESO)** solves this by:
1. Keeping the authoritative secret in a managed secret store (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
2. Syncing a copy into a Kubernetes Secret on a schedule
3. Updating the Kubernetes Secret automatically when the upstream value changes (e.g., after rotation)
4. Authenticating to the cloud using short-lived OIDC tokens (IRSA / Workload Identity) — no static credentials in the cluster

## Directory Structure

```
secrets/
├── external-secrets/
│   ├── aws-secret-store.yaml        # ClusterSecretStore for AWS Secrets Manager (IRSA)
│   ├── azure-secret-store.yaml      # ClusterSecretStore for Azure Key Vault (Workload Identity)
│   ├── gcp-secret-store.yaml        # ClusterSecretStore for GCP Secret Manager (Workload Identity)
│   └── example-external-secret.yaml # ExternalSecret — maps upstream keys to a Kubernetes Secret
└── rotation/
    ├── aws-rotation.yml             # GitHub Actions: rotate AWS Secrets Manager secret + restart pods
    ├── azure-rotation.yml           # GitHub Actions: rotate Azure Key Vault secret + restart pods
    └── gcp-rotation.yml             # GitHub Actions: rotate GCP Secret Manager secret + restart pods
```

## Quick Start

### 1. Install External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace \
  --set installCRDs=true
```

### 2. Apply the SecretStore for your cloud

```bash
# AWS (IRSA):
kubectl apply -f secrets/external-secrets/aws-secret-store.yaml

# Azure (Workload Identity):
kubectl apply -f secrets/external-secrets/azure-secret-store.yaml

# GCP (Workload Identity):
kubectl apply -f secrets/external-secrets/gcp-secret-store.yaml
```

### 3. Create an ExternalSecret for your application

Copy and edit `example-external-secret.yaml`:

```bash
cp secrets/external-secrets/example-external-secret.yaml \
   secrets/external-secrets/my-app-secrets.yaml
# Edit: name, namespace, secretStoreRef, data keys
kubectl apply -f secrets/external-secrets/my-app-secrets.yaml
```

### 4. Verify sync

```bash
# Check ExternalSecret status
kubectl get externalsecret app-db-credentials -n default

# Should show READY = True and SYNC STATUS = Synced
kubectl describe externalsecret app-db-credentials -n default

# Verify the Kubernetes Secret was created
kubectl get secret app-db-credentials -n default
```

### 5. Force an immediate refresh (e.g., after rotation)

```bash
kubectl annotate externalsecret app-db-credentials \
  force-sync=$(date +%s) --overwrite -n default
```

## Authentication Methods

| Cloud | Method | Credential stored in cluster? |
|-------|--------|-------------------------------|
| AWS | IRSA (projected ServiceAccount token) | No |
| Azure | Workload Identity (federated OIDC token) | No |
| GCP | Workload Identity (projected ServiceAccount token) | No |

All three methods use short-lived, automatically-rotated OIDC tokens issued by the Kubernetes API server. The cloud provider exchanges these tokens for cloud-native access tokens. No static keys or certificates are stored in Kubernetes.

## Rollout After Rotation

ESO updates the Kubernetes Secret automatically. However, most applications read environment variables or secret files only at startup — a pod restart is needed to pick up the new value.

The rotation workflows in `secrets/rotation/` handle this automatically: they rotate the secret in the cloud store, trigger an ESO refresh, then restart the affected Deployment.

## Related Files

- [`secrets/rotation/`](../rotation/) — automated rotation GitHub Actions workflows
- [`cd/kubernetes/_base/deployment.yaml`](../../cd/kubernetes/_base/deployment.yaml) — deployment consuming secrets via `envFrom`
- [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml) — secrets consumed by migration jobs
