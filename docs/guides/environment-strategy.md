<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Environment Strategy Guide

---

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Standard Environment Model

```
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Developer → dev → staging → production
                     ↑
            <!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
            (integration / QA)
```

<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Environment | Purpose | Deploy trigger | Data |
|-------------|---------|----------------|------|
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| dev | Rapid feedback, feature work | Every push / PR | Synthetic / mocked |
| staging | Pre-prod verification, QA sign-off | Merge to main | Anonymised production snapshot |
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| production | Live system | Manual / scheduled | Real production data |

---

<!-- Note 8: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Environment-Specific Configuration

Never bake environment config into images. Externalize via:
<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Kubernetes ConfigMaps + Secrets
- Helm values files (`values.dev.yaml`, `values.prod.yaml`)
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Kustomize overlays (`_overlays/dev`, `_overlays/prod`)
- Cloud-native: Azure App Config, AWS Parameter Store

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Promotion Flow (GitOps)

<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
1. CI builds image, tags with SHA
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
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
