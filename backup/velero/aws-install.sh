#!/usr/bin/env bash
# ============================================================
# TEMPLATE: Install Velero on EKS with S3 backend (IRSA)
# WHEN TO USE: First-time Velero install on an EKS cluster.
#   Uses IRSA for authentication — no static AWS credentials
#   are stored inside the cluster.
#
# PREREQUISITES:
#   - eksctl, velero CLI, kubectl configured against your cluster
#   - An S3 bucket for backup storage already created
#   - An IAM role with the Velero permissions policy attached
#     (see: https://velero.io/docs/main/contributions/aws-config/)
#
# WHAT TO CHANGE: Variables in the CONFIG section below
# RELATED FILES: backup/velero/schedule.yaml
# ============================================================

set -euo pipefail

# ── CONFIG ───────────────────────────────────────────────────
CLUSTER_NAME="my-cluster"                      # <-- CHANGE THIS
AWS_REGION="us-east-1"                         # <-- CHANGE THIS
BUCKET_NAME="my-cluster-velero-backups"        # <-- CHANGE THIS: S3 bucket name (must already exist)
VELERO_NAMESPACE="velero"
IAM_ROLE_ARN="arn:aws:iam::123456789012:role/velero-irsa-role"  # <-- CHANGE THIS
VELERO_VERSION="v1.13.0"                       # <-- CHANGE THIS: pin to a version
# ── END CONFIG ───────────────────────────────────────────────

echo "Installing Velero ${VELERO_VERSION} on cluster: ${CLUSTER_NAME}"
echo "S3 bucket: ${BUCKET_NAME} in ${AWS_REGION}"

# Install Velero with the AWS plugin using IRSA
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:${VELERO_VERSION} \
  --bucket "${BUCKET_NAME}" \
  --backup-location-config region="${AWS_REGION}" \
  --snapshot-location-config region="${AWS_REGION}" \
  --namespace "${VELERO_NAMESPACE}" \
  --no-secret \
  --sa-annotations "eks.amazonaws.com/role-arn=${IAM_ROLE_ARN}" \
  --features=EnableCSI

# Wait for Velero pod to be ready
echo "Waiting for Velero deployment to be ready..."
kubectl rollout status deployment/velero -n "${VELERO_NAMESPACE}" --timeout=120s

# Verify BackupStorageLocation is available
echo "Checking BackupStorageLocation..."
kubectl get backupstoragelocation -n "${VELERO_NAMESPACE}"

echo ""
echo "Velero installed successfully."
echo "Next: kubectl apply -f backup/velero/schedule.yaml"
