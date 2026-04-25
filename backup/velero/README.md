# Backup and Disaster Recovery

This directory provides patterns for backing up Kubernetes workloads (Velero) and managed databases (Terraform snippets), plus a disaster recovery runbook.

## Directory Structure

```
backup/
├── velero/
│   ├── README.md              # This file
│   ├── aws-install.sh         # Velero install on EKS with S3 backend
│   ├── schedule.yaml          # Automated backup schedule CR
│   └── namespace-backup.yaml  # On-demand namespace backup CR
└── terraform/
    ├── aws-rds-backup.tf      # AWS RDS automated backups + cross-region copy
    ├── azure-postgres-backup.tf  # Azure Database for PostgreSQL backup
    └── gcp-cloudsql-backup.tf    # GCP Cloud SQL backup
```

See also: [`docs/guides/disaster-recovery.md`](../../docs/guides/disaster-recovery.md)

## Velero Quick Start

```bash
# 1. Run the install script for your cloud:
bash backup/velero/aws-install.sh

# 2. Verify Velero is running:
kubectl get pods -n velero

# 3. Apply backup schedule:
kubectl apply -f backup/velero/schedule.yaml

# 4. Trigger an on-demand backup:
kubectl apply -f backup/velero/namespace-backup.yaml

# 5. Check backup status:
velero backup describe daily-production-backup --details
```

## Database Backup Quick Start

Apply the Terraform snippets in `backup/terraform/` inside your existing Terraform module to enable point-in-time recovery (PITR) and cross-region replication for managed databases.

## RTO / RPO Targets

| Component | RPO | RTO |
|-----------|-----|-----|
| Kubernetes workloads (Velero) | 24 h (daily backup) | 2 h |
| AWS RDS (PITR enabled) | 5 min | 1 h |
| Azure PostgreSQL (PITR enabled) | 5 min | 1 h |
| GCP Cloud SQL (daily backup) | 24 h | 2 h |

Adjust backup schedules to reduce RPO. See `disaster-recovery.md` for the full recovery procedure.
