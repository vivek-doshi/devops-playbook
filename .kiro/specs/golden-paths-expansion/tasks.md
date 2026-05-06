# Implementation Plan: Golden Paths Expansion

## Overview

Create three new golden path documents (`mobile-backend.md`, `database-migrations.md`, `multi-tenant-saas.md`) under `docs/golden-paths/`, then update `docs/golden-paths/kubernetes-microservice.md` to cross-link to all three. All tasks produce Markdown files only — no new infrastructure artefacts are introduced.

## Tasks

- [x] 1. Create `docs/golden-paths/mobile-backend.md`
  - [x] 1.1 Write the full `mobile-backend.md` golden path document
    - Add level-1 heading `# Golden Path — Mobile Backend` and standard subtitle `> **An opinionated, end-to-end workflow that guides developers from idea → production**`
    - Add "When to use this path" section with bullet criteria (building a BFF for mobile apps, Kubernetes deployment target, need API versioning + auth + push notifications + rate limiting) and "Not the right path?" cross-links to `kubernetes-microservice.md` and `serverless-app.md`
    - Add Prerequisites section with `bash scripts/env-checker.sh` as the first action, plus a tool table for any additional tools
    - Add Flow section with ASCII art pipeline diagram: `local dev → pre-commit → CI (build + test + scan) → Docker image → Kubernetes deploy → API versioning → OAuth/OIDC → push notifications → rate limiting → observability → alerts`
    - Add Step 1 (local dev): `bash local-dev/kind/setup.sh` + Docker Compose, referencing `local-dev/kind/setup.sh` and `local-dev/kind/kind-config.yaml`
    - Add Step 2 (pre-commit hooks): `make hooks`, referencing `.pre-commit-config.yaml` and `docs/guides/pre-commit-setup.md`
    - Add Step 3 (CI pipeline): reusable workflows table from `ci/github-actions/_shared/`, security scans table identical to `kubernetes-microservice.md`
    - Add Step 4 (Docker image): `reusable-docker-build.yml` usage snippet, referencing `ci/github-actions/_shared/reusable-docker-build.yml`
    - Add Step 5 (API versioning): two-row strategy table (URL path default, header alternative); Ingress YAML snippet routing `/v1/` and `/v2/` to `mobile-bff:8080`; 12-month deprecation policy; `Deprecation` response header requirement
    - Add Step 6 (OAuth 2.0/OIDC with PKCE): Authorization Code + PKCE (RFC 7636) requirement; BFF as resource server validating `Authorization: Bearer <token>`; refresh token rotation rule; ESO reference for JWKS/credentials; list Auth0, Keycloak, AWS Cognito, Azure AD B2C as supported providers
    - Add Step 7 (push notifications): architecture flow diagram (`Mobile app → BFF → ExternalSecret → Notification service → APNs/FCM`); `device_tokens` table scoped to `user_id`, upserted on every app launch; APNs/FCM keys via ESO, referencing `secrets/external-secrets/`
    - Add Step 8 (rate limiting): nginx-ingress annotation snippet with `limit-rps: "20"`, `limit-connections: "10"`, `limit-burst-multiplier: "5"`; per-user Redis sliding window for post-auth rate limiting; rule that all public endpoints must have rate limiting
    - Add Step 9 (observability): mobile-specific Prometheus metrics table with `http_requests_total{version="v1"}`, `auth_token_validation_errors_total`, `push_notification_delivery_failures_total`, `rate_limit_rejections_total` and their alert thresholds; reference `observability/prometheus/alerts/`
    - Add Guardrails table: PKCE required (code review + integration test), refresh token rotation (IdP config), `Deprecation` header on sunset versions (BFF middleware), rate limiting on all public endpoints (Ingress annotations), device tokens encrypted at rest (DB encryption + ESO), no `latest` image tags (`policy/kyverno/disallow-latest-tag.yaml`)
    - Add Responsibilities table with Developer, Platform team, and Security team rows
    - Cross-link to `kubernetes-microservice.md`, `serverless-app.md`, `docs/guides/secrets-management.md`, `docs/guides/github-actions-oidc.md`
    - Verify all file references point to files that exist in the repository before saving
    - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4, 6.5, 19.1_

  - [x] 1.2 Verify structural completeness of `mobile-backend.md`
    - Check the file contains all required Structural_Template sections: `# Golden Path — Mobile Backend` heading, "When to use this path" section, Prerequisites section with `bash scripts/env-checker.sh`, Flow section, at least Steps 1–9, Guardrails table with Rule and "Enforced by" columns, Responsibilities table with Developer and Platform team rows
    - Check the "Not the right path?" subsection contains at least two cross-links
    - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7_

  - [x] 1.3 Verify file reference integrity of `mobile-backend.md`
    - For every relative file link in `mobile-backend.md` (pattern `[text](../../path/to/file)`), confirm the referenced file exists in the repository
    - Flag any broken references and fix them before marking complete
    - _Requirements: 6.5_

