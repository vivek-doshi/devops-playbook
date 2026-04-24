# IaC Scanning

Use Checkov when you want broad infrastructure coverage across multiple file types in one workflow. Use tfsec when you want deeper Terraform-specific feedback, especially cloud-provider checks around IAM, networking, encryption, and managed-service defaults that benefit from Terraform-aware rules.

Both workflows emit SARIF and upload to the GitHub Security tab. In GitHub, open Security > Code scanning alerts, then filter by tool to separate Checkov's broad repository findings from tfsec's Terraform-module findings. Severity, rule ID, and the exact file path in the alert are the fields teams usually triage first.

Suppressions are inline and should be used sparingly with a justification comment nearby. Checkov supports comments such as `#checkov:skip=CKV_AWS_20: public bucket required for static website hosting`, and tfsec supports comments such as `#tfsec:ignore:aws-s3-enable-bucket-encryption public website bucket exception`.

| Directory type | Example paths | Checkov | tfsec |
|---|---|---|---|
| Terraform modules | `terraform/aws-eks/`, `terraform/azure-aks/` | Yes | Yes |
| Kubernetes manifests | `cd/kubernetes/` | Yes | No |
| Helm charts | `cd/helm/` | Yes | No |
| Docker Compose | `compose/` | Yes | No |
| Dockerfiles | `docker/` | Yes | No |
| Pulumi projects | `cd/pulumi/` | Not in this workflow by default | No |

Use both workflows together when your repository mixes Terraform with other IaC formats. If your team only maintains Terraform, tfsec is the narrower default and Checkov becomes the broader second layer.
