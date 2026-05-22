#!/usr/bin/env bash
# finops/scripts/export-cost-report.sh
# Upload a cost report file to S3, Azure Blob Storage, or Google Cloud Storage.
#
# Usage:
#   ./export-cost-report.sh --provider aws --bucket my-finops-reports --file /tmp/report.json
#   ./export-cost-report.sh --provider azure --bucket finops-container --file /tmp/report.csv
#   ./export-cost-report.sh --provider gcp --bucket my-gcs-bucket --file /tmp/report.json
#
# The script will:
#   1. Validate the input file exists
#   2. Add metadata tags (cluster, provider, timestamp)
#   3. Upload to the specified storage backend
#   4. Verify the upload was successful

set -euo pipefail

PROVIDER=""
BUCKET=""
FILE=""
CLUSTER_NAME="${CLUSTER_NAME:-production}"
PREFIX="${PREFIX:-finops/reports}"
REGION="${AWS_REGION:-us-east-1}"

# ─── argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)     PROVIDER="$2"; shift 2 ;;
    --bucket)       BUCKET="$2"; shift 2 ;;
    --file)         FILE="$2"; shift 2 ;;
    --cluster)      CLUSTER_NAME="$2"; shift 2 ;;
    --prefix)       PREFIX="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 --provider aws|azure|gcp --bucket BUCKET --file FILE"
      echo ""
      echo "Options:"
      echo "  --provider  Cloud storage backend (aws, azure, gcp)"
      echo "  --bucket    Bucket/container/GCS bucket name"
      echo "  --file      Local file to upload"
      echo "  --cluster   Cluster name for metadata (default: production)"
      echo "  --prefix    Path prefix in bucket (default: finops/reports)"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ─── validation ───────────────────────────────────────────────────────────────
if [[ -z "$PROVIDER" || -z "$BUCKET" || -z "$FILE" ]]; then
  echo "ERROR: --provider, --bucket, and --file are required."
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: File not found: $FILE"
  echo "See finops/docs/runbooks/investigate-cost-spike.md for troubleshooting."
  exit 1
fi

FILENAME=$(basename "$FILE")
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
DEST_PATH="${PREFIX}/${TIMESTAMP}-${FILENAME}"

echo "==> FinOps Cost Report Export"
echo "    Provider  : $PROVIDER"
echo "    Bucket    : $BUCKET"
echo "    Source    : $FILE"
echo "    Dest path : $DEST_PATH"
echo "    Cluster   : $CLUSTER_NAME"
echo ""

# ─── AWS S3 ───────────────────────────────────────────────────────────────────
export_aws() {
  if ! command -v aws &>/dev/null; then
    echo "ERROR: AWS CLI not installed. Install: https://aws.amazon.com/cli/"
    exit 1
  fi

  echo "==> Uploading to s3://$BUCKET/$DEST_PATH ..."
  aws s3 cp "$FILE" "s3://${BUCKET}/${DEST_PATH}" \
    --region "$REGION" \
    --metadata "cluster=${CLUSTER_NAME},provider=aws,exported_at=${TIMESTAMP}" \
    --no-progress

  # Verify
  echo "==> Verifying upload ..."
  if aws s3 ls "s3://${BUCKET}/${DEST_PATH}" --region "$REGION" > /dev/null 2>&1; then
    echo "    SUCCESS: s3://${BUCKET}/${DEST_PATH}"
  else
    echo "ERROR: Upload verification failed."
    echo "Check IAM permissions. Runbook: finops/docs/runbooks/investigate-cost-spike.md"
    exit 1
  fi
}

# ─── Azure Blob Storage ───────────────────────────────────────────────────────
export_azure() {
  if ! command -v az &>/dev/null; then
    echo "ERROR: Azure CLI not installed. Install: https://docs.microsoft.com/cli/azure/"
    exit 1
  fi

  STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT:-}"
  if [[ -z "$STORAGE_ACCOUNT" ]]; then
    echo "ERROR: AZURE_STORAGE_ACCOUNT environment variable is required for Azure export."
    exit 1
  fi

  echo "==> Uploading to Azure Blob: $STORAGE_ACCOUNT/$BUCKET/$DEST_PATH ..."
  az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$BUCKET" \
    --name "$DEST_PATH" \
    --file "$FILE" \
    --metadata "cluster=${CLUSTER_NAME}" "provider=azure" "exported_at=${TIMESTAMP}" \
    --no-progress \
    --overwrite

  echo "    SUCCESS: https://${STORAGE_ACCOUNT}.blob.core.windows.net/${BUCKET}/${DEST_PATH}"
}

# ─── Google Cloud Storage ─────────────────────────────────────────────────────
export_gcp() {
  if ! command -v gsutil &>/dev/null && ! command -v gcloud &>/dev/null; then
    echo "ERROR: Google Cloud SDK not installed. Install: https://cloud.google.com/sdk"
    exit 1
  fi

  GCS_URI="gs://${BUCKET}/${DEST_PATH}"
  echo "==> Uploading to $GCS_URI ..."

  if command -v gsutil &>/dev/null; then
    gsutil cp "$FILE" "$GCS_URI"
    gsutil setmeta \
      -h "x-goog-meta-cluster:${CLUSTER_NAME}" \
      -h "x-goog-meta-provider:gcp" \
      -h "x-goog-meta-exported_at:${TIMESTAMP}" \
      "$GCS_URI"
  else
    gcloud storage cp "$FILE" "$GCS_URI"
  fi

  echo "    SUCCESS: $GCS_URI"
}

# ─── dispatch ─────────────────────────────────────────────────────────────────
case "$PROVIDER" in
  aws)   export_aws ;;
  azure) export_azure ;;
  gcp)   export_gcp ;;
  *)
    echo "ERROR: Unknown provider '$PROVIDER'. Must be one of: aws, azure, gcp"
    exit 1
    ;;
esac

echo ""
echo "==> Export complete."
echo "    File    : $FILE"
echo "    Uploaded: $DEST_PATH"
echo "    Cluster : $CLUSTER_NAME"
echo "    Time    : $TIMESTAMP"
