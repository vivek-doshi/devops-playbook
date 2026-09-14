# AWS EKS Persistent Storage Guide

This guide explains how to configure persistent storage for EKS workloads using Terraform.

## Overview

Persistent storage is essential for workloads that require durable storage beyond ephemeral containers. This guide covers three storage options:

1. **EBS Volumes**: Block storage for database, cache, and file systems
2. **EFS File Systems**: File storage with automatic backups and encryption
3. **S3 Buckets**: Object storage for data lakes and archival storage

## When to Use Each Storage Type

### EBS Volumes
Use EBS when you need:
- Block storage for databases (PostgreSQL, MySQL)
- High-performance I/O for caching layers
- File systems requiring low latency

**Best for**: Workloads with predictable I/O patterns, databases, and caching

### EFS File Systems
Use EFS when you need:
- File storage with automatic backups
- Encryption at rest
- Shared file systems across workloads

**Best for**: Multi-workload environments, real-time analytics, and security-sensitive workloads

### S3 Buckets
Use S3 when you need:
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
  default = "ebs"  # ebs, efs, or s3
}
```

### Configure Storage Parameters

#### EBS Configuration

```hcl
variable "storage_type" {
  default = "ebs"
}

variable "storage_class_name" {
  default = "gp3"  # standard, gp2, gp3, io1
}

variable "storage_size" {
  default = 100  # GB
}

variable "storage_iops" {
  default = 3000  # IOPS
}

variable "storage_throughput" {
  default = 50  # MB/s
}

variable "storage_volume_type" {
  default = "gp3"  # gp2, gp3, io1
}
```

#### EFS Configuration

```hcl
variable "storage_type" {
  default = "efs"
}

variable "storage_performance_mode" {
  default = "performance"  # performance or general-purpose
}

variable "storage_throughput_mode" {
  default = "bursting"  # bursting or provisioned
}

variable "storage_encryption" {
  default = true  # Enable encryption
}
```

#### S3 Configuration

```hcl
variable "storage_type" {
  default = "s3"
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
  name: ebs-storage
provisioner: "ebs.csi.aws.com"
volumeType: "gp3"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-storage
provisioner: "efs.csi.aws.com"
volumeType: "performance"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: s3-storage
provisioner: "s3.csi.aws.com"
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
  storageClassName: ebs-storage
```

## Security Considerations

### Encryption

Enable encryption for sensitive workloads:

```hcl
variable "storage_encryption" {
  default = true
}
```

### IAM Permissions

Ensure proper IAM permissions for storage access:

```hcl
# EBS permissions
- s3:GetObject
- s3:PutObject
- s3:DeleteObject

# EFS permissions
- elasticfilesystem:CreateFileSystem
- elasticfilesystem:DescribeFileSystems

# S3 permissions
- s3:ListBucket
- s3:GetObject
- s3:PutObject
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

Choose appropriate storage class:

```hcl
# High performance, higher cost
variable "storage_volume_type" {
  default = "io1"  # Magnetic I/O intensive
}

# Balanced performance, moderate cost
variable "storage_volume_type" {
  default = "gp3"  # General purpose SSD
}

# Lower performance, lower cost
variable "storage_volume_type" {
  default = "gp2"  # General purpose SSD
}
```

## Backup and Recovery

### EFS Automatic Backups

EFS provides automatic backups:

```hcl
# Configure backup retention
variable "backup_retention_days" {
  default = 14
}
```

### S3 Lifecycle Policies

Implement lifecycle policies for cost savings:

```hcl
# Archive old data
variable "lifecycle_policy" {
  default = {
    transition_to_ia = "90d"
    expiration = "365d"
  }
}
```

## Monitoring and Alerts

### Storage Metrics

Monitor storage usage:

```bash
# EBS metrics
aws cloudwatch get-metrics --namespace AWS/ElasticBlockStore --dimensions Name=VolumeId --query 'MetricSummaries[*].[Timestamp,Value]' --output table

# EFS metrics
aws cloudwatch get-metrics --namespace AWS/ElasticFileSystem --dimensions Name=FileSystemId --query 'MetricSummaries[*].[Timestamp,Value]' --output table

# S3 metrics
aws cloudwatch get-metrics --namespace AWS/S3 --dimensions Name=BucketName --query 'MetricSummaries[*].[Timestamp,Value]' --output table
```

### Alerting

Set up alerts for storage thresholds:

```yaml
# Prometheus alert rules
groups:
- name: storage
  rules:
  - alert: EBSVolumeUtilization
    expr: aws_ebs_volume_utilization > 80
    annotations:
      summary: "EBS volume utilization high"
```

## Troubleshooting

### Common Issues

#### EBS Volume Creation Fails

**Problem**: Volume creation fails with "Insufficient capacity"

**Solution**: Increase `storage_size` or reduce `storage_iops` requirements

#### EFS Performance Issues

**Problem**: EFS performance lower than expected

**Solution**: Increase `storage_throughput_mode` to "provisioned" or adjust `storage_performance_mode`

#### S3 Bucket Access Denied

**Problem**: Workloads cannot access S3 bucket

**Solution**: Verify IAM permissions and bucket policies

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
     default = "ebs"  # or efs, s3
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
     storageClassName: ebs-storage
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
2. **Choose appropriate type**: Use EBS for block storage, EFS for file systems, S3 for object storage
3. **Size appropriately**: Configure `storage_size` based on workload requirements
4. **Enable encryption**: Set `storage_encryption = true` for security
5. **Use multi-attached volumes**: Enable `storage_multi_attached` for high availability workloads
6. **Monitor usage**: Regularly monitor storage metrics and adjust sizing
7. **Implement lifecycle policies**: Use S3 lifecycle policies for cost savings
8. **Backup important data**: Enable EFS automatic backups for critical workloads

## Related Resources

- [AWS EBS Documentation](https://docs.aws.amazon.com/elastic-block-store/latest/userguide/)
- [AWS EFS Documentation](https://docs.aws.amazon.com/elastic-filesystem/latest/userguide/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/)
- [Terraform AWS Storage](https://registry.terraform.io/modules/hashicorp/aws/latest/docs/storage)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review [Best Practices](#best-practices)
- Consult [AWS Documentation](https://docs.aws.amazon.com/)
- Contact platform team for EKS storage configuration
