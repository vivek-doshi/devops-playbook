# Requirements Document

## Introduction

This feature adds three new golden path documents to `docs/golden-paths/`:

1. **`mobile-backend.md`** — Backend for Frontend (BFF) serving mobile apps, covering API versioning, OAuth 2.0/OIDC with PKCE, push notifications (APNs/FCM), and rate limiting.
2. **`database-migrations.md`** — Promotes the existing `docs/guides/database-migrations.md` reference guide into a first-class golden path with CI integration, a zero-downtime checklist, observability, and backup integration.
3. **`multi-tenant-saas.md`** — Namespace-per-tenant isolation, automated tenant onboarding, per-tenant secrets and schemas, billing instrumentation, and an offboarding checklist.

All three documents follow the established golden path conventions used by the six existing paths in `docs/golden-paths/`. No new infrastructure files are required — all three paths reference existing repo artefacts.

---

## Glossary

- **Golden_Path**: An opinionated, end-to-end workflow document in `docs/golden-paths/` that guides developers from idea to production by referencing existing repo artefacts.
- **Golden_Path_Document**: A Markdown file in `docs/golden-paths/` that follows the established structural template.
- **Structural_Template**: The shared document structure used by all golden paths: header, subtitle, "When to use" section, Prerequisites section, Flow diagram, numbered steps with code blocks and file references, Guardrails table, and Responsibilities table.
- **File_Reference**: A Markdown link in a golden path document that points to a file in the repository (e.g., `[name](../../path/to/file)`).
- **BFF**: Backend for Frontend — a server-side API layer purpose-built for a specific client type (in this case, mobile apps).
- **PKCE**: Proof Key for Code Exchange (RFC 7636) — a security extension to the OAuth 2.0 Authorization Code flow that protects against authorization code interception attacks.
- **APNs**: Apple Push Notification service — Apple's platform for delivering push notifications to iOS devices.
- **FCM**: Firebase Cloud Messaging — Google's platform for delivering push notifications to Android devices.
- **Expand_Contract_Pattern**: A database migration strategy where schema changes are applied in multiple backwards-compatible releases to enable zero-downtime deployments.
- **Tenant**: A customer or organisational unit in a multi-tenant SaaS system, isolated from other tenants at the namespace, RBAC, network, and data layers.
- **Tenant_Registry**: A YAML file in the repository that records tenant metadata and drives automated onboarding.
- **ESO**: External Secrets Operator — a Kubernetes operator that synchronises secrets from cloud provider vaults into Kubernetes Secrets.

---

## Requirements

### Requirement 1: Structural Conformance of New Golden Path Documents

**User Story:** As a developer, I want the new golden path documents to follow the same structure as existing paths, so that I can navigate them with the same mental model I already use.

#### Acceptance Criteria

1. THE Golden_Path_Document for `mobile-backend.md` SHALL contain all sections defined in the Structural_Template: a level-1 heading matching `# Golden Path — Mobile Backend`, a "When to use this path" section, a Prerequisites section, a Flow section, numbered steps, a Guardrails section, and a Responsibilities section.
2. THE Golden_Path_Document for `database-migrations.md` SHALL contain all sections defined in the Structural_Template: a level-1 heading matching `# Golden Path — Database Migrations`, a "When to use this path" section, a Prerequisites section, a Flow section, numbered steps, a Guardrails section, and a Responsibilities section.
3. THE Golden_Path_Document for `multi-tenant-saas.md` SHALL contain all sections defined in the Structural_Template: a level-1 heading matching `# Golden Path — Multi-Tenant SaaS`, a "When to use this path" section, a Prerequisites section, a Flow section, numbered steps, a Guardrails section, and a Responsibilities section.
4. WHEN a Golden_Path_Document includes a "When to use this path" section, THE Golden_Path_Document SHALL include a "Not the right path?" subsection with cross-links to at least two alternative golden paths.
5. WHEN a Golden_Path_Document includes a Prerequisites section, THE Golden_Path_Document SHALL reference `bash scripts/env-checker.sh` as the first action.
6. THE Guardrails section of each Golden_Path_Document SHALL be formatted as a Markdown table with at minimum a "Rule" column and an "Enforced by" column.
7. THE Responsibilities section of each Golden_Path_Document SHALL be formatted as a Markdown table listing at minimum the Developer role and the Platform team role.

