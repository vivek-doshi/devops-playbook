# GCP GKE Persistent Storage Module

This module provisions persistent storage options for GKE workloads, including:

- **Persistent Disk**: Block storage for database, cache, and file systems
- **Cloud Storage**: Object storage for data lakes and backups
- **Memorystore**: In-memory storage for caching and real-time workloads

## Usage

Enable persistent storage by setting `enable_persistent_storage = true` in your Terraform configuration.

## Storage Types

### Persistent Disk
- **pd-balanced**: Balanced performance and cost
- **pd-ssd**: High-performance SSD storage
- **pd-hdd**: High-capacity HDD storage
- **pd-ultra**: Ultra-high performance storage

### Cloud Storage
- **Standard**: Standard storage class
- **Nearline**: Nearline storage class
- **Coldline**: Coldline storage class

### Memorystore
- **PREMIUM**: Premium tier for high-performance caching
- **STANDARD**: Standard tier for cost-effective caching

## Configuration

### Required Variables
- `enable_persistent_storage`: Enable/disable the module (default: false)
- `storage_type`: Type of storage (persistent-disk, cloud-storage, or memorystore)

### Optional Variables
- `storage_class_name`: Storage class for Persistent Disk (default: standard)
- `storage_size`: Disk size in GB (default: 100)
- `storage_disk_type`: Disk type (pd-balanced, pd-ssd, pd-hdd, pd-ultra) (default: pd-balanced)
- `storage_zone`: Zone for Persistent Disk (default: us-central1-a)
- `storage_location`: Location for Cloud Storage bucket (default: us-central1)
- `storage_tier`: Tier for Memorystore (PREMIUM or STANDARD) (default: PREMIUM)
- `storage_node_count`: Node count for Memorystore (default: 3)
- `storage_node_memory_gb`: Memory per node in GB (default: 512)
- `storage_automatic_failover`: Enable automatic failover (default: true)
- `storage_force_destroy`: Force Cloud Storage bucket deletion (default: false)
- `storage_uniform_access`: Enable uniform bucket level access (default: true)
- `storage_labels`: Additional labels for Persistent Disk (default: workload=gke, environment=var.environment)

## Outputs

- `persistent_disk_id`: ID of the Persistent Disk
- `cloud_storage_bucket_id`: ID of the Cloud Storage bucket
- `memorystore_cluster_id`: ID of the Memorystore cluster
- `storage_type`: Type of storage configured

## Best Practices

1. **Enable only when needed**: Set `enable_persistent_storage = true` only when required
2. **Choose appropriate type**: Use Persistent Disk for block storage, Cloud Storage for object storage, Memorystore for caching
3. **Size appropriately**: Configure `storage_size` based on workload requirements
4. **Enable automatic failover**: Set `storage_automatic_failover = true` for high availability
5. **Use uniform access**: Enable `storage_uniform_access = true` for security
6. **Monitor usage**: Regularly monitor storage metrics and adjust sizing
7. **Implement lifecycle policies**: Use Cloud Storage lifecycle policies for cost savings
8. **Backup important data**: Enable automatic backups for critical workloads
