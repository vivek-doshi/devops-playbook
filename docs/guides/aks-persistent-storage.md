# Azure AKS Persistent Storage Guide

This guide explains how to configure persistent storage for AKS workloads using Terraform.

## Overview

Persistent storage is essential for workloads that require durable storage beyond ephemeral containers. This guide covers three storage options:

1. **Azure Disk**: Block storage for database, cache, and file systems
2. **Azure File Share**: File storage with automatic backups and encryption
3. **Azure Blob Storage**: Object storage for data lakes and archival storage

## When to Use Each Storage Type

### Azure Disk
Use Azure Disk when you need:
- Block storage for databases (PostgreSQL, MySQL)
- High-performance I/O for caching layers
- File systems requiring low latency

**Best for**: Workloads with predictable I/O patterns, databases, and caching

### Azure File Share
Use Azure File Share when you need:
- File storage with automatic backups
- Encryption at rest
- Shared file systems across workloads

**Best for**: Multi-workload environments, real-time analytics, and security-sensitive workloads

### Azure Blob Storage
Use Azure Blob Storage when you need:
- Object storage for data lakes
- Archival storage and backups
- Scalable, durable storage

**Best for**: Data lakes, backups, archival storage, and large-scale data workloads

## Configuration

### Enable Persistent Storage

Enable the module by setting `enable_persistent_storage = true` in your Terraform configuration:

```hcl
variable "enable_persistent_storage" {
  default = true
}
```

### Choose Storage Type

Select the storage type based on your workload requirements:

```hcl
variable "storage_type" {
  default = "disk"  # disk, file-share, or blob-storage
}
```

### Configure Storage Parameters

#### Azure Disk Configuration

```hcl
variable "storage_type" {
  default = "disk"
}

variable "storage_class_name" {
  default = "standard"  # standard, premium, or ultra
}

variable "storage_size" {
  default = 100  # GB
}

variable "storage_sku" {
  default = "Standard_LRSs"  # Standard_LRSs, Standard_GRSs, Standard_RRSs
}

variable "storage_zone" {
  default = "1"  # Availability zone
}

variable "storage_resource_group_name" {
  default = "default"  # Resource group for storage resources
}

variable "storage_location" {
  default = "eastus"  # Azure region
}
```

#### Azure File Share Configuration

```hcl
variable "storage_type" {
  default = "file-share"
}

variable "storage_class_name" {
  default = "standard"  # Storage class for file share
}

variable "storage_access_tier" {
  default = "TransactionOptimized"  # TransactionOptimized, Hot, or Cool
}

variable "storage_enable_https" {
  default = true  # Enable HTTPS
}

variable "storage_network_acl" {
  default = true  # Enable network ACL
}
```

#### Azure Blob Storage Configuration

```hcl
variable "storage_type" {
  default = "blob-storage"
}

variable "storage_class_name" {
  default = "standard"  # Storage class for blob storage
}

variable "storage_force_destroy" {
  default = false  # Force destroy on deletion
}
```

## Usage in Workloads

### Kubernetes Storage Classes

Configure storage classes for PVCs:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: disk-storage
provisioner: "disk.csi.azure.com"
volumeType: "standard"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: file-share-storage
provisioner: "file-share.csi.azure.com"
volumeType: "standard"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: blob-storage
provisioner: "blob.csi.azure.com"
```

### Persistent Volume Claims

Create PVCs using the storage class:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: "100Gi"
  storageClassName: disk-storage
```

## Security Considerations

### Encryption

Enable encryption for sensitive workloads:

```hcl
variable "storage_encryption" {
  default = true
}
```

### RBAC Permissions

Ensure proper RBAC permissions for storage access:

```hcl
# Disk permissions
- Microsoft.Compute/disks/read
- Microsoft.Compute/disks/write

# File Share permissions
- Microsoft.Network/fileshares/read
- Microsoft.Network/fileshares/write

# Blob Storage permissions
- Microsoft.Storage/blobServices/read
- Microsoft.Storage/blobServices/write
```

## Cost Optimization

### Right-sizing

Configure storage based on workload requirements:

```hcl
variable "storage_size" {
  default = 50  # Adjust based on actual usage
}
```

### Performance vs Cost

Choose appropriate storage SKU:

