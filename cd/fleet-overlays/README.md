# Fleet Overlays

This directory defines workload overlays deployed by `fleet-workload-applicationset.yaml`.

## Directory Convention

Use this path format for every fleet workload overlay:

`cd/fleet-overlays/<environment>/<app-name>/`

Examples:
- `cd/fleet-overlays/production/payments-api/`
- `cd/fleet-overlays/staging/webapp-example/`
- `cd/fleet-overlays/dev/feature-service/`

## Relationship To Fleet Workload ApplicationSet

`cd/gitops/argocd/fleet/fleet-workload-applicationset.yaml` scans this directory with a Git directory generator and creates one ArgoCD Application per `(cluster, app overlay)` pair.

For `5` clusters and `3` app directories, ArgoCD creates `15` Applications.

## Add A New Application To The Fleet

1. Create `cd/fleet-overlays/<environment>/<app-name>/kustomization.yaml`.
2. Commit and merge to your GitOps branch.
3. ApplicationSet detects the new directory.
4. ArgoCD deploys that overlay to clusters matching the configured target environment and registry filters.
