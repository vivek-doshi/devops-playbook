# Database Migration Patterns

This guide helps you choose the right migration pattern and run it safely in Kubernetes environments.

## Decision Tree

```
Are you using Helm to deploy?
│
├── YES → Use db-migration-hook.yaml
│         Migrations run as a pre-upgrade Job before every helm upgrade.
│         Helm blocks and rolls back automatically if the Job fails.
│
└── NO → How long does the migration take?
         │
         ├── < 5 minutes → Use db-migration-init-container.yaml
         │                  Migration runs inside an init container at pod start.
         │                  Simple, no CI step needed, but runs on EVERY pod restart.
         │
         └── > 5 minutes → Use db-migration-job.yaml
                            Dedicated Job; run it in CI before the Deployment rollout.
                            Handles long-running backfills and schema changes.
```

| Pattern | File | Best for | Runs when |
|---------|------|----------|-----------|
| Init container | `db-migration-init-container.yaml` | Fast migrations (< 5 min), non-Helm workloads | Every pod start |
| Job | `db-migration-job.yaml` | Long migrations, backfills, one-time jobs | Explicitly, from CI |
| Helm hook | `db-migration-hook.yaml` | Helm-managed apps | `helm upgrade` / `helm install` |

---

## The Golden Rules

### 1. Every migration must be backwards-compatible (Expand / Contract)

The old version of your application will be running while new pods start.
If a migration drops a column the old app reads, the old pods crash.

Use the **expand/contract pattern**:

```
Release N:   ADD new column (nullable) — old app ignores it, new app writes it
Release N+1: Backfill existing rows, make column NOT NULL
Release N+2: Remove the code that used the old column
Release N+3: DROP the old column — now safe, nothing reads it
```

Never drop a column or rename a column in the same release that removes the code using it.

### 2. Migrations must be idempotent

Running the same migration twice must leave the schema unchanged.
Every migration tool in this repo satisfies this by tracking applied versions in a schema-history table (`flyway_schema_history`, `__EFMigrationsHistory`, `alembic_version`, etc.).

If you are writing raw SQL migrations, add a guard:
```sql
-- PostgreSQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);

-- MySQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);
```

### 3. Always test migrations locally before pushing

Use the Kind cluster from `local-dev/kind/` to run the full migration → rollout cycle locally:
```bash
# Start a local cluster
cd local-dev/kind
./setup.sh

# Apply the migration Job
kubectl apply -f cd/kubernetes/_patterns/db-migration-job.yaml

# Watch it run
kubectl logs -f job/db-migrate -n default
```

---

## Rollback Procedure

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
# 1. Run your rollback Job (you must write this alongside each forward migration)
kubectl apply -f cd/kubernetes/_patterns/db-rollback-job.yaml   # <-- you create this

# 2. Wait for completion
kubectl wait --for=condition=complete job/db-rollback --timeout=600s -n <namespace>

# 3. Roll back the Deployment
kubectl rollout undo deployment/my-app -n <namespace>
```

### Helm hook pattern

```bash
# Helm does NOT roll back the migration Job automatically — it only rolls back Kubernetes resources.
# You must run the rollback migration manually before or after helm rollback.

# 1. Apply rollback migration Job
kubectl apply -f path/to/rollback-job.yaml
kubectl wait --for=condition=complete job/db-rollback --timeout=600s -n <namespace>

# 2. Roll back the Helm release
helm rollback <release-name> <previous-revision> -n <namespace>

# Check revision history:
helm history <release-name> -n <namespace>
```

---

## Monitoring Migration Runs

### Tail logs in real time

```bash
# For a Job:
kubectl logs -f job/db-migrate -n <namespace>

# For an init container (while it is running):
kubectl logs <pod-name> -c db-migrate -n <namespace>

# With stern (multi-pod log tailing):
stern -l component=db-migrate -n <namespace>
```

### What a healthy migration looks like

```
[wait-for-db] Waiting for postgres:5432...
[wait-for-db] Database is up. Starting migration.
Flyway Community Edition 10.4.1 by Redgate
Database: jdbc:postgresql://postgres:5432/myapp (PostgreSQL 15.4)
Successfully validated 12 migrations (execution time 00:00.087s)
Current version of schema "public": 11
Migrating schema "public" to version 12 - add users phone column
Successfully applied 1 migration to schema "public" (execution time 00:00.234s)
```

### What a stuck migration looks like

```
[wait-for-db] Waiting for postgres:5432...
[wait-for-db]   not ready — retrying in 3s
[wait-for-db]   not ready — retrying in 3s
...
```

If `wait-for-db` loops indefinitely:
```bash
# Check if the DB pod is running
kubectl get pods -n <namespace> -l app=postgres

# Check DB pod events
kubectl describe pod <postgres-pod> -n <namespace>
```

If the migration itself hangs (no output after the DB connection is established):
```bash
# Check for a lock conflict in the DB
# PostgreSQL:
kubectl exec -it <postgres-pod> -n <namespace> -- psql -U postgres -c "
  SELECT pid, state, wait_event_type, wait_event, query
  FROM pg_stat_activity
  WHERE state != 'idle';
"
```

A migration holding an `AccessExclusiveLock` on a large table can block for minutes.
See the [expand/contract pattern](#1-every-migration-must-be-backwards-compatible-expand--contract) to avoid this.

---

## Related Files

- [`cd/kubernetes/_patterns/db-migration-init-container.yaml`](../../cd/kubernetes/_patterns/db-migration-init-container.yaml) — init container pattern
- [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml) — standalone Job pattern
- [`cd/kubernetes/_patterns/db-migration-hook.yaml`](../../cd/kubernetes/_patterns/db-migration-hook.yaml) — Helm pre-upgrade hook
- [`local-dev/kind/`](../../local-dev/kind/) — local Kind cluster for testing migrations
- [`docs/guides/environment-strategy.md`](environment-strategy.md) — environment separation
