# Golden Path — MLOps Workflow

> **An opinionated, end-to-end workflow for teams training, validating, and deploying ML workloads on shared platform infrastructure.**

---

## When to use this path

- You need GPU-backed infrastructure for model training or fine-tuning
- You want local notebook or experiment validation before pushing to cloud clusters
- You want Terraform, CI cost controls, Kubernetes policy, and deployment patterns wired together

Not the right path? See:
- [kubernetes-microservice.md](kubernetes-microservice.md) — general service workloads on Kubernetes
- [data-pipeline.md](data-pipeline.md) — non-GPU batch and scheduled data jobs
- [platform-onboarding.md](platform-onboarding.md) — team and platform setup

---

## Prerequisites

Run the environment checker before anything else:

```bash
bash scripts/env-checker.sh
```

For local GPU work, you also need a machine with NVIDIA drivers and Docker GPU pass-through enabled. Use the GPU-specific devcontainer in [.devcontainer/gpu/devcontainer.json](../../.devcontainer/gpu/devcontainer.json).

---

## Flow

```text
local GPU devcontainer -> experiment + fine-tune -> CI checks + Infracost
                      -> Terraform GPU cluster plan -> cluster apply
                      -> image push -> Kubernetes rollout -> metrics + alerts
```

---

## Step 1 — Start the local GPU workspace

Open the repo with the GPU devcontainer:

- Config: [.devcontainer/gpu/devcontainer.json](../../.devcontainer/gpu/devcontainer.json)
- Setup script: [.devcontainer/gpu/post-create.sh](../../.devcontainer/gpu/post-create.sh)
- Usage notes: [.devcontainer/gpu/README.md](../../.devcontainer/gpu/README.md)

Validate GPU visibility before installing framework-specific wheels:

```bash
nvidia-smi
python3 -m jupyter lab --ip=0.0.0.0 --no-browser --NotebookApp.token=''
```

---

## Step 2 — Choose the cloud GPU cluster pattern

Use one of the Kubernetes Terraform modules and enable the optional GPU pool.

### AWS EKS

Files:
- [terraform/aws-eks/main.tf](../../terraform/aws-eks/main.tf)
- [terraform/aws-eks/variables.tf](../../terraform/aws-eks/variables.tf)

Minimum GPU settings:

```hcl
gpu_node_group_enabled = true
gpu_instance_types     = ["g5.xlarge"]
gpu_desired_count      = 1
gpu_min_count          = 0
gpu_max_count          = 3
```

The module provisions a dedicated managed node group with GPU labels and an optional `nvidia.com/gpu=dedicated:NoSchedule` taint so only explicit ML workloads land on it.

### Azure AKS

Files:
- [terraform/azure-aks/main.tf](../../terraform/azure-aks/main.tf)
- [terraform/azure-aks/variables.tf](../../terraform/azure-aks/variables.tf)

Minimum GPU settings:

```hcl
gpu_node_pool_enabled  = true
gpu_node_vm_size       = "Standard_NC4as_T4_v3"
gpu_node_min_count     = 0
gpu_node_max_count     = 3
gpu_enable_autoscaling = true
```

The module provisions a separate AKS user pool for GPU workloads so the default system pool remains isolated for core cluster services.

---

## Step 3 — Put infrastructure cost controls in the PR path

Use the Terraform workflow with Infracost before apply:

- Workflow: [ci/github-actions/terraform/plan-apply.yml](../../ci/github-actions/terraform/plan-apply.yml)

This workflow:
- Generates a Terraform plan on pull requests
- Posts an Infracost diff comment to the PR
- Fails the pipeline when monthly cost growth is greater than `$500`

This is the minimum control you want before approving new GPU capacity.

---

## Step 4 — Build the ML image

Start from the Python container templates:

- [docker/python/Dockerfile.fastapi](../../docker/python/Dockerfile.fastapi)
- [docker/python/Dockerfile.flask](../../docker/python/Dockerfile.flask)
- [docker/_base/Dockerfile.multistage](../../docker/_base/Dockerfile.multistage)

Use a training image for fine-tuning or scheduled jobs, and a separate inference image for serving if your runtime footprint is materially smaller.

---

## Step 5 — Add CI for training or inference code

Start with the Python CI template:

- [ci/github-actions/python/build-test.yml](../../ci/github-actions/python/build-test.yml)
- [ci/github-actions/python/security-scan.yml](../../ci/github-actions/python/security-scan.yml)

Add unit tests for data transforms, model packaging, and inference smoke tests. Keep long-running training out of the default PR workflow unless you gate it behind a manual or nightly trigger.

---

## Step 6 — Package the Kubernetes workload

Use the standard base manifests and adapt them for ML jobs or inference services:

- [cd/kubernetes/_base/deployment.yaml](../../cd/kubernetes/_base/deployment.yaml)
- [cd/kubernetes/_base/hpa.yaml](../../cd/kubernetes/_base/hpa.yaml)
- [cd/kubernetes/_base/configmap.yaml](../../cd/kubernetes/_base/configmap.yaml)
- [cd/kubernetes/_patterns/init-containers.yaml](../../cd/kubernetes/_patterns/init-containers.yaml)
- [cd/kubernetes/_patterns/db-migration-job.yaml](../../cd/kubernetes/_patterns/db-migration-job.yaml)

For GPU workloads:
- target the GPU node pool using the labels exposed by the Terraform module
- tolerate the optional GPU taint if you keep taint isolation enabled
- keep system services off the GPU pool

---

## Step 7 — Protect metadata and admission policy

Keep cost and environment metadata present from infra through workloads:

- Terraform FinOps tags: [terraform/aws-eks/variables.tf](../../terraform/aws-eks/variables.tf) and [terraform/azure-aks/variables.tf](../../terraform/azure-aks/variables.tf)
- Kyverno enforcement: [policy/kyverno/enforce-finops-labels.yaml](../../policy/kyverno/enforce-finops-labels.yaml)

Namespaces and Pods must include:
- `finops.org/costcenter`
- `finops.org/environment`

This keeps GPU workloads attributable to a team, environment, and budget owner.

---

## Step 8 — Deploy via GitOps

Register the workload with ArgoCD:

- [cd/gitops/argocd/application.yaml](../../cd/gitops/argocd/application.yaml)
- [cd/gitops/argocd/applicationset.yaml](../../cd/gitops/argocd/applicationset.yaml)

Promotion should remain a PR-driven image or values change, not a manual kubectl apply from a workstation.

---

## Step 9 — Observe training and inference

Use the existing observability stack for model-serving and training control-plane visibility:

- [observability/prometheus/](../../observability/prometheus/)
- [observability/opentelemetry/](../../observability/opentelemetry/)
- [notifications/slack-notify.yml](../../notifications/slack-notify.yml)

Track at least:
- GPU node utilization
- pod restarts and OOMs
- queue lag for batch fine-tuning jobs
- latency and error rate for inference endpoints

---

## Step 10 — Scale non-production clusters down when idle

If your dev cluster is mostly used for daytime experimentation, use the scale scheduler pattern:

- [cd/kubernetes/_patterns/dev-scale-to-zero.yaml](../../cd/kubernetes/_patterns/dev-scale-to-zero.yaml)

This helps avoid burning GPU budget overnight in lower environments.

---

## Exit criteria

You are done when:
- local GPU experiments run successfully in the dedicated devcontainer
- Terraform PRs show cost deltas before approval
- the cluster has a dedicated GPU pool with autoscaling enabled
- workloads carry FinOps labels and deploy cleanly through policy enforcement
- GitOps owns rollout into the target environment
