# Local Development

This folder provides local Kubernetes tooling for pre-merge validation.

## Purpose

Use `local-dev/` to test manifests and rollout behavior on a disposable local cluster.

## What's Inside

- `kind/`: scripts and config for local multi-node Kind setup.

## Use This Component Alone

- Spin up a local cluster to test Kubernetes resources.
- Validate ingress and rollout behavior before pushing changes.

## Use This Component With Others

- With `cd/kubernetes/` and `cd/helm/`: Validate deployment manifests and charts.
- With `docker/`: Load locally built images for cluster tests.
- With `scripts/`: Run rollout checks and environment validation.

## Quick Start

```bash
bash local-dev/kind/setup.sh
kubectl get pods -A
```
