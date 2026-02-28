# Pulumi CD Examples

Copy-paste-ready Pulumi infrastructure-as-code examples using **TypeScript** and a reusable GitHub Actions deploy workflow.

## Structure

```
pulumi/
├── README.md             ← this file
├── deploy.yml            ← GitHub Actions: preview on PR, up on merge
├── aws/                  ← ECS Fargate cluster + service
│   ├── index.ts
│   ├── Pulumi.yaml
│   └── Pulumi.prod.yaml
├── azure/                ← AKS cluster + container app
│   ├── index.ts
│   ├── Pulumi.yaml
│   └── Pulumi.prod.yaml
└── gcp/                  ← GKE Autopilot cluster + Cloud Run
    ├── index.ts
    ├── Pulumi.yaml
    └── Pulumi.prod.yaml
```

## Quick Start

1. **Install Pulumi CLI:** `curl -fsSL https://get.pulumi.com | sh`
2. **Pick a cloud folder** — `cd cd/pulumi/aws`
3. **Install deps:** `npm install`
4. **Configure stack:** `pulumi stack init dev && pulumi config set aws:region us-east-1`
5. **Preview:** `pulumi preview`
6. **Deploy:** `pulumi up`

## CI/CD Workflow

The `deploy.yml` workflow follows the same plan-on-PR / apply-on-merge pattern as
the Terraform pipeline:

| Event        | Action           | Manual gate? |
|-------------|-----------------|-------------|
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
