# Golden Path — Data Pipeline

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are building a scheduled or event-driven batch job
- Targets: Kubernetes CronJob, AWS ECS task, or a standalone script on a schedule
- Your workload processes data in bulk (ETL, reports, aggregations, ML training)

Not the right path? See:
- [kubernetes-microservice.md](kubernetes-microservice.md) — long-running services that handle real-time requests
- [serverless-app.md](serverless-app.md) — lightweight event-driven functions (< 15 min runtime)

---

## Prerequisites

```bash
bash scripts/env-checker.sh
```

Additional tools:

| Tool | Purpose |
|------|---------|
| kubectl 1.29+ | Manage CronJob manifests |
| AWS CLI v2 | ECS task management |
| Terraform 1.7+ | Provision infrastructure |

---

## Flow

```
local run (Docker) → pre-commit → CI (test + scan)
→ Docker image push → Terraform (infra)
→ CronJob / ECS task schedule → alerting on failure
```

---

## Step 1 — Run the job locally

Data pipeline jobs are packaged as Docker containers so the local run matches production exactly.

```bash
# Build
docker build -f docker/python/Dockerfile -t my-pipeline .

# Run with environment overrides
docker run --rm \
  -e DATABASE_URL=postgres://localhost:5432/dev \
  -e OUTPUT_BUCKET=my-bucket-dev \
  my-pipeline
```

To run with a local Postgres and Redis:

```bash
docker compose -f compose/python-postgres-redis/docker-compose.yml up
docker compose -f compose/python-postgres-redis/docker-compose.yml run pipeline
```

---

## Step 2 — Install pre-commit hooks

```bash
make hooks
```

Config: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml)  
Details: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 3 — Set up the CI pipeline

Copy the workflow into `.github/workflows/`:

| Stack | Build + test file |
|-------|-------------------|
| Python | [`ci/github-actions/python/build-test.yml`](../../ci/github-actions/python/build-test.yml) |
| Go | [`ci/github-actions/go/build-test.yml`](../../ci/github-actions/go/build-test.yml) |
| Java | [`ci/github-actions/java/build-test.yml`](../../ci/github-actions/java/build-test.yml) |

Add security scanning as a parallel job:

```yaml
uses: ./.github/workflows/reusable-security-scan.yml
```

Source: [`ci/github-actions/_shared/reusable-security-scan.yml`](../../ci/github-actions/_shared/reusable-security-scan.yml)

### Security scans for data pipelines

| Scan | File | Priority |
|------|------|---------|
| Secrets | [`security/secret-detection/gitleaks.yml`](../../security/secret-detection/gitleaks.yml) | Blocks merge |
| Container scan | [`security/container-scanning/trivy-scan.yml`](../../security/container-scanning/trivy-scan.yml) | Blocks merge |
| SAST | [`security/sast/semgrep.yml`](../../security/sast/semgrep.yml) | Blocks merge |
| Dependency audit | [`security/dependency-audit/`](../../security/dependency-audit/) | Advisory |

---

## Step 4 — Build and push the Docker image

```yaml
uses: ./.github/workflows/reusable-docker-build.yml
with:
  image-name: my-pipeline
  dockerfile: docker/python/Dockerfile
```

Source: [`ci/github-actions/_shared/reusable-docker-build.yml`](../../ci/github-actions/_shared/reusable-docker-build.yml)

---

## Step 5 — Provision infrastructure

### Kubernetes (EKS / AKS / GKE)

If your pipeline runs on Kubernetes, the cluster is already provisioned by the platform team. Skip to Step 6.

### AWS ECS (standalone task)

```bash
cd terraform/aws-ecs
terraform init
terraform apply
```

Provisions: ECS cluster, task definition, IAM execution role, CloudWatch log group.  
Files: [`terraform/aws-ecs/`](../../terraform/aws-ecs/)

---

## Step 6 — Define the job manifest

### Kubernetes CronJob

The CronJob manifest pattern is in:

```
cd/kubernetes/_patterns/db-migration-job.yaml   ← base Job pattern
```

Use this as the starting template for a CronJob:

```yaml
# my-pipeline-cronjob.yaml  (adapted from _patterns/db-migration-job.yaml)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: my-pipeline
  namespace: data
spec:
  schedule: "0 2 * * *"          # 02:00 UTC daily
  concurrencyPolicy: Forbid       # never run two instances simultaneously
  failedJobsHistoryLimit: 3
  successfulJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 2             # retry twice before marking failed
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pipeline
              image: my-pipeline:$SHA
              envFrom:
                - secretRef:
                    name: pipeline-secrets
```

