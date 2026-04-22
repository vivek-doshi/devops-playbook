<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# 🏗️ Terraform — Infrastructure Provisioning

> **Self-contained Terraform configurations for provisioning the cloud infrastructure your CI/CD pipelines deploy to.**
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
>
> Each folder is a standalone root module — just `cd` in, set your variables, and `terraform apply`.

<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## How to Use

<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
1. Pick the target that matches your deployment platform
2. Copy the folder into your infrastructure repo
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
3. Update `variables.tf` defaults or create a `terraform.tfvars` file
4. Run:

<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
terraform init
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
terraform plan -out=tfplan
terraform apply tfplan
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

---

<!-- Note 9: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Structure

```
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
terraform/
├── azure-aks/              # AKS cluster + VNet + ACR + IAM
<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── aws-eks/                # EKS cluster + VPC + ECR + IAM roles
├── gcp-gke/                # GKE cluster + VPC + Artifact Registry + IAM
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── azure-app-service/      # App Service PlanApp + Staging Slot
├── aws-ecs/                # ECS Fargate cluster + ALB + ECR
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── aws-lambda/             # Lambda function + API Gateway + IAM
```

<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Conventions

<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **State:** Remote state is not configured — add your own `backend` block (S3, Azure Blob, GCS)
- **Naming:** All resources use a `project`/`environment` prefix for easy identification
<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Tags:** Every resource is tagged with `Project`, `Environment`, and `ManagedBy = "terraform"`
- **Versions:** Provider versions are pinned in `required_providers`
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Secrets:** No secrets are hardcoded — use `terraform.tfvars` (gitignored) or environment variables
- **Markers:** Lines that must be customised are marked with `# <-- CHANGE THIS`

<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Which Target Do I Need?

<!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| I want to deploy to... | Use this |
|---|---|
<!-- Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
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
