# Golden Path — Mobile Backend

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are building a Backend for Frontend (BFF) that serves mobile apps (iOS and/or Android)
- Deployment target is Kubernetes (EKS, AKS, GKE, or local kind)
- You need API versioning to support old app versions still in the wild
- You need OAuth 2.0 / OIDC authentication with PKCE for mobile clients
- You need push notifications via APNs (iOS) and FCM (Android)
- You need rate limiting to protect against aggressive mobile client retry behaviour

Not the right path? See:
- [Kubernetes Microservice](kubernetes-microservice.md) — standard backend microservice without mobile-specific concerns
- [Serverless App](serverless-app.md) — lightweight BFF on Lambda / Cloud Run

---

## Prerequisites

Run the environment checker before anything else:

```bash
bash scripts/env-checker.sh
```

Required tools:

| Tool | Version | Purpose |
|------|---------|---------|
| Git | 2.40+ | Source control |
| Docker Desktop | 4.x | Local container builds |
| kubectl | 1.29+ | Kubernetes CLI |
| kind | 0.24+ | Local Kubernetes cluster |
| Helm | 3.14+ | Kubernetes package manager |
| pre-commit | 3.x | Git hook runner |

Full list with install links: [docs/guides/onboarding.md](../guides/onboarding.md)

---

## Flow

```
local dev → pre-commit → CI (build + test + scan) → Docker image
         → Kubernetes deploy → API versioning → OAuth/OIDC
         → push notifications → rate limiting → observability → alerts
```

---

## Step 1 — Start local environment

```bash
# Create a kind cluster, local registry, and ingress-nginx
bash local-dev/kind/setup.sh
```

This script:
1. Creates a kind cluster named `devops-playbook`
2. Starts a local container registry at `localhost:5001`
3. Installs ingress-nginx
4. Creates a `dev` namespace and applies the dev Kustomize overlay

Config: [`local-dev/kind/kind-config.yaml`](../../local-dev/kind/kind-config.yaml)
Script: [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh)

To tear down:

```bash
bash local-dev/kind/teardown.sh
```

To run your BFF with its dependencies (DB, Redis, mock notification service) locally:

```bash
docker compose -f compose/microservices-example/docker-compose.yml up
```

---

## Step 2 — Install pre-commit hooks

```bash
make hooks
```

Hooks run on every `git commit` and `git push`. What they check:

| Hook | Tool | Catches |
|------|------|---------|
| Secret scan | Gitleaks | Credentials committed to Git |
| IaC format | terraform fmt | Malformatted Terraform |

Config: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml)
Full details: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 3 — Set up the CI pipeline

Copy the workflow file for your stack into `.github/workflows/`:

| Stack | File |
|-------|------|
| Python | [`ci/github-actions/python/build-test.yml`](../../ci/github-actions/python/build-test.yml) |
| Go | [`ci/github-actions/go/build-test.yml`](../../ci/github-actions/go/build-test.yml) |
| .NET | [`ci/github-actions/dotnet/build-test.yml`](../../ci/github-actions/dotnet/build-test.yml) |
| Java | [`ci/github-actions/java/build-test.yml`](../../ci/github-actions/java/build-test.yml) |

The pipeline runs: dependency install → build → unit tests → coverage → lint.

Add the security scan step by referencing the shared workflow:

```yaml
# .github/workflows/build.yml  (add after build-test)
uses: ./.github/workflows/reusable-security-scan.yml
```

Source: [`ci/github-actions/_shared/reusable-security-scan.yml`](../../ci/github-actions/_shared/reusable-security-scan.yml)

Security scans — wire these three into CI. They run in parallel after the build step:

| What | File | Blocks merge? |
|------|------|---------------|
| Secrets in image | [`ci-security/secret-detection/gitleaks.yml`](../../ci-security/secret-detection/gitleaks.yml) | Yes |
| Container vulnerabilities | [`ci-security/container-scanning/trivy-scan.yml`](../../ci-security/container-scanning/trivy-scan.yml) | Yes (HIGH/CRITICAL) |
| Source code (SAST) | [`ci-security/sast/semgrep.yml`](../../ci-security/sast/semgrep.yml) | Yes |
| Dependency audit | [`ci-security/dependency-audit/`](../../ci-security/dependency-audit/) | Advisory |

---

## Step 4 — Build and push the Docker image

Use the reusable build workflow — it enforces multi-stage build, non-root user, and SHA-pinned tags:

```yaml
uses: ./.github/workflows/reusable-docker-build.yml
with:
  image-name: mobile-bff
  dockerfile: docker/<stack>/Dockerfile
```

Source: [`ci/github-actions/_shared/reusable-docker-build.yml`](../../ci/github-actions/_shared/reusable-docker-build.yml)