---

### Requirement 2: `mobile-backend.md` — API Versioning

**User Story:** As a mobile developer, I want clear guidance on API versioning strategy, so that I can support old app versions in the wild while shipping new features.

#### Acceptance Criteria

1. THE `mobile-backend.md` Golden_Path_Document SHALL document URL path versioning (`/v1/`, `/v2/`) as the default API versioning strategy.
2. THE `mobile-backend.md` Golden_Path_Document SHALL document header-based versioning (`Accept` header with version parameter) as an alternative strategy.
3. THE `mobile-backend.md` Golden_Path_Document SHALL include an Ingress YAML snippet demonstrating path-based routing to versioned endpoints.
4. THE `mobile-backend.md` Golden_Path_Document SHALL specify that a deprecated API version MUST be supported for at least 12 months after a successor version is released.
5. THE `mobile-backend.md` Golden_Path_Document SHALL specify that deprecation is signalled via a `Deprecation` response header on sunset versions.

---

### Requirement 3: `mobile-backend.md` — OAuth 2.0 / OIDC with PKCE

**User Story:** As a mobile developer, I want guidance on implementing secure authentication for mobile clients, so that I can protect user accounts without storing long-lived credentials on the device.

#### Acceptance Criteria

1. THE `mobile-backend.md` Golden_Path_Document SHALL specify that mobile clients MUST use the OAuth 2.0 Authorization Code flow with PKCE (RFC 7636).
2. THE `mobile-backend.md` Golden_Path_Document SHALL specify that the BFF acts as the resource server and validates `Authorization: Bearer <token>` headers on every request.
3. THE `mobile-backend.md` Golden_Path_Document SHALL specify that refresh token rotation is required — a new refresh token is issued on every use and the previous token is invalidated.
4. THE `mobile-backend.md` Golden_Path_Document SHALL reference `secrets/external-secrets/` for storing the JWKS endpoint URL and client credentials.
5. THE `mobile-backend.md` Golden_Path_Document SHALL list at least three supported identity provider options (e.g., Auth0, Keycloak, AWS Cognito, Azure AD B2C) and state that the BFF is provider-agnostic.

---

### Requirement 4: `mobile-backend.md` — Push Notifications

**User Story:** As a mobile developer, I want guidance on integrating push notifications, so that I can send timely alerts to iOS and Android users.

#### Acceptance Criteria

1. THE `mobile-backend.md` Golden_Path_Document SHALL describe the push notification architecture: the BFF registers device tokens and triggers notification events to a dedicated notification service, which delivers to APNs (iOS) and FCM (Android).
2. THE `mobile-backend.md` Golden_Path_Document SHALL specify that device tokens are stored in a `device_tokens` table scoped to `user_id` and upserted on every app launch.
3. THE `mobile-backend.md` Golden_Path_Document SHALL specify that APNs and FCM keys are stored via the ESO and never in code or manifests.
4. THE `mobile-backend.md` Golden_Path_Document SHALL reference `secrets/external-secrets/` for storing APNs and FCM credentials.

---

### Requirement 5: `mobile-backend.md` — Rate Limiting

**User Story:** As a mobile developer, I want guidance on rate limiting, so that I can protect the BFF from aggressive mobile client retry behaviour.

#### Acceptance Criteria

1. THE `mobile-backend.md` Golden_Path_Document SHALL specify that rate limiting is enforced at the Ingress layer using nginx-ingress annotations.
2. THE `mobile-backend.md` Golden_Path_Document SHALL include an Ingress annotation snippet with `limit-rps`, `limit-connections`, and `limit-burst-multiplier` values.
3. THE `mobile-backend.md` Golden_Path_Document SHALL specify that per-user rate limiting (post-authentication) is enforced in the BFF middleware using a sliding window counter stored in Redis.
4. THE `mobile-backend.md` Golden_Path_Document SHALL specify that all public endpoints MUST have rate limiting applied.

---

### Requirement 6: `mobile-backend.md` — Observability and Cross-links

**User Story:** As a mobile developer, I want mobile-specific observability guidance and clear cross-links, so that I can monitor the health of my BFF and know where to find related documentation.

#### Acceptance Criteria

