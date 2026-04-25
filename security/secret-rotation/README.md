# Secret Rotation Templates

Secret **detection** (gitleaks, trufflehog) tells you when a secret is exposed.
Secret **rotation** is what you actually do about it — and what you do on a schedule
before exposure happens.

## Templates in this folder

| File | Purpose |
|------|---------|
| `aws-rotation-lambda.py` | Lambda function that AWS Secrets Manager calls automatically to rotate a secret |
| `aws-rotation-lambda.tf` | Terraform wiring: IAM role, Lambda, Secrets Manager rotation schedule |
| `azure-keyvault-rotation.yaml` | Azure Function + EventGrid subscription for near-expiry key/secret rotation |
| `external-secrets-operator.yaml` | ExternalSecrets + SecretStore manifests so Kubernetes pods always read the live secret from the vault |

## Mental model

```
Vault stores secret (AWS SecretsManager / Azure Key Vault)
    │
    ├─► Rotation schedule fires (Lambda / Azure Function)
    │       1. Create new secret version in upstream system (DB, API provider)
    │       2. Store new value in vault under AWSPENDING/new version label
    │       3. Test new value
    │       4. Mark new version AWSCURRENT / set as current
    │       5. Invalidate old version after a grace period
    │
    └─► ExternalSecrets Operator syncs vault → Kubernetes Secret on schedule
            Pods mount the Kubernetes Secret — no restart needed if using volume mounts
            (use reloader sidecar/Reloader controller to trigger pod restarts on configmap/secret changes)
```

## Recommended rotation intervals

| Secret type | Suggested interval |
|-------------|-------------------|
| Database passwords | 30 days |
| API keys (3rd-party) | 90 days |
| Service account tokens | 90 days |
| TLS certificates | Automated via cert-manager (see `cd/kubernetes/_base/cert-manager-bootstrap.yaml`) |
| SSH keys | 180 days |