> **Rule:** Never push or deploy with the `latest` tag. The pipeline tags images with the Git SHA. The Kyverno policy [`policy/kyverno/disallow-latest-tag.yaml`](../../policy/kyverno/disallow-latest-tag.yaml) will block deployments that violate this.

---

## Step 5 — API versioning

Mobile clients cannot be force-updated — old app versions live in the wild for months. API versioning is **required** for all mobile BFFs.

### Versioning strategy

| Strategy | When to use | Implementation |
|----------|-------------|----------------|
| URL path versioning (`/v1/`, `/v2/`) | **Default** — simple, cache-friendly, easy to route | Ingress path rewrite rules |
| Header versioning (`Accept: application/vnd.api+json;version=2`) | When URL stability matters more than simplicity | Middleware in the BFF |

URL path versioning is the default. The Ingress routes `/v1/*` and `/v2/*` to the same BFF Deployment; the BFF reads the version prefix from the path and adapts the response.

### Ingress configuration

```yaml
# Ingress snippet — route /v1/* and /v2/* to the mobile-bff Service
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mobile-bff
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - http:
        paths:
          - path: /v1/
            pathType: Prefix
            backend:
              service:
                name: mobile-bff
                port:
                  number: 8080
          - path: /v2/
            pathType: Prefix
            backend:
              service:
                name: mobile-bff
                port:
                  number: 8080
```

Base manifest to adapt: [`cd/kubernetes/_base/ingress.yaml`](../../cd/kubernetes/_base/ingress.yaml)

### Deprecation policy

- A deprecated API version **MUST** be supported for at least **12 months** after a successor version is released.
- Deprecation is signalled by including a `Deprecation` response header on every response from a sunset version:

```
Deprecation: true
Sunset: Sat, 01 Jan 2026 00:00:00 GMT
Link: <https://api.example.com/v2/>; rel="successor-version"
```

- Implement the `Deprecation` header in BFF middleware — do not rely on manual per-handler additions.

---

## Step 6 — OAuth 2.0 / OIDC with PKCE

Mobile clients use the **Authorization Code flow with PKCE** (RFC 7636). PKCE is mandatory — it protects against authorization code interception attacks on mobile devices where a confidential client secret cannot be safely stored.

### How it works

1. Mobile app generates a `code_verifier` (random string) and a `code_challenge` (SHA-256 hash of the verifier).
2. App redirects to the identity provider's authorization endpoint with `code_challenge` and `code_challenge_method=S256`.
3. Identity provider returns an authorization code.
4. App exchanges the code + `code_verifier` for tokens at the token endpoint.
5. BFF validates the `Authorization: Bearer <token>` header on every request using the identity provider's JWKS endpoint.

### BFF responsibilities

- The BFF acts as the **resource server** — it validates JWTs on every inbound request.
- Validate the `Authorization: Bearer <token>` header using the JWKS endpoint (never hardcode public keys).
- Return `401 Unauthorized` with a `WWW-Authenticate` header on validation failure.
- **Refresh token rotation:** issue a new refresh token on every use and invalidate the previous token. This prevents token replay attacks.

### Storing credentials

Store the JWKS endpoint URL and client credentials in the secrets store — never in code or manifests:

| Cloud | Store config |
|-------|-------------|
| AWS | [`secrets/external-secrets/aws-secret-store.yaml`](../../secrets/external-secrets/aws-secret-store.yaml) |
| Azure | [`secrets/external-secrets/azure-secret-store.yaml`](../../secrets/external-secrets/azure-secret-store.yaml) |
| GCP | [`secrets/external-secrets/gcp-secret-store.yaml`](../../secrets/external-secrets/gcp-secret-store.yaml) |

Reference: [`secrets/external-secrets/example-external-secret.yaml`](../../secrets/external-secrets/example-external-secret.yaml)
Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

### Supported identity providers

The BFF is provider-agnostic — it only needs the JWKS endpoint URL. Supported providers:

| Provider | Notes |
|----------|-------|
| Auth0 | Managed IdP, easy PKCE setup |
| Keycloak | Self-hosted, full control |
| AWS Cognito | Native AWS integration |
| Azure AD B2C | Native Azure integration, supports custom policies |

For CI/CD OIDC (not end-user auth): [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md)

---

## Step 7 — Push notifications

Push notifications are sent via a dedicated **notification microservice** — not the BFF itself. The BFF registers device tokens and triggers notification events.

### Architecture

```
Mobile app → BFF (register device token)
           → ExternalSecret (APNs key / FCM key)
           → Notification service → APNs (iOS)
                                  → FCM (Android)
```

### Device token storage

Store device tokens in a `device_tokens` table in the BFF's database:

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key — scopes token to a user |
| `platform` | enum | `ios` or `android` |
| `token` | text | APNs device token or FCM registration token |
| `updated_at` | timestamp | Updated on every app launch |