Source pattern: [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml)

Key decisions encoded here:
- `concurrencyPolicy: Forbid` — prevents overlapping runs if the job takes longer than its schedule interval
- `restartPolicy: OnFailure` — Kubernetes retries the container, not the pod
- `backoffLimit: 2` — fail fast, let alerts fire, don't spin indefinitely

### AWS ECS scheduled task

Deploy via GitHub Actions:

```yaml
uses: cd/targets/aws-ecs/github-actions-deploy.yml
```

Source: [`cd/targets/aws-ecs/github-actions-deploy.yml`](../../cd/targets/aws-ecs/github-actions-deploy.yml)

---

## Step 7 — Configure secrets

Data pipelines typically need database credentials and cloud storage access. Use External Secrets Operator for Kubernetes jobs:

```yaml
# secrets/external-secrets/example-external-secret.yaml
# Change secretKey to point to your pipeline's secrets
```

File: [`secrets/external-secrets/example-external-secret.yaml`](../../secrets/external-secrets/example-external-secret.yaml)  
Store configs: [`secrets/external-secrets/aws-secret-store.yaml`](../../secrets/external-secrets/aws-secret-store.yaml)

For ECS, the task IAM role accesses Secrets Manager directly — no sidecar needed.

Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 8 — Add database migration support

If your pipeline applies schema changes before running, use the init container pattern:

```yaml
# Runs migrations before the main container starts
# source: cd/kubernetes/_patterns/db-migration-init-container.yaml
```

File: [`cd/kubernetes/_patterns/db-migration-init-container.yaml`](../../cd/kubernetes/_patterns/db-migration-init-container.yaml)

For a standalone pre-migration Job (runs once before CronJob starts):

File: [`cd/kubernetes/_patterns/db-migration-job.yaml`](../../cd/kubernetes/_patterns/db-migration-job.yaml)

Full guide: [docs/guides/database-migrations.md](../guides/database-migrations.md)

---

## Step 9 — Add observability

### Key signals for batch jobs

Batch jobs are different from services — you don't measure latency, you measure:

| Signal | What to alert on |
|--------|-----------------|
| Job completion | Failed jobs (exit code ≠ 0) |
| Job duration | Runtime exceeds expected window (SLA breach) |
| Records processed | Volume anomaly (far fewer rows than yesterday = source issue) |

### Kubernetes alerts

Prometheus fires alerts for failed jobs automatically via kube-state-metrics. Add custom alerts for duration and volume in:

```
observability/prometheus/alerts/
```

Copy an existing alert file and adapt the `job_name` label selector.

### Notifications on job failure

A failed CronJob must page the on-call engineer. Wire Alertmanager to:

```
notifications/pagerduty-notify.yml   ← production failures
notifications/slack-notify.yml       ← dev/staging failures
```

---

## Step 10 — Backup and recovery

For pipelines that write to a database, configure automated backups:

| Cloud | Terraform module |
|-------|-----------------|
| AWS RDS | [`backup/terraform/aws-rds-backup.tf`](../../backup/terraform/aws-rds-backup.tf) |
| Azure PostgreSQL | [`backup/terraform/azure-postgres-backup.tf`](../../backup/terraform/azure-postgres-backup.tf) |
| GCP Cloud SQL | [`backup/terraform/gcp-cloudsql-backup.tf`](../../backup/terraform/gcp-cloudsql-backup.tf) |

For namespace-level backup of Kubernetes workloads (including CronJob state):

```bash
kubectl apply -f backup/velero/namespace-backup.yaml
kubectl apply -f backup/velero/schedule.yaml
```

---

## Guardrails

| Rule | Enforced by |
|------|-------------|
| No secrets in code or manifests | Gitleaks + External Secrets |
| `concurrencyPolicy: Forbid` on all CronJobs | Code review, Kyverno policy planned |
| `backoffLimit` set explicitly | Code review — never leave as default (6) |
| Pipeline owner label on all Jobs | [`policy/kyverno/require-labels.yaml`](../../policy/kyverno/require-labels.yaml) |
| Database backups enabled before going live | Checklist in this guide (Step 10) |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Job code, Docker image, CronJob manifest, alert thresholds |
| Platform team | Cluster, ECS cluster, secrets store, Velero backup |
| Data / DBA | Database backup schedule, migration scripts |
