# Continuous Deployment Templates

This folder contains deployment patterns for Kubernetes, cloud targets, Helm, and GitOps workflows.

## Purpose

Use `cd/` to convert build artifacts into deployed runtime workloads with environment-specific controls.

## What's Inside

- `kubernetes/`: Raw manifests and Kustomize base/overlay structure.
- `helm/`: Chart-based deployment patterns.
- `gitops/`: ArgoCD and Flux GitOps examples.
- `targets/`: Cloud-specific deployment pipelines.
- `fleet-overlays/`: Multi-cluster deployment overlays.
- `pulumi/`: Pulumi-based deployment/provisioning examples.

## Use This Component Alone

- Deploy one workload to one target.
- Evaluate one deployment strategy (Kustomize, Helm, or GitOps).

## Use This Component With Others

- With `ci/`: Trigger deployment after successful quality and security checks.
- With `secrets/`: Inject runtime secrets safely.
- With `policy/`: Enforce admission and static policy controls.
- With `observability/` and `notifications/`: Route post-deploy alerts and runbooks.
- With `terraform/`: Provision target infrastructure before deployment.

## Quick Selection Guide

- Kustomize-first: start in `kubernetes/`
- Chart-first: start in `helm/`
- Pull-based delivery: start in `gitops/`
- Cloud pipeline deploy jobs: start in `targets/`
