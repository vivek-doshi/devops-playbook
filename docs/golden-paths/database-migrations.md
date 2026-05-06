# Golden Path — Database Migrations

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are applying schema changes to a Kubernetes-hosted database
- You need zero-downtime migrations (old app version must keep running while new pods start)
- You need a CI-integrated migration workflow (migrations run before the Deployment rollout)

Not the right path? See:
- [kubernetes-microservice.md](kubernetes-microservice.md) Step 9 — if you need the full microservice deployment workflow that references this path
- [data-pipeline.md](data-pipeline.md) Step 8 — if your migration is part of a data pipeline job

---

## Prerequisites

Run the environment checker before anything else:

```bash
bash scripts/env-checker.sh
```

Required tools:

| Tool | Version | Purpose |
|------|---------|---------|
| kubectl | 1.29+ | Apply migration Jobs and tail logs |
| kind | 0.24+ | Local Kubernetes cluster for testing migrations |

Full list with install links: [docs/guides/onboarding.md](../guides/onboarding.md)

---

## Flow

```
write migration → test locally (kind) → CI migration check
→ choose pattern → deploy migration → verify schema
→ deploy app → monitor → rollback
```

---

## Step 1 — Write the migration

### The three golden rules

Every migration must satisfy all three rules before it is merged:

1. **Backwards-compatible** — the old version of your application must be able to run against the new schema while new pods are starting up.
2. **Idempotent** — running the same migration twice must leave the schema unchanged.
3. **Tested locally** — run the full migration → rollout cycle in the local kind cluster before pushing.

### Expand / Contract pattern

Never drop a column or rename a column in the same release that removes the code using it. Use the expand/contract pattern to spread the change across four releases:

| Release | Schema change | App change |
|---------|--------------|-----------|
| Release N | `ADD` new column (nullable) | New app writes to new column; old app ignores it |
| Release N+1 | Backfill existing rows; add `NOT NULL` constraint | Both old and new app work against new schema |
| Release N+2 | No schema change | Remove code that used the old column |
| Release N+3 | `DROP` old column | Safe — nothing reads it any more |

This pattern avoids `AccessExclusiveLock` on large tables and ensures zero-downtime deployments.

### Idempotency guard

Every migration tool in this repo tracks applied versions in a schema-history table (`flyway_schema_history`, `__EFMigrationsHistory`, `alembic_version`, `schema_migrations`, `_prisma_migrations`, etc.) and will not re-apply a migration that has already run.

If you are writing raw SQL migrations, add an explicit guard:

```sql
-- PostgreSQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);
```

```sql
-- MySQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);
```

---

## Step 2 — Test locally

Use the local kind cluster to run the full migration → rollout cycle before pushing:

```bash
# Start the local kind cluster
cd local-dev/kind && ./setup.sh

# Apply the migration Job
kubectl apply -f cd/kubernetes/_patterns/db-migration-job.yaml

# Tail the migration logs
kubectl logs -f job/db-migrate -n default
```

A healthy migration run ends with a line like:

```
Successfully applied 1 migration to schema "public" (execution time 00:00.234s)
```

If the logs loop on `Waiting for postgres:5432...`, the database pod is not ready — check `kubectl get pods -n default`.

Script: [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh)  
Pattern: [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml)

---

## Step 3 — CI integration

Migrations run as a dedicated CI step **before** the Deployment rollout. The migration step uses the same container image as the application — migration scripts are bundled in the image.

```yaml
# .github/workflows/deploy.yml — add this step before the Deployment rollout
- name: Run database migration
  run: |
    kubectl apply -f cd/kubernetes/_patterns/db-migration-job.yaml
    kubectl wait --for=condition=complete job/db-migrate \
      --timeout=600s -n $NAMESPACE
```

If the Job fails or times out, the CI pipeline fails and the Deployment rollout does not proceed.

Reference: [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml)

---

## Step 4 — Choose the migration pattern

Use the decision tree from [`docs/guides/database-migrations.md`](../guides/database-migrations.md) to select the right pattern:

| Pattern | File | When to use |
|---------|------|-------------|
| Init container | [`cd/kubernetes/_patterns/db-migration-init-container.yaml`](../../cd/kubernetes/_patterns/db-migration-init-container.yaml) | Migration takes < 5 min; non-Helm workload; runs on every pod start |
| Job | [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml) | Migration takes > 5 min; backfills; one-time run-once jobs |
| Helm hook | [`cd/kubernetes/_patterns/db-migration-hook.yaml`](../../cd/kubernetes/_patterns/db-migration-hook.yaml) | Helm-managed apps; Helm blocks and rolls back automatically on failure |

> **Rule:** Migrations longer than 5 minutes MUST use the Job pattern, not init containers, to avoid blocking pod rollouts.

---

## Step 5 — Zero-downtime checklist

Complete this checklist before running any migration in production:

- [ ] Migration is backwards-compatible (old app version can run against the new schema)
- [ ] Migration is idempotent (safe to run twice without side effects)
- [ ] Rollback migration script is written and tested
- [ ] `activeDeadlineSeconds` is set on the Job or init container
- [ ] Database backup has been taken within the last 24 hours
- [ ] Migration has been tested on a staging environment with production-scale data volume