- [x] 2. Create `docs/golden-paths/database-migrations.md`
  - [x] 2.1 Write the full `database-migrations.md` golden path document
    - Add level-1 heading `# Golden Path — Database Migrations` and standard subtitle
    - Add "When to use this path" section with bullet criteria (applying schema changes to a Kubernetes-hosted database, need zero-downtime migrations, need CI-integrated migration workflow) and "Not the right path?" cross-links to `kubernetes-microservice.md` (Step 9) and `data-pipeline.md` (Step 8)
    - Add Prerequisites section with `bash scripts/env-checker.sh` as the first action, plus kubectl and kind in the tool table
    - Add Flow section with ASCII art diagram: `write migration → test locally (kind) → CI migration check → choose pattern → deploy migration → verify schema → deploy app → monitor → rollback`
    - Add Step 1 (write the migration): three golden rules (backwards-compatible, idempotent, tested locally); expand/contract pattern with four-release timeline (`Release N: ADD nullable column`, `Release N+1: backfill + NOT NULL`, `Release N+2: remove old code`, `Release N+3: DROP column`); idempotency guard SQL examples for PostgreSQL and MySQL
    - Add Step 2 (test locally): `cd local-dev/kind && ./setup.sh`, `kubectl apply -f cd/kubernetes/_patterns/db-migration-job.yaml`, `kubectl logs -f job/db-migrate -n default`
    - Add Step 3 (CI integration): GitHub Actions YAML snippet with `kubectl apply -f cd/kubernetes/_patterns/db-migration-job.yaml` + `kubectl wait --for=condition=complete job/db-migrate --timeout=600s -n $NAMESPACE`; note that migration scripts are bundled in the same image as the application; reference `cd/kubernetes/_patterns/db-migration-job.yaml`
    - Add Step 4 (choose migration pattern): decision tree table with Pattern, File, and When columns linking to `cd/kubernetes/_patterns/db-migration-init-container.yaml`, `cd/kubernetes/_patterns/db-migration-job.yaml`, `cd/kubernetes/_patterns/db-migration-hook.yaml`
    - Add Step 5 (zero-downtime checklist): six-item checklist — migration is backwards-compatible, migration is idempotent, rollback migration script written and tested, `activeDeadlineSeconds` set on Job/init container, database backup taken within last 24 hours, migration tested on staging with production-scale data volume
    - Add Step 6 (monitor the migration): `kubectl logs -f job/db-migrate -n <namespace>` and `kubectl logs <pod> -c db-migrate -n <namespace>` commands; Prometheus alert YAML `alert: DatabaseMigrationFailed, expr: kube_job_failed{job_name=~"db-migrate.*"} > 0`; PostgreSQL lock contention query (`pg_stat_activity` WHERE state != 'idle')
    - Add Step 7 (rollback procedure): all three rollback procedures from `docs/guides/database-migrations.md` (init container, Job, Helm hook); explicit ordering rule — schema rollback before app rollback
    - Add Step 8 (backup before major migrations): `kubectl apply -f backup/velero/namespace-backup.yaml`; references to `backup/terraform/aws-rds-backup.tf`, `backup/terraform/azure-postgres-backup.tf`, `backup/terraform/gcp-cloudsql-backup.tf`
    - Add Guardrails table and Responsibilities table (Developer, Platform team, DBA)
    - Cross-link to `kubernetes-microservice.md` Step 9, `data-pipeline.md` Step 8, `docs/guides/database-migrations.md`, `multi-tenant-saas.md`
    - Verify all file references point to files that exist in the repository before saving
    - _Requirements: 1.2, 1.4, 1.5, 1.6, 1.7, 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.3, 9.1, 9.2, 10.1, 10.2, 10.3, 11.1, 11.2, 11.3, 11.4, 11.5, 19.1_

  - [x] 2.2 Verify structural completeness of `database-migrations.md`
    - Check the file contains all required Structural_Template sections: `# Golden Path — Database Migrations` heading, "When to use this path" section, Prerequisites section with `bash scripts/env-checker.sh`, Flow section, at least Steps 1–8, Guardrails table, Responsibilities table
    - Check the zero-downtime checklist contains all six items from Requirement 9.2
    - _Requirements: 1.2, 9.1, 9.2_

  - [x] 2.3 Verify file reference integrity of `database-migrations.md`
    - For every relative file link in `database-migrations.md`, confirm the referenced file exists in the repository
    - Flag any broken references and fix them before marking complete
    - _Requirements: 11.5_