```hcl
# High performance, higher cost
variable "storage_sku" {
  default = "Standard_GRSs"  # Geo-redundant standard
}

# Balanced performance, moderate cost
variable "storage_sku" {
  default = "Standard_LRSs"  # Locally redundant standard
}

# Lower performance, lower cost
variable "storage_sku" {
  default = "Standard_RRSs"  # Redundant standard
}
```

### Zone Selection

Choose appropriate availability zone:

```hcl
variable "storage_zone" {
  default = "1"  # Primary zone for high availability
}

variable "storage_location" {
  default = "eastus"  # Region for storage resources
}
```

## Backup and Recovery

### File Share Automatic Backups

Azure File Share provides automatic backups:

```hcl
# Configure backup retention
variable "backup_retention_days" {
  default = 14
}
```

### Blob Storage Lifecycle Policies

Implement lifecycle policies for cost savings:

```hcl
# Archive old data
variable "lifecycle_policy" {
  transition_to_archive = "90d"
  expiration = "365d"
}
```

## Monitoring and Alerts

### Storage Metrics

Monitor storage usage:

```bash
# Disk metrics
az monitor metrics list --resource-group <rg> --resource-type Microsoft.Compute/disks --metric "UsedBytes" --time-ago 1d

# File Share metrics
az monitor metrics list --resource-group <rg> --resource-type Microsoft.Network/fileshares --metric "ConnectionCount" --time-ago 1d

# Blob Storage metrics
az monitor metrics list --resource-group <rg> --resource-type Microsoft.Storage/blobServices --metric "BucketSize" --time-ago 1d
```

### Alerting

Set up alerts for storage thresholds:

```yaml
# Azure Monitor alert rules
groups:
- name: storage
  rules:
  - alert: DiskUtilization
    expr: azure_disk_utilization > 80
    annotations:
      summary: "Disk utilization high"
```

## Troubleshooting

### Common Issues

#### Disk Creation Fails

**Problem**: Disk creation fails with "Insufficient capacity"

**Solution**: Increase `storage_size` or reduce SKU requirements

#### File Share Performance Issues

**Problem**: File Share performance lower than expected

**Solution**: Increase `storage_access_tier` to "Hot" or adjust `storage_class_name`

#### Blob Storage Access Denied

**Problem**: Workloads cannot access Blob Storage

**Solution**: Verify RBAC permissions and storage account policies

## Migration Guide

### From Local Storage to Persistent Storage

**Before**: Workloads using ephemeral storage

**After**: Workloads using persistent storage

### Migration Steps

1. **Enable persistent storage module**
   ```hcl
   variable "enable_persistent_storage" {
     default = true
   }
   ```

2. **Configure storage type**
   ```hcl
   variable "storage_type" {
     default = "disk"  # or file-share, blob-storage
   }
   ```

3. **Create PVCs for workloads**
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: data-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: "100Gi"
     storageClassName: disk-storage
   ```

4. **Update workloads to use PVCs**
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: app
   spec:
     containers:
     - name: app
       image: myapp:latest
       volumeMounts:
       - name: data
         mountPath: /data
         volumeClaim: data-pvc
   ```

## Best Practices

1. **Enable only when needed**: Set `enable_persistent_storage = true` only when required
2. **Choose appropriate type**: Use Disk for block storage, File Share for file systems, Blob Storage for object storage
3. **Size appropriately**: Configure `storage_size` based on workload requirements
4. **Enable encryption**: Set `storage_encryption = true` for security
5. **Use multi-zone deployment**: Enable `storage_zone` for high availability workloads
6. **Monitor usage**: Regularly monitor storage metrics and adjust sizing
7. **Implement lifecycle policies**: Use Blob Storage lifecycle policies for cost savings
8. **Backup important data**: Enable File Share automatic backups for critical workloads

## Related Resources

- [Azure Disk Documentation](https://learn.microsoft.com/azure/virtual-machines/disks/)
- [Azure File Share Documentation](https://learn.microsoft.com/azure/storage/files/)
- [Azure Blob Storage Documentation](https://learn.microsoft.com/azure/storage/blobs/)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/)
- [Terraform Azure Storage](https://registry.terraform.io/modules/terraform-azure-modules/storage/latest/docs/storage)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review [Best Practices](#best-practices)
- Consult [Azure Documentation](https://learn.microsoft.com/azure/)
- Contact platform team for AKS storage configuration