Do not proceed to production until all six items are checked.

---

## Step 6 — Monitor the migration

### Tail logs in real time

```bash
# For a Job:
kubectl logs -f job/db-migrate -n <namespace>

# For an init container (while it is running):
kubectl logs <pod> -c db-migrate -n <namespace>
```

### Prometheus alert for migration failures

Add this alert rule to [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/):

```yaml
- alert: DatabaseMigrationFailed
  expr: kube_job_failed{job_name=~"db-migrate.*"} > 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Database migration Job failed"
    description: "Job {{ $labels.job_name }} in namespace {{ $labels.namespace }} has failed."
```

### Detect lock contention

If the migration hangs after connecting to the database, check for lock contention:

```sql
-- PostgreSQL: find queries holding or waiting for locks
SELECT pid, state, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE state != 'idle';
```

A migration holding an `AccessExclusiveLock` on a large table can block for minutes. Use the expand/contract pattern (Step 1) to avoid this.

---

## Step 7 — Rollback procedure

> **Ordering rule: always roll back the schema before rolling back the application.**

### Init container pattern

```bash
# 1. Roll back the Deployment to the previous revision (reverts app code + init container)
kubectl rollout undo deployment/my-app -n <namespace>

# 2. Confirm pods come up
kubectl rollout status deployment/my-app -n <namespace>

# 3. If the schema change needs to be reverted, apply the rollback migration manually:
kubectl apply -f path/to/rollback-job.yaml
kubectl wait --for=condition=complete job/db-rollback --timeout=300s -n <namespace>
```

### Job pattern

```bash
# 1. Run your rollback Job (write this alongside each forward migration)
kubectl apply -f cd/kubernetes/_patterns/db-rollback-job.yaml

# 2. Wait for completion
kubectl wait --for=condition=complete job/db-rollback --timeout=600s -n <namespace>

# 3. Roll back the Deployment
kubectl rollout undo deployment/my-app -n <namespace>
```

### Helm hook pattern

```bash
# Helm does NOT roll back the migration Job automatically.
# Run the rollback migration manually before helm rollback.

# 1. Apply rollback migration Job
kubectl apply -f path/to/rollback-job.yaml
kubectl wait --for=condition=complete job/db-rollback --timeout=600s -n <namespace>

# 2. Roll back the Helm release
helm rollback <release-name> <previous-revision> -n <namespace>

# Check revision history:
helm history <release-name> -n <namespace>
```

Full rollback reference: [`docs/guides/database-migrations.md`](../guides/database-migrations.md)

---

## Step 8 — Backup before major migrations

Take a namespace-level snapshot before any destructive migration (column drops, table renames, data purges):

```bash
# Namespace snapshot via Velero
kubectl apply -f backup/velero/namespace-backup.yaml
```

For database-level backups, use the cloud-specific Terraform configuration:

| Cloud | Terraform file |
|-------|---------------|
| AWS RDS | [`backup/terraform/aws-rds-backup.tf`](../../backup/terraform/aws-rds-backup.tf) |
| Azure PostgreSQL | [`backup/terraform/azure-postgres-backup.tf`](../../backup/terraform/azure-postgres-backup.tf) |
| GCP Cloud SQL | [`backup/terraform/gcp-cloudsql-backup.tf`](../../backup/terraform/gcp-cloudsql-backup.tf) |

Reference: [`backup/velero/namespace-backup.yaml`](../../backup/velero/namespace-backup.yaml)

---

## Guardrails

| Rule | Enforced by |
|------|-------------|
| Every migration must be backwards-compatible | Code review + expand/contract pattern |
| Every migration must be idempotent | Migration tool schema-history table + code review |
| Rollback migration script required alongside every forward migration | Code review |
| `activeDeadlineSeconds` set on all migration Jobs and init containers | Code review + CI lint |
| Database backup taken within 24 hours before destructive migrations | Zero-downtime checklist (Step 5) |
| Migration tested on staging with production-scale data before production | Zero-downtime checklist (Step 5) |
| Database credentials sourced from External Secrets — never hardcoded | External Secrets Operator + code review |
| Schema rollback before app rollback | Rollback procedure (Step 7) |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Writing migrations (Steps 1–3), choosing the pattern (Step 4), completing the zero-downtime checklist (Step 5), writing rollback migrations (Step 7) |
| Platform team | Kubernetes cluster, CI pipeline integration (Step 3), Prometheus alert rules (Step 6), Velero backup configuration (Step 8) |
| DBA | Reviewing migrations for lock contention and performance impact, approving destructive migrations, verifying backups (Step 8) |

---

## Related paths and guides

- [kubernetes-microservice.md](kubernetes-microservice.md) — Step 9 references this path for schema migration guidance
- [data-pipeline.md](data-pipeline.md) — Step 8 references this path for pipeline-triggered migrations
- [docs/guides/database-migrations.md](../guides/database-migrations.md) — the underlying reference guide; this golden path is the workflow wrapper
- [multi-tenant-saas.md](multi-tenant-saas.md) — uses this path for per-tenant schema isolation and migrations
