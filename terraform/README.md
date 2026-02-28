# 🏗️ Terraform — Infrastructure Provisioning

> **Self-contained Terraform configurations for provisioning the cloud infrastructure your CI/CD pipelines deploy to.**
>
> Each folder is a standalone root module — just `cd` in, set your variables, and `terraform apply`.

---

## How to Use

1. Pick the target that matches your deployment platform
2. Copy the folder into your infrastructure repo
3. Update `variables.tf` defaults or create a `terraform.tfvars` file
4. Run:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Structure

```
terraform/
├── azure-aks/              # AKS cluster + VNet + ACR + IAM
├── aws-eks/                # EKS cluster + VPC + ECR + IAM roles
├── gcp-gke/                # GKE cluster + VPC + Artifact Registry + IAM
├── azure-app-service/      # App Service PlanApp + Staging Slot
├── aws-ecs/                # ECS Fargate cluster + ALB + ECR
└── aws-lambda/             # Lambda function + API Gateway + IAM
```

---

## Conventions

- **State:** Remote state is not configured — add your own `backend` block (S3, Azure Blob, GCS)
- **Naming:** All resources use a `project`/`environment` prefix for easy identification
- **Tags:** Every resource is tagged with `Project`, `Environment`, and `ManagedBy = "terraform"`
- **Versions:** Provider versions are pinned in `required_providers`
- **Secrets:** No secrets are hardcoded — use `terraform.tfvars` (gitignored) or environment variables
- **Markers:** Lines that must be customised are marked with `# <-- CHANGE THIS`

---

## Which Target Do I Need?

| I want to deploy to... | Use this |
|---|---|
| Azure Kubernetes Service (AKS) | `azure-aks/` |
| Amazon Elastic Kubernetes Service (EKS) | `aws-eks/` |
| Google Kubernetes Engine (GKE) | `gcp-gke/` |
| Azure App Service (no K8s) | `azure-app-service/` |
| AWS ECS Fargate (no K8s) | `aws-ecs/` |
| AWS Lambda (serverless) | `aws-lambda/` |

---

## Best Practices

1. **Never store state locally in production** — configure a remote backend with state locking
2. **Use `terraform plan` before every `apply`** — review what will change
3. **Pin provider versions** — avoid surprise breaking changes
4. **Separate environments** using workspaces or separate state files, not branches
5. **Use variables for everything** that changes between environments
6. **Tag all resources** — you'll thank yourself when the bill arrives

---

## Related

- **Deploy pipelines:** [`cd/targets/`](../cd/targets/) — CI/CD workflows that deploy *to* this infrastructure
- **Kubernetes manifests:** [`cd/kubernetes/`](../cd/kubernetes/) — what runs *on* the clusters provisioned here
- **Helm charts:** [`cd/helm/`](../cd/helm/) — packaged applications for Kubernetes
- **Secrets management guide:** [`docs/guides/secrets-management.md`](../docs/guides/secrets-management.md)
