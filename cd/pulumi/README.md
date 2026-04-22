<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Pulumi CD Examples

Copy-paste-ready Pulumi infrastructure-as-code examples using **TypeScript** and a reusable GitHub Actions deploy workflow.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Structure

```
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
pulumi/
├── README.md             ← this file
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── deploy.yml            ← GitHub Actions: preview on PR, up on merge
├── aws/                  ← ECS Fargate cluster + service
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── index.ts
│   ├── Pulumi.yaml
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── Pulumi.prod.yaml
├── azure/                ← AKS cluster + container app
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── index.ts
│   ├── Pulumi.yaml
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── Pulumi.prod.yaml
└── gcp/                  ← GKE Autopilot cluster + Cloud Run
    <!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    ├── index.ts
    ├── Pulumi.yaml
    <!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    └── Pulumi.prod.yaml
```

<!-- Note 11: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Quick Start

1. **Install Pulumi CLI:** `curl -fsSL https://get.pulumi.com | sh`
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. **Pick a cloud folder** — `cd cd/pulumi/aws`
3. **Install deps:** `npm install`
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
4. **Configure stack:** `pulumi stack init dev && pulumi config set aws:region us-east-1`
5. **Preview:** `pulumi preview`
<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
6. **Deploy:** `pulumi up`

## CI/CD Workflow

<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
The `deploy.yml` workflow follows the same plan-on-PR / apply-on-merge pattern as
the Terraform pipeline:

<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Event        | Action           | Manual gate? |
|-------------|-----------------|-------------|
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Pull Request | `pulumi preview` | No — informational |
| Push to main | `pulumi up`      | Yes — requires PR approval |

## Backend State

By default these examples use **Pulumi Cloud** for state management.
To use a self-hosted backend, set `PULUMI_BACKEND_URL`:

```bash
# AWS S3
export PULUMI_BACKEND_URL=s3://my-pulumi-state

# Azure Blob
export PULUMI_BACKEND_URL=azblob://pulumi-state

# GCS
export PULUMI_BACKEND_URL=gs://my-pulumi-state
```

## Related Files

- `ci/github-actions/terraform/plan-apply.yml` — equivalent Terraform pipeline
- `terraform/` — Terraform versions of the same infrastructure
- `docs/guides/github-actions-oidc.md` — OIDC authentication setup
