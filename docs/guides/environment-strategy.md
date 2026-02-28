# Environment Strategy Guide

---

## Standard Environment Model

```
Developer → dev → staging → production
                     ↑
            (integration / QA)
```

| Environment | Purpose | Deploy trigger | Data |
|-------------|---------|----------------|------|
| dev | Rapid feedback, feature work | Every push / PR | Synthetic / mocked |
| staging | Pre-prod verification, QA sign-off | Merge to main | Anonymised production snapshot |
| production | Live system | Manual / scheduled | Real production data |

---

## Environment-Specific Configuration

Never bake environment config into images. Externalize via:
- Kubernetes ConfigMaps + Secrets
- Helm values files (`values.dev.yaml`, `values.prod.yaml`)
- Kustomize overlays (`_overlays/dev`, `_overlays/prod`)
- Cloud-native: Azure App Config, AWS Parameter Store

---

## Promotion Flow (GitOps)

```
1. CI builds image, tags with SHA
2. CI updates dev overlay: image tag → new SHA
3. ArgoCD syncs dev automatically
4. After testing, PR: update staging overlay
5. After staging approval, PR: update prod overlay
6. ArgoCD syncs prod (with manual sync gate in prod)
```

---

## Production Access Controls

- No direct `kubectl exec` to production pods  
- All changes via Git PR (GitOps)  
- Break-glass procedures documented and audited  
- RBAC: least-privilege service accounts  
- Separate Kubernetes namespaces per environment  
