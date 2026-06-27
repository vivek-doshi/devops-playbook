# Backup and Disaster Recovery

This folder contains backup templates and recovery references for Kubernetes workloads and managed databases.

## Purpose

Use `backup/` to reduce recovery risk and codify RTO/RPO decisions.

## What's Inside

- `velero/`: Kubernetes backup schedules and restore patterns.
- `terraform/`: Backup configuration snippets for AWS RDS, Azure PostgreSQL, and GCP Cloud SQL.

## Use This Component Alone

- Configure backup jobs and retention for one platform.
- Run restore drills for a namespace or database.

## Use This Component With Others

- With `cd/`: Align deployment rollout with backup windows.
- With `terraform/`: Provision infrastructure and attach backup policies in the same delivery flow.
- With `docs/runbooks/`: Document and rehearse disaster recovery procedures.
- With `observability/` and `notifications/`: Alert on backup failures.

## Quick Start

```bash
bash backup/velero/aws-install.sh
kubectl apply -f backup/velero/schedule.yaml
kubectl apply -f backup/velero/namespace-backup.yaml
```

For managed databases, copy the relevant file from `backup/terraform/` into your existing Terraform module and adapt variables to your environment.
