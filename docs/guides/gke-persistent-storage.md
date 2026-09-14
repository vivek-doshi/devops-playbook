# Google GKE Persistent Storage Guide

This guide explains how to configure persistent storage for GKE workloads using Terraform.

## Overview

Persistent storage is essential for workloads that require durable storage beyond ephemeral containers. This guide covers three storage options:

1. **Persistent Disk**: Block storage for database, cache, and file systems
2. **Cloud Storage**: Object storage for data lakes and archival storage
3. **Memorystore**: In-memory storage for caching and real-time workloads

## When to Use Each Storage Type

### Persistent Disk
Use Persistent Disk when you need:
- Block storage for databases (PostgreSQL, MySQL)
- High-performance I/O for caching layers
- File systems requiring low latency

**Best for**: Workloads with predictable I/O patterns, databases, and caching

### Cloud Storage
Use Cloud Storage when you need:
- Object storage for data lakes
- Archival storage and backups
- Scalable, durable storage

**Best for**: Data lakes, backups, archival storage, and large-scale data workloads

### Memorystore
Use Memorystore when you need:
- In-memory caching for high-performance workloads
- Real-time analytics and low-latency access
- Shared memory across workloads

**Best for**: Caching layers, real-time analytics, and high-performance workloads

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
  default = "persistent-disk"  # persistent-disk, cloud-storage, or memorystore
}
```

### Configure Storage Parameters

#### Persistent Disk Configuration

```hcl
variable "storage_type" {
  default = "persistent-disk"
}

variable "storage_class_name" {
  default = "standard"  # standard, premium, or ultra
}

variable "storage_size" {
  default = 100  # GB
}

variable "storage_disk_type" {
  default = "pd-balanced"  # pd-balanced, pd-ssd, pd-hdd, or pd-ultra
}

variable "storage_zone" {
  default = "us-central1-a"  # Zone for Persistent Disk
}

variable "storage_location" {
  default = "us-central1"  # Location for storage resources
}
```

#### Cloud Storage Configuration

```hcl
variable "storage_type" {
  default = "cloud-storage"
}

variable "storage_class_name" {
  default = "standard"  # Storage class for Cloud Storage
}

variable "storage_location" {
  default = "us-central1"  # GCP region for bucket
}

variable "storage_force_destroy" {
  default = false  # Force destroy on deletion
}

variable "storage_uniform_access" {
  default = true  # Enable uniform bucket level access
}
```

#### Memorystore Configuration

```hcl
variable "storage_type" {
  default = "memorystore"
}

variable "storage_tier" {
  default = "PREMIUM"  # PREMIUM or STANDARD
}

variable "storage_node_count" {
  default = 3  # Node count for Memorystore cluster
}

variable "storage_node_memory_gb" {
  default = 512  # Memory per node in GB
}

variable "storage_automatic_failover" {
  default = true  # Enable automatic failover
}
```

## Usage in Workloads

### Kubernetes Storage Classes

Configure storage classes for PVCs:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: persistent-disk-storage
provisioner: "compute.csi.gcp.io"
volumeType: "pd-balanced"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cloud-storage-storage
provisioner: "storage.csi.gcp.io"
volumeType: "standard"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: memorystore-storage
provisioner: "memorystore.csi.gcp.io"
volumeType: "PREMIUM"
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
  storageClassName: persistent-disk-storage
```

## Security Considerations

### IAM Permissions

Ensure proper IAM permissions for storage access:

```hcl
# Persistent Disk permissions
- compute.disks.get
- compute.disks.create
- compute.disks.attach

# Cloud Storage permissions
- storage.objects.get
- storage.objects.create
- storage.objects.delete

# Memorystore permissions
- memorystore.clusters.get
- memorystore.clusters.create
- memorystore.clusters.delete
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

Choose appropriate disk type:

```hcl
# High performance, higher cost
variable "storage_disk_type" {
  default = "pd-ssd"  # SSD storage
}

# Balanced performance, moderate cost
variable "storage_disk_type" {
  default = "pd-balanced"  # Balanced performance
}

# Lower performance, lower cost
variable "storage_disk_type" {
  default = "pd-hdd"  # HDD storage
}
```

### Zone Selection

Choose appropriate zone for high availability:

```hcl
variable "storage_zone" {
  default = "us-central1-a"  # Primary zone for high availability
}

variable "storage_location" {
  default = "us-central1"  # Region for storage resources
}
```

## Backup and Recovery

### Cloud Storage Lifecycle Policies

Implement lifecycle policies for cost savings:

```hcl
# Archive old data
variable "lifecycle_policy" {
  transition_to_ia = "90d"
  expiration = "365d"
}
```

### Memorystore Backup

Memorystore provides automatic backups:

```hcl
# Configure backup retention
variable "backup_retention_count" {
  default = 7
}
```

## Monitoring and Alerts

### Storage Metrics

Monitor storage usage:

```bash
# Persistent Disk metrics
gcloud compute disks describe <disk-name> --format=json

# Cloud Storage metrics
gcloud storage ls --bucket=<bucket-name> --format=json

# Memorystore metrics
gcloud memorystore clusters describe <cluster-name> --format=json
```

### Alerting

Set up alerts for storage thresholds:

```yaml
# Cloud Monitoring alert rules
groups:
- name: storage
  rules:
  - alert: DiskUtilization
    expr: google_compute_disk_utilization > 80
    annotations:
      summary: "Disk utilization high"
```

## Troubleshooting

### Common Issues

#### Disk Creation Fails

**Problem**: Disk creation fails with "Insufficient capacity"

**Solution**: Increase `storage_size` or reduce disk type requirements

#### Cloud Storage Access Denied

**Problem**: Workloads cannot access Cloud Storage bucket

**Solution**: Verify IAM permissions and bucket policies

#### Memorystore Performance Issues

**Problem**: Memorystore performance lower than expected

**Solution**: Increase `storage_tier` to "PREMIUM" or adjust node count

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
     default = "persistent-disk"  # or cloud-storage, memorystore
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
     storageClassName: persistent-disk-storage
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
2. **Choose appropriate type**: Use Persistent Disk for block storage, Cloud Storage for object storage, Memorystore for caching
3. **Size appropriately**: Configure `storage_size` based on workload requirements
4. **Enable automatic failover**: Set `storage_automatic_failover = true` for high availability
5. **Use uniform access**: Enable `storage_uniform_access = true` for security
6. **Monitor usage**: Regularly monitor storage metrics and adjust sizing
7. **Implement lifecycle policies**: Use Cloud Storage lifecycle policies for cost savings
8. **Backup important data**: Enable automatic backups for critical workloads

## Related Resources

- [Persistent Disk Documentation](https://cloud.google.com/compute/docs/disks/)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs/)
- [Memorystore Documentation](https://cloud.google.com/memorystore/docs/)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/)
- [Terraform GCP Storage](https://registry.terraform.io/modules/terraform-google-modules/storage/latest/docs/storage)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review [Best Practices](#best-practices)
- Consult [GCP Documentation](https://cloud.google.com/)
- Contact platform team for GKE storage configuration