1. THE `mobile-backend.md` Golden_Path_Document SHALL include a table of mobile-specific Prometheus metrics to track, including at minimum: per-version request counts, auth token validation errors, push notification delivery failures, and rate limit rejections.
2. THE `mobile-backend.md` Golden_Path_Document SHALL reference `observability/prometheus/alerts/` for alert configuration.
3. THE `mobile-backend.md` Golden_Path_Document SHALL cross-link to `kubernetes-microservice.md` as the base path it extends.
4. THE `mobile-backend.md` Golden_Path_Document SHALL cross-link to `docs/guides/secrets-management.md` for APNs/FCM key storage.
5. WHEN a File_Reference appears in `mobile-backend.md`, THE Golden_Path_Document SHALL reference a file that exists in the repository.

---

### Requirement 7: `database-migrations.md` — Golden Path Promotion

**User Story:** As a developer, I want a first-class golden path for database migrations, so that I can follow a complete end-to-end workflow rather than a reference guide.

#### Acceptance Criteria

1. THE `database-migrations.md` Golden_Path_Document SHALL include a Flow section with an ASCII art or text diagram showing the full migration workflow: write → test locally → CI check → choose pattern → deploy migration → verify schema → deploy app → monitor → rollback.
2. THE `database-migrations.md` Golden_Path_Document SHALL reproduce the expand/contract pattern from `docs/guides/database-migrations.md` with a four-release timeline explanation.
3. THE `database-migrations.md` Golden_Path_Document SHALL cross-link to `docs/guides/database-migrations.md` as the underlying reference guide.
4. THE `database-migrations.md` Golden_Path_Document SHALL present the pattern decision tree (init container vs. Job vs. Helm hook) as the primary decision point with direct links to each pattern file.

---

### Requirement 8: `database-migrations.md` — CI Integration

**User Story:** As a developer, I want guidance on running migrations as a CI pipeline stage, so that schema changes are applied before the application Deployment rolls out.

#### Acceptance Criteria

1. THE `database-migrations.md` Golden_Path_Document SHALL include a GitHub Actions YAML snippet showing a migration step that applies the migration Job and waits for completion before the Deployment rollout.
2. THE `database-migrations.md` Golden_Path_Document SHALL specify that the migration step uses the same container image as the application (migration scripts are bundled in the image).
3. THE `database-migrations.md` Golden_Path_Document SHALL reference `cd/kubernetes/_patterns/db-migration-job.yaml` as the CI migration Job template.

---

### Requirement 9: `database-migrations.md` — Zero-Downtime Checklist

**User Story:** As a developer, I want a zero-downtime migration checklist, so that I can verify all safety conditions are met before running a migration in production.

#### Acceptance Criteria

1. THE `database-migrations.md` Golden_Path_Document SHALL include a checklist that a developer MUST complete before running a migration in production.
2. THE checklist SHALL include at minimum the following items: migration is backwards-compatible, migration is idempotent, rollback migration script is written and tested, `activeDeadlineSeconds` is set on the Job or init container, a database backup has been taken within the last 24 hours, and the migration has been tested on a staging environment with production-scale data volume.

---

### Requirement 10: `database-migrations.md` — Observability

**User Story:** As a developer, I want observability guidance for migration runs, so that I can detect and respond to migration failures quickly.

#### Acceptance Criteria

1. THE `database-migrations.md` Golden_Path_Document SHALL include commands for tailing migration logs in real time (for both Job and init container patterns).
2. THE `database-migrations.md` Golden_Path_Document SHALL include a Prometheus alert definition for detecting failed migration Jobs (using `kube_job_failed` metric).
3. THE `database-migrations.md` Golden_Path_Document SHALL include guidance on detecting lock contention in the database during a migration.

---

### Requirement 11: `database-migrations.md` — Backup Integration and Cross-links

**User Story:** As a developer, I want backup integration guidance and clear cross-links, so that I can protect data before running destructive migrations.

#### Acceptance Criteria

