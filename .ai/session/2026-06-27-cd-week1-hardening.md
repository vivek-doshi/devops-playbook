# Session Summary - 2026-06-27 - CD Week 1 Hardening

## Scope
Implemented Week 1 items from the CD audit plan:
- Step 1 (GitOps safety)
- Step 2 (remove mutable latest tags in Kubernetes deploy-critical templates)
- Step 3 (FinOps label requirements)
- Step 8 (target workflow hardening)
- Step 9 (Azure OIDC migration)

## Files Updated
- cd/gitops/argocd/application.yaml
- cd/gitops/argocd/applicationset.yaml
- cd/gitops/argocd/app-of-apps.yaml
- cd/kubernetes/_base/deployment.yaml
- cd/kubernetes/_overlays/dev/kustomization.yaml
- cd/kubernetes/_overlays/staging/kustomization.yaml
- cd/kubernetes/_patterns/db-migration-job.yaml
- cd/kubernetes/_patterns/db-migration-init-container.yaml
- cd/kubernetes/_patterns/init-containers.yaml
- cd/helm/webapp/values.yaml
- cd/targets/aws-eks/github-actions-deploy.yml
- cd/targets/azure-aks/github-actions-deploy.yml
- cd/targets/azure-app-service/github-actions-deploy.yml
- cd/targets/gcp-gke/github-actions-deploy.yml

## Key Changes
- ArgoCD templates:
  - Replaced `project: default` with `project: platform-apps` in `application.yaml`, `applicationset.yaml`, `app-of-apps.yaml`.
  - Pinned `targetRevision` to `v1.0.0` in `application.yaml` and `app-of-apps.yaml`.
  - Added `ApplyOutOfSyncOnly=true` in `application.yaml` sync options.
- Kubernetes templates:
  - Replaced mutable `latest`/`*-latest` image tags in selected deployment-critical manifests with pinned placeholders.
  - Added required FinOps pod-template labels in `_base/deployment.yaml`.
- Helm values:
  - Added `finops.labels.costCenter` and `finops.labels.environment` contract in `webapp/values.yaml`.
- Deployment workflows (AWS EKS, Azure AKS, Azure App Service, GCP GKE):
  - Added `concurrency` protection.
  - Added rollout/smoke-test checks.
  - Added rollback jobs on failure.
  - Added Slack failure notification jobs.
  - Set production environment on deploy jobs.
- Azure workflows:
  - Migrated from `AZURE_CREDENTIALS` JSON login to OIDC (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`).

## Validation
- `get_errors` returned no errors for all updated key files.
- Verified workflow hardening markers (`concurrency`, `id-token: write`, smoke test, rollback, Slack webhook usage).
- Verified no `latest` tags remain in `cd/kubernetes/**`.

## Notes
- `cd/gitops/argocd/applicationset.yaml` still contains `targetRevision: HEAD` in the generic template path; this was left as-is because Week 1 pinning requirement targeted `application.yaml` and `app-of-apps.yaml`.
- Slack notifications were implemented inline per workflow to avoid GitHub reusable-workflow path constraints; `notifications/slack-notify.yml` remains the reference template pattern.
