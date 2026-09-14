# AWS EKS Persistent Storage Module

This module provisions persistent storage options for EKS workloads, including:

- **EBS Volumes**: Elastic Block Store volumes for block storage
- **EFS File Systems**: File storage with automatic backups and encryption
- **S3 Buckets**: Object storage for data lakes and backups

## Usage

Enable persistent storage by setting `enable_persistent_storage = true` in your Terraform configuration.

## Storage Types

### EBS (Elastic Block Store)
- **Standard**: General purpose storage
- **gp2**: General purpose SSD
- **gp3**: General purpose SSD with higher performance
- **io1**: Magnetic I/O intensive workloads

### EFS (Elastic File System)
- **Performance mode**: High throughput for real-time workloads
- **General-purpose mode**: Cost-effective for batch workloads
- **Bursting throughput**: Auto-scales throughput
- **Provisioned throughput**: Fixed throughput allocation

### S3 (Simple Storage Service)
- **Object storage**: For data lakes, backups, and archival storage
- **Force destroy**: Optional aggressive cleanup on deletion

## Configuration

### Required Variables
- `enable_persistent_storage`: Enable/disable the module (default: false)
- `storage_type`: Type of storage (ebs, efs, or s3)

### Optional Variables
- `storage_class_name`: Storage class for EBS (default: standard)
- `storage_size`: Volume size in GB (default: 100)
- `storage_iops`: IOPS for EBS (default: 3000)
- `storage_throughput`: Throughput in MB/s (default: 50)
- `storage_volume_type`: Volume type (gp2, gp3, io1) (default: gp3)
- `storage_performance_mode`: EFS performance mode (default: performance)
- `storage_throughput_mode`: EFS throughput mode (default: bursting)
- `storage_encryption`: Enable EFS encryption (default: true)
- `storage_multi_attached`: Multi-attached EBS volumes (default: false)
- `storage_force_destroy`: Force S3 bucket deletion (default: false)

## Outputs

- `storage_class_id`: ID of the storage class
- `efs_file_system_id`: ID of the EFS file system
- `ebs_volume_id`: ID of the EBS volume
- `s3_bucket_id`: ID of the S3 bucket
- `storage_type`: Type of storage configured

## Best Practices

1. **Enable only when needed**: Set `enable_persistent_storage = true` only when required
2. **Choose appropriate type**: Use EBS for block storage, EFS for file systems, S3 for object storage
3. **Size appropriately**: Configure `storage_size` based on workload requirements
4. **Enable encryption**: Set `storage_encryption = true` for security
5. **Use multi-attached volumes**: Enable `storage_multi_attached` for high availability workloads
