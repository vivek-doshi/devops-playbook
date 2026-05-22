# Helm Configurations

This directory contains Helm chart values files and configurations for deploying FinOps components to Kubernetes clusters.

## Contents

This directory will include:

- **kubecost-values.yaml** - Helm values for Kubecost deployment with Prometheus integration and cloud provider settings
- **opencost-values.yaml** - Helm values for OpenCost deployment with multi-cloud support
- **vpa-values.yaml** - Helm values for Vertical Pod Autoscaler deployment in recommendation-only mode

## Usage

Helm values files in this directory are used by installation scripts in the `../scripts/` directory to deploy cost monitoring and optimization tools to the cluster.

## Tool Selection

- **Kubecost**: Built on OpenCost, adds enterprise features (multi-cluster, advanced reporting), suitable for organizations needing commercial support
- **OpenCost**: CNCF project, vendor-neutral, free, suitable for organizations prioritizing open standards

Refer to `../docs/kubecost-vs-opencost.md` for a detailed comparison to guide tool selection.