1. THE `database-migrations.md` Golden_Path_Document SHALL include steps for taking a namespace-level backup with Velero before a destructive migration.
2. THE `database-migrations.md` Golden_Path_Document SHALL reference the cloud-specific database backup Terraform files: `backup/terraform/aws-rds-backup.tf`, `backup/terraform/azure-postgres-backup.tf`, and `backup/terraform/gcp-cloudsql-backup.tf`.
3. THE `database-migrations.md` Golden_Path_Document SHALL cross-link to `kubernetes-microservice.md` Step 9 as the path that references this golden path.
4. THE `database-migrations.md` Golden_Path_Document SHALL cross-link to `multi-tenant-saas.md` as a consumer of this path for per-tenant schema management.
5. WHEN a File_Reference appears in `database-migrations.md`, THE Golden_Path_Document SHALL reference a file that exists in the repository.

---

### Requirement 12: `multi-tenant-saas.md` — Isolation Model

**User Story:** As a platform engineer, I want clear guidance on tenant isolation models, so that I can choose the right level of isolation for my SaaS product's requirements.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL document namespace-per-tenant as the default isolation model.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL document cluster-per-tenant as an escalation path for regulated industries or contractual isolation requirements.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL document shared namespace with label selectors as a low-isolation option for internal tools.
4. THE `multi-tenant-saas.md` Golden_Path_Document SHALL present the isolation model comparison as a table with at minimum Isolation, Cost, and "When to use" columns.
5. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that namespace-per-tenant scales to approximately 100 tenants per cluster before Kubernetes control plane overhead becomes significant.

---

### Requirement 13: `multi-tenant-saas.md` — Automated Tenant Onboarding

**User Story:** As a platform engineer, I want automated tenant onboarding, so that provisioning a new tenant is repeatable, auditable, and does not require manual Kubernetes operations.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that tenant onboarding is triggered by adding a tenant record to a YAML-based tenant registry in the repository.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify the required fields in a tenant registry entry: `slug`, `tier`, `region`, `db_schema`, `status`, and `notification_email`.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that onboarding automation creates: a Kubernetes namespace, RBAC roles, a NetworkPolicy deny-all default, an External Secrets store config, a per-tenant database schema, and an ArgoCD Application.
4. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that the onboarding job is idempotent — re-running it after a partial failure is safe.
5. THE `multi-tenant-saas.md` Golden_Path_Document SHALL reference `cd/gitops/argocd/application.yaml` as the ArgoCD Application template for tenant deployments.

---

### Requirement 14: `multi-tenant-saas.md` — Namespace, RBAC, and Network Isolation

**User Story:** As a platform engineer, I want guidance on namespace, RBAC, and network isolation per tenant, so that tenants cannot access each other's workloads or data.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL include kubectl commands for creating a tenant namespace and applying base RBAC roles from `cd/kubernetes/_base/rbac/`.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that a deny-all NetworkPolicy is applied to every tenant namespace by default, referencing `cd/kubernetes/_base/network-policies/default-deny.yaml`.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL reference the specific allow-list NetworkPolicy files: `allow-egress-to-database.yaml`, `allow-egress-to-dns.yaml`, and `allow-ingress-from-ingress-controller.yaml`.

---

### Requirement 15: `multi-tenant-saas.md` — Per-Tenant Secrets

**User Story:** As a platform engineer, I want guidance on per-tenant secret management, so that each tenant's credentials are isolated and cannot be accessed by other tenants.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify the secret naming convention: `tenant-<slug>-<secret-name>`.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL include an External Secret YAML snippet scoped to the tenant's namespace.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL reference `secrets/external-secrets/` for the secret store configuration.
4. THE `multi-tenant-saas.md` Golden_Path_Document SHALL cross-link to `docs/guides/secrets-management.md` for full secret management guidance.

---

### Requirement 16: `multi-tenant-saas.md` — Per-Tenant Schema and Billing

**User Story:** As a platform engineer, I want guidance on per-tenant database schemas and billing instrumentation, so that tenant data is isolated and usage can be metered accurately.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify schema-per-tenant as the default data isolation model on a shared database cluster.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL cross-link to `database-migrations.md` for schema creation and migration procedures.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that all Prometheus metrics MUST carry a `tenant` label to enable per-tenant aggregation.
4. THE `multi-tenant-saas.md` Golden_Path_Document SHALL include a Prometheus recording rule example that aggregates per-tenant API request rates using the `tenant` label.
5. THE `multi-tenant-saas.md` Golden_Path_Document SHALL reference `observability/prometheus/` for adding tenant-scoped alert rules and recording rules.
6. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that schema-per-tenant on a shared database cluster scales to approximately 1,000 tenants before connection pool exhaustion becomes a concern, and SHALL recommend PgBouncer or equivalent as a mitigation.

