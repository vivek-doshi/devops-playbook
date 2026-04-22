<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Secrets Management Guide

A practical guide to managing secrets across CI/CD pipelines and Kubernetes.

<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## The Problem

<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Secrets (passwords, API keys, certificates) must be:
- **Never stored in Git** — even in private repos
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Scoped** — each service gets only the secrets it needs
- **Rotatable** — changing secrets should not require code changes
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Auditable** — who accessed what, when?

---

<!-- Note 6: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Options by Context

### CI/CD Pipelines

<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Platform | Built-in Secrets | External Integration |
|----------|-----------------|---------------------|
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| GitHub Actions | `secrets.*` in repository/org settings | OIDC → AWS/Azure/GCP |
| GitLab CI | CI/CD Variables (masked) | HashiCorp Vault plugin |
<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Azure Pipelines | Variable Groups + Key Vault link | Managed Identity |
| Jenkins | Credentials store | HashiCorp Vault plugin |

<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Best practice:** Use OIDC / Workload Identity Federation instead of long-lived credentials.

### Kubernetes

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Tool | How it works |
|------|-------------|
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Kubernetes Secrets** | Base64-encoded, stored in etcd — enable envelope encryption |
| **Sealed Secrets** | Encrypted at rest in Git, decrypted only in-cluster |
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **External Secrets Operator** | Syncs from Vault, AWS Secrets Manager, Azure Key Vault |
| **Vault Agent Injector** | Vault injects secrets as files/env at pod startup |

<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Recommended Setup

<!-- Note 15: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Small team / simple needs
1. GitHub Actions encrypted secrets
<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. Kubernetes Secrets with etcd encryption enabled
3. Rotate secrets manually on schedule

<!-- Note 17: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
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
