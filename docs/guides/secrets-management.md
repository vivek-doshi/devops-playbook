# Secrets Management Guide

A practical guide to managing secrets across CI/CD pipelines and Kubernetes.

---

## The Problem

Secrets (passwords, API keys, certificates) must be:
- **Never stored in Git** — even in private repos
- **Scoped** — each service gets only the secrets it needs
- **Rotatable** — changing secrets should not require code changes
- **Auditable** — who accessed what, when?

---

## Options by Context

### CI/CD Pipelines

| Platform | Built-in Secrets | External Integration |
|----------|-----------------|---------------------|
| GitHub Actions | `secrets.*` in repository/org settings | OIDC → AWS/Azure/GCP |
| GitLab CI | CI/CD Variables (masked) | HashiCorp Vault plugin |
| Azure Pipelines | Variable Groups + Key Vault link | Managed Identity |
| Jenkins | Credentials store | HashiCorp Vault plugin |

**Best practice:** Use OIDC / Workload Identity Federation instead of long-lived credentials.

### Kubernetes

| Tool | How it works |
|------|-------------|
| **Kubernetes Secrets** | Base64-encoded, stored in etcd — enable envelope encryption |
| **Sealed Secrets** | Encrypted at rest in Git, decrypted only in-cluster |
| **External Secrets Operator** | Syncs from Vault, AWS Secrets Manager, Azure Key Vault |
| **Vault Agent Injector** | Vault injects secrets as files/env at pod startup |

---

## Recommended Setup

### Small team / simple needs
1. GitHub Actions encrypted secrets
2. Kubernetes Secrets with etcd encryption enabled
3. Rotate secrets manually on schedule

### Medium team
1. Azure Key Vault / AWS Secrets Manager as source of truth
2. External Secrets Operator to sync to Kubernetes
3. OIDC for CI/CD → cloud authentication

### Large enterprise
1. HashiCorp Vault with namespaces
2. Vault Agent Injector for Kubernetes
3. Dynamic secrets (Vault generates short-lived credentials on demand)
4. Full audit logging

---

## Anti-patterns to Avoid

- ❌ `.env` files committed to Git
- ❌ Secrets in `docker-compose.yml`
- ❌ Long-lived service account keys / personal access tokens
- ❌ Same secret in dev, staging, and prod
- ❌ Secrets in container image layers