---

### Requirement 17: `multi-tenant-saas.md` — Tenant Offboarding

**User Story:** As a platform engineer, I want a deliberate and audited tenant offboarding procedure, so that tenant data is preserved before deletion and no accidental data loss occurs.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL include a tenant offboarding checklist with the following ordered steps: mark tenant as `status: offboarding` in the registry, export tenant data via Velero namespace backup, delete the ArgoCD Application, delete the namespace, drop the tenant schema (manual DBA step requiring explicit approval), and remove the tenant's secrets from the secrets store.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL include kubectl commands for the Velero backup step, the ArgoCD Application deletion, and the namespace deletion.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that the tenant schema drop requires explicit DBA approval and MUST NOT be automated.
4. THE `multi-tenant-saas.md` Golden_Path_Document SHALL specify that billing metrics MUST be exported before the namespace is deleted.

---

### Requirement 18: `multi-tenant-saas.md` — Guardrails and Cross-links

**User Story:** As a platform engineer, I want clear guardrails and cross-links in the multi-tenant path, so that I can enforce isolation policies and navigate to related documentation.

#### Acceptance Criteria

1. THE `multi-tenant-saas.md` Golden_Path_Document SHALL include a Guardrails table covering at minimum: namespace-per-tenant enforcement, NetworkPolicy deny-all default, `tenant` label requirement, per-tenant secrets isolation, schema-per-tenant isolation, offboarding data export gate, and billing metrics export gate.
2. THE `multi-tenant-saas.md` Golden_Path_Document SHALL reference `policy/kyverno/require-labels.yaml` as the enforcement mechanism for the `tenant` label requirement.
3. THE `multi-tenant-saas.md` Golden_Path_Document SHALL cross-link to `kubernetes-microservice.md` as the base path.
4. THE `multi-tenant-saas.md` Golden_Path_Document SHALL cross-link to `platform-onboarding.md` for cluster and namespace foundations.
5. WHEN a File_Reference appears in `multi-tenant-saas.md`, THE Golden_Path_Document SHALL reference a file that exists in the repository.

---

### Requirement 19: Repository Integration

**User Story:** As a developer browsing the golden paths, I want the new documents to be discoverable from existing paths, so that I can navigate to them naturally.

#### Acceptance Criteria

1. THE three new Golden_Path_Documents SHALL be placed at `docs/golden-paths/mobile-backend.md`, `docs/golden-paths/database-migrations.md`, and `docs/golden-paths/multi-tenant-saas.md`.
2. WHERE the repository contains `docs/golden-paths/kubernetes-microservice.md`, THE `kubernetes-microservice.md` document SHALL cross-link to `mobile-backend.md`, `database-migrations.md`, and `multi-tenant-saas.md` as specialisations or related paths.
3. THE feature implementation SHALL NOT create any new infrastructure files (Terraform modules, Kubernetes manifests, or CI workflow files) — all three golden paths reference only existing repo artefacts.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Structural Template Completeness

*For any* new golden path document in `docs/golden-paths/`, the document SHALL contain all required sections of the Structural_Template: a level-1 heading, a "When to use this path" section, a Prerequisites section, a Flow section, at least one numbered step, a Guardrails section, and a Responsibilities section.

**Validates: Requirements 1.1, 1.2, 1.3**

### Property 2: Cross-link Integrity

*For any* cross-link in a new golden path document that points to another golden path or guide, the target file SHALL exist in the repository at the referenced path.

**Validates: Requirements 1.4, 2.5, 3.6, 4.7**

### Property 3: File Reference Integrity

*For any* File_Reference in a new golden path document, the referenced file SHALL exist in the repository.

**Validates: Requirements 2.6, 3.7, 4.8**

### Property 4: No New Infrastructure Files

*For any* file created as part of this feature, the file SHALL be a Markdown document located under `docs/golden-paths/` — no Terraform, Kubernetes manifest, or CI workflow files SHALL be introduced.

**Validates: Requirement 19.3**