- [x] 3. Create `docs/golden-paths/multi-tenant-saas.md`
  - [x] 3.1 Write the full `multi-tenant-saas.md` golden path document
    - Add level-1 heading `# Golden Path — Multi-Tenant SaaS` and standard subtitle
    - Add "When to use this path" section with bullet criteria (building a SaaS product on Kubernetes, need tenant isolation, need automated onboarding, need billing instrumentation) and "Not the right path?" cross-links to `kubernetes-microservice.md` and `database-migrations.md`
    - Add Prerequisites section with `bash scripts/env-checker.sh` as the first action, plus kubectl, Terraform, and Helm in the tool table
    - Add Flow section with ASCII art diagram: `design isolation model → provision cluster → onboard first tenant → namespace + RBAC → network isolation → per-tenant secrets → per-tenant schema → billing instrumentation → tenant offboarding → observability → guardrails`
    - Add Step 1 (choose isolation model): four-column table (Model, Isolation, Cost, When to use) with namespace-per-tenant (default, ~100 tenant limit), cluster-per-tenant (escalation for regulated industries), shared namespace + labels (internal tools only); note ~100 tenant scale limit for namespace-per-tenant
    - Add Step 2 (provision cluster): reference `terraform/aws-eks/`, `terraform/azure-aks/`, `terraform/gcp-gke/`; note that multi-tenant clusters need larger node pools
    - Add Step 3 (tenant onboarding automation): tenant registry YAML example with all six required fields (`slug`, `tier`, `region`, `db_schema`, `status`, `notification_email`); list the six resources created by onboarding (namespace, RBAC, NetworkPolicy, ESO config, DB schema, ArgoCD Application); idempotency guarantee; reference `cd/gitops/argocd/application.yaml`
    - Add Step 4 (namespace and RBAC): `kubectl create namespace tenant-acme`; `kubectl apply -k cd/kubernetes/_base/rbac/ -n tenant-acme`; `kubectl apply -f cd/kubernetes/_base/network-policies/default-deny.yaml -n tenant-acme`; `kubectl apply -f cd/kubernetes/_base/network-policies/allow-egress-to-database.yaml -n tenant-acme`; `kubectl apply -f cd/kubernetes/_base/network-policies/allow-egress-to-dns.yaml -n tenant-acme`; `kubectl apply -f cd/kubernetes/_base/network-policies/allow-ingress-from-ingress-controller.yaml -n tenant-acme`
    - Add Step 5 (per-tenant secrets): naming convention `tenant-<slug>-<secret-name>`; External Secret YAML snippet with `namespace: tenant-acme`, `secretStoreRef`, and `remoteRef: key: /tenants/acme/db`; reference `secrets/external-secrets/`; cross-link to `docs/guides/secrets-management.md`
    - Add Step 6 (per-tenant schema): schema-per-tenant as default; migration Job command scoped to tenant namespace; cross-link to `database-migrations.md`; note ~1,000 tenant scale limit with PgBouncer recommendation
    - Add Step 7 (billing instrumentation): `tenant` label requirement on all Prometheus metrics; recording rule YAML `record: tenant:api_requests:rate5m, expr: sum by (tenant) (rate(http_requests_total[5m]))`; reference `observability/prometheus/` for tenant-scoped alert rules
    - Add Step 8 (tenant offboarding): ordered six-step checklist (mark `status: offboarding`, Velero backup, delete ArgoCD Application, delete namespace, drop schema with DBA approval, remove secrets); kubectl commands for `kubectl apply -f backup/velero/namespace-backup.yaml`, `kubectl delete application tenant-acme -n argocd`, `kubectl delete namespace tenant-acme`; explicit note that schema drop requires DBA approval and MUST NOT be automated; note that billing metrics must be exported before namespace deletion
    - Add Step 9 (observability): Prometheus alert rules for tenant-level failures; reference `observability/prometheus/alerts/`; notification routing via `notifications/pagerduty-notify.yml` and `notifications/slack-notify.yml`
    - Add Guardrails table covering all seven items: namespace-per-tenant (onboarding automation), NetworkPolicy deny-all default (`cd/kubernetes/_base/network-policies/default-deny.yaml`), `tenant` label required (`policy/kyverno/require-labels.yaml`), per-tenant secrets isolation (RBAC + ESO namespace scoping), schema-per-tenant isolation (connection string scoping), offboarding data export gate (Step 8 checklist), billing metrics export gate (Step 8 checklist)
    - Add Responsibilities table with Developer, Platform team, and DBA rows
    - Cross-link to `kubernetes-microservice.md`, `database-migrations.md`, `platform-onboarding.md`, `docs/guides/secrets-management.md`
    - Verify all file references point to files that exist in the repository before saving
    - _Requirements: 1.3, 1.4, 1.5, 1.6, 1.7, 12.1, 12.2, 12.3, 12.4, 12.5, 13.1, 13.2, 13.3, 13.4, 13.5, 14.1, 14.2, 14.3, 15.1, 15.2, 15.3, 15.4, 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 17.1, 17.2, 17.3, 17.4, 18.1, 18.2, 18.3, 18.4, 18.5, 19.1_

  - [x] 3.2 Verify structural completeness of `multi-tenant-saas.md`
    - Check the file contains all required Structural_Template sections: `# Golden Path — Multi-Tenant SaaS` heading, "When to use this path" section, Prerequisites section with `bash scripts/env-checker.sh`, Flow section, at least Steps 1–9, Guardrails table with all seven items from Requirement 18.1, Responsibilities table
    - Check the offboarding checklist contains all six ordered steps from Requirement 17.1
    - _Requirements: 1.3, 17.1, 18.1_

  - [x] 3.3 Verify file reference integrity of `multi-tenant-saas.md`
    - For every relative file link in `multi-tenant-saas.md`, confirm the referenced file exists in the repository
    - Flag any broken references and fix them before marking complete
    - _Requirements: 18.5_

- [x] 4. Update `docs/golden-paths/kubernetes-microservice.md` to cross-link to the three new paths
  - [x] 4.1 Add cross-links to the three new paths in `kubernetes-microservice.md`
    - Locate the existing "Not the right path?" section (currently links to `frontend-spa.md`, `serverless-app.md`, `data-pipeline.md`)
    - Add `[mobile-backend.md](mobile-backend.md) — BFF for mobile apps (API versioning, OAuth/OIDC, push notifications, rate limiting)`
    - Add `[database-migrations.md](database-migrations.md) — end-to-end workflow for zero-downtime schema migrations`
    - Add `[multi-tenant-saas.md](multi-tenant-saas.md) — namespace-per-tenant isolation, automated onboarding, billing instrumentation`
    - _Requirements: 19.2_

  - [x] 4.2 Verify cross-link integrity of the updated `kubernetes-microservice.md`
    - Confirm the three new links resolve to files that now exist at `docs/golden-paths/mobile-backend.md`, `docs/golden-paths/database-migrations.md`, and `docs/golden-paths/multi-tenant-saas.md`
    - _Requirements: 19.2_