**Rule:** Upsert the device token on every app launch — tokens rotate and must be kept current.

### Storing APNs and FCM keys

APNs and FCM keys **MUST** be stored via the External Secrets Operator — never in code or manifests:

```yaml
# Adapt secrets/external-secrets/example-external-secret.yaml for notification keys
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: notification-keys
  namespace: mobile-bff
spec:
  secretStoreRef:
    name: aws-secret-store   # or azure-secret-store / gcp-secret-store
    kind: SecretStore
  target:
    name: notification-keys
  data:
    - secretKey: APNS_KEY
      remoteRef:
        key: /mobile-bff/notifications
        property: apns_key
    - secretKey: FCM_SERVER_KEY
      remoteRef:
        key: /mobile-bff/notifications
        property: fcm_server_key
```

Reference: [`secrets/external-secrets/`](../../secrets/external-secrets/)
Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 8 — Rate limiting

Mobile clients retry aggressively. Rate limiting is **required** on all public endpoints.

### Ingress-layer rate limiting (IP-based)

Apply nginx-ingress annotations to the BFF Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mobile-bff
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "20"
    nginx.ingress.kubernetes.io/limit-connections: "10"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
```

These limits apply per source IP before authentication.

### Per-user rate limiting (post-authentication)

After the BFF validates the JWT, enforce per-user rate limits in BFF middleware using a **Redis sliding window counter**:

- Key: `rate_limit:<user_id>:<endpoint>`
- Window: 60 seconds
- Limit: configurable per endpoint tier (e.g., 100 req/min for free tier, 1000 req/min for pro tier)
- Response on limit exceeded: `429 Too Many Requests` with `Retry-After` header

> **Rule:** All public endpoints MUST have rate limiting applied at the Ingress layer. Authenticated endpoints MUST additionally have per-user rate limiting in BFF middleware.

---

## Step 9 — Observability

### Mobile-specific metrics

Track these metrics in addition to the standard Prometheus metrics:

| Metric | Description | Alert threshold |
|--------|-------------|----------------|
| `http_requests_total{version="v1"}` | Request count per API version | Alert when v1 traffic drops to 0 (all clients migrated — safe to sunset) |
| `http_requests_total{version="v2"}` | Request count per API version | Alert on unexpected drop (client regression) |
| `auth_token_validation_errors_total` | JWT validation failures | Alert on spike (potential credential stuffing attack) |
| `push_notification_delivery_failures_total` | Failed APNs/FCM deliveries | Alert when failure rate > 5% |
| `rate_limit_rejections_total` | Requests rejected by rate limiter | Alert on sustained spike (client misbehaviour or DDoS) |

Add alert rules to: [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/)

### Notifications

Wire alert routing to your team channel:

```
notifications/slack-notify.yml
notifications/pagerduty-notify.yml
```

### Error responses

| Scenario | HTTP status | Response |
|----------|-------------|---------|
| JWT validation failure | `401 Unauthorized` | `WWW-Authenticate` header |
| Refresh token expired | `401 Unauthorized` | `error: token_expired` |
| Rate limit exceeded | `429 Too Many Requests` | `Retry-After` header |
| Push notification failure | — | Logged, retried 3× with exponential backoff |
| Deprecated API version called | `200 OK` | `Deprecation` header added |

---

## Guardrails

| Rule | Enforced by |
|------|-------------|
| PKCE required on all OAuth flows | Code review + integration test |
| Refresh token rotation enabled | Identity provider configuration |
| `Deprecation` header on all sunset API versions | BFF middleware (not per-handler) |
| Rate limiting on all public endpoints | Ingress annotations (verified in CI) |
| Device tokens encrypted at rest | Database encryption + External Secrets Operator |
| No `latest` image tags | [`policy/kyverno/disallow-latest-tag.yaml`](../../policy/kyverno/disallow-latest-tag.yaml) |
| APNs/FCM keys never in code or manifests | External Secrets Operator + code review |
| JWT public keys from JWKS endpoint only | Code review + integration test |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Steps 1–5, BFF implementation, API versioning middleware, JWT validation, device token storage, rate limiting middleware |
| Platform team | Kubernetes cluster, Ingress configuration, External Secrets Operator setup, Redis provisioning, Prometheus alert rules |
| Security team | OAuth/OIDC provider configuration, PKCE enforcement review, APNs/FCM key rotation policy |

---

## Related paths and guides

- [Kubernetes Microservice](kubernetes-microservice.md) — base path this extends; covers cluster provisioning, GitOps, and standard observability
- [Serverless App](serverless-app.md) — alternative for lightweight BFFs that do not need Kubernetes
- [docs/guides/secrets-management.md](../guides/secrets-management.md) — storing APNs/FCM keys and JWKS credentials
- [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md) — OIDC for CI/CD pipelines
