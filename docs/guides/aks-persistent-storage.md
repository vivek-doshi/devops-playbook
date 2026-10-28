# AKS persistent storage

AKS workloads should use a Kubernetes PersistentVolumeClaim (PVC). Do not create `azurerm_disk` resources for application volumes: the AKS Azure Disk CSI driver creates and attaches managed disks dynamically when a PVC is bound.

## Supported paths

| Need | Use | Terraform responsibility |
| --- | --- | --- |
| Single-node block storage | AKS Azure Disk CSI driver | None; create a StorageClass/PVC in Kubernetes. |
| Shared file storage | Azure Files CSI driver | Optionally create a private Azure Files account and share with `modules/persistent-storage`. |
| Object data or backups | Azure Blob Storage | Manage it as an application data service, not a PVC. |

## Terraform configuration

The AKS root module exposes one opt-in integration. It is disabled by default.

```hcl
enable_persistent_storage = true
persistent_storage_type  = "azure_file"

azure_file_share_name     = "shared-data"
azure_file_share_quota_gb = 100
azure_file_replication_type = "ZRS"
azure_file_public_network_access_enabled = false
```

`managed_disk` is the default type. It deliberately creates no Azure resource: the CSI driver creates a managed disk after Kubernetes accepts a PVC. `azure_file` creates an encrypted StorageV2 account and SMB share with TLS 1.2, public access disabled, and shared-key access disabled.

For private AKS deployments, configure approved private endpoints and private DNS for the Azure Files account before mounting the share. This module does not grant workload identity permissions or create Kubernetes secrets; choose a CSI-driver authentication pattern appropriate to the cluster identity model.

## PVC examples

Use the AKS-provided Azure Disk StorageClass for a single-writer workload. Confirm the available StorageClass names with `kubectl get storageclass` because AKS defaults can vary by Kubernetes version.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: application-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: managed-csi
```

For Azure Files, use a CSI StorageClass approved by the platform team. Do not place storage-account keys in a Git-tracked manifest. Retrieve credentials through External Secrets or configure identity-based mounting.

## Production checks

1. Confirm the selected zone/replication strategy meets the workload RPO and RTO.
2. Restrict network access with private endpoints or approved firewall rules.
3. Encrypt and back up application data according to its data classification; Azure Files durability is not a backup policy.
4. Test restore and failover, including the application-level recovery procedure.
5. Monitor PVC capacity, CSI provisioning failures, and storage-account availability.
