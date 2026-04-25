# Disaster Recovery Runbook

This document is the operational runbook for recovering from a cluster failure, data-center outage, or database corruption. Use the decision tree to identify which recovery procedure applies to your situation.

## RTO / RPO Summary

| Component | RPO (data loss) | RTO (downtime) | Recovery method |
|-----------|----------------|----------------|-----------------|
| Kubernetes workloads | 24 h (daily backup) | 2 h | Velero restore to new cluster |
| AWS RDS | 5 min (PITR) | 1 h | RDS PITR restore |
| Azure PostgreSQL | 5 min (PITR) | 1–2 h | Flexible Server PITR / geo-restore |
| GCP Cloud SQL | 5 min (PITR) | 30 min | Cloud SQL PITR or replica promotion |
| Secrets (ESO) | 0 (live in cloud store) | 15 min | Reinstall ESO + apply ClusterSecretStore |

## Decision Tree

```
Is the entire cluster gone?
├── Yes → Section 1: Cluster Recovery
└── No
    └── Is the database corrupted or unavailable?
        ├── Yes → Section 2: Database Recovery
        └── No
            └── Is a namespace/workload corrupted?
                └── Yes → Section 3: Namespace Restore
```

---

## Section 1: Cluster Recovery (total cluster loss)

### 1.1 Provision a new cluster

Use your existing Terraform configuration:

```bash
# AWS EKS
terraform -chdir=terraform/aws-eks apply -var="project=<project>" -var="environment=production"

# Azure AKS
terraform -chdir=terraform/azure-aks apply -var="project=<project>" -var="environment=production"
```

### 1.2 Restore Velero backups

```bash
# Install Velero on the new cluster (points to the SAME backup bucket)
bash backup/velero/aws-install.sh   # or azure/gcp equivalent

# List available backups
velero backup get

# Restore the latest scheduled backup
velero restore create \
  --from-schedule daily-full-backup \
  --restore-volumes=true

# Monitor restore progress
velero restore describe <restore-name> --details

# Watch all pods come up
kubectl get pods -A --watch
```

### 1.3 Restore secrets (External Secrets Operator)

Velero backs up ExternalSecret and ClusterSecretStore resources. Once the restore completes, ESO will re-sync all secrets from the cloud store automatically.

```bash
# Verify ESO pods are running
kubectl get pods -n external-secrets-system

# Check ExternalSecret sync status
kubectl get externalsecret -A
```

### 1.4 Validate cluster health

```bash
kubectl get nodes
kubectl get pods -A
kubectl get ingress -A

# Run a smoke test against each exposed endpoint
curl -f https://my-app.example.com/health
```

---

## Section 2: Database Recovery

### 2a: AWS RDS Point-in-Time Restore

```bash
# Find the last good timestamp (before the corruption event)
aws rds describe-db-instances \
  --db-instance-identifier rds-<project>-production

# Restore to a new RDS instance
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier rds-<project>-production \
  --target-db-instance-identifier rds-<project>-production-restored \
  --restore-time "2024-01-15T14:30:00Z"   # <-- CHANGE THIS: last known good timestamp

# Wait for the instance to be available (~10-20 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier rds-<project>-production-restored

# Promote the restored instance by updating the connection string
# in your application's secret (in AWS Secrets Manager), then restart pods.
```

### 2b: AWS RDS Cross-Region Failover (regional outage)

```bash
# Promote the cross-region read replica (requires enable_cross_region_replica = true)
aws rds promote-read-replica \
  --db-instance-identifier rds-<project>-production-dr \
  --region us-west-2   # <-- CHANGE THIS: DR region

# Wait for promotion to complete
aws rds wait db-instance-available \
  --db-instance-identifier rds-<project>-production-dr \
  --region us-west-2
```

### 2c: Azure PostgreSQL PITR

```bash
# Portal or CLI restore to a specific point in time
az postgres flexible-server restore \
  --name psql-<project>-production-restored \
  --resource-group <rg> \
  --source-server psql-<project>-production \
  --restore-time "2024-01-15T14:30:00Z"   # <-- CHANGE THIS

# Geo-restore (regional outage)
az postgres flexible-server geo-restore \
  --name psql-<project>-production-dr \
  --resource-group <dr-rg> \
  --location westus \
  --source-server /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-<project>-production
```

### 2d: GCP Cloud SQL PITR

```bash
# Clone to a new instance at a specific point in time
gcloud sql instances clone sql-<project>-production sql-<project>-production-restored \
  --point-in-time "2024-01-15T14:30:00.000Z"   # RFC 3339 format

# Cross-region replica promotion (regional outage)
gcloud sql instances promote-replica sql-<project>-production-dr \
  --project <project>
```

---

## Section 3: Namespace / Workload Restore

```bash
# List available backups
velero backup get

# Restore a single namespace from the most recent backup
velero restore create \
  --from-backup daily-full-backup-<timestamp> \
  --include-namespaces production \
  --restore-volumes=true

# Restore a single Deployment (no volume restore needed for stateless apps)
velero restore create \
  --from-backup daily-full-backup-<timestamp> \
  --include-resources deployments \
  --selector app=my-app

# Watch the restore
velero restore describe <restore-name> --details
kubectl get pods -n production --watch
```

---

## Post-Recovery Checklist

- [ ] All pods are Running (no CrashLoopBackOff)
- [ ] Ingress endpoints respond with HTTP 200
- [ ] Database connection strings point to the recovered instance
- [ ] ExternalSecrets are Synced (`kubectl get externalsecret -A`)
- [ ] Monitoring/alerting is active (Prometheus targets healthy)
- [ ] On-call acknowledged — incident ticket updated with timeline
- [ ] Post-mortem scheduled within 48 hours

## Runbook Maintenance

Review this runbook quarterly and after every DR exercise. Verify:

1. Velero backup schedule is running: `velero schedule get`
2. Latest backup is healthy: `velero backup describe <latest> --details`
3. RTO/RPO targets are still achievable given current data growth
4. Contact list and escalation path are up to date
