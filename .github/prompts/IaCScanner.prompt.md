---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'runCommands', 'search']
description: 'Generate IaC security scanning workflows for Checkov and tfsec that integrate with existing CI pipelines in this repo.'
---

# IaC Security Scanner Generator

You are a senior DevSecOps engineer. Your task is to generate infrastructure-as-code security scanning workflows for this repository.

## Context

Scan the repository first:
- Identify all Terraform directories under `terraform/`
- Identify any Pulumi projects under `cd/pulumi/`
- Review existing CI patterns in `ci/github-actions/` to match style exactly
- Review `.github/workflows/` for any existing security workflows
- Read `security/README.md` to understand the existing security structure

## Your deliverables

### 1. `security/iac-scanning/checkov.yml`

A GitHub Actions workflow that:
- Triggers on push to main, pull_request to main, and weekly schedule (Monday 08:00 UTC)
- Uses `bridgecrewio/checkov-action@master`
- Scans all directories: `terraform/`, `cd/kubernetes/`, `cd/helm/`, `compose/`, `docker/`
- Output format: `sarif`
- Uploads results to GitHub Security tab via `github/codeql-action/upload-sarif`
- Soft-fails on findings (exit code 0) so pipeline does not block — findings are advisory only
- Includes a `# <-- CHANGE THIS` comment on the `soft-fail` setting so teams can harden it
- Follows the exact file header standard from `README.md` (TEMPLATE, WHEN TO USE, PREREQUISITES, etc.)
- Uses `MATURITY: Stable` badge

### 2. `security/iac-scanning/tfsec.yml`

A GitHub Actions workflow that:
- Triggers on push/PR only when files under `terraform/**` change (use `paths:` filter)
- Uses `aquasecurity/tfsec-action@v1.0.0`
- Runs against each Terraform subdirectory: `azure-aks`, `aws-eks`, `gcp-gke`, `aws-ecs`, `aws-lambda`, `azure-app-service`
- Uses a matrix strategy so each directory is scanned in parallel
- Output format: `sarif`, uploaded to GitHub Security tab
- Includes the standard file header
- Adds inline comments explaining what tfsec checks that Checkov does not (e.g. cloud-provider-specific misconfigurations)

### 3. `security/iac-scanning/README.md`

A short markdown file explaining:
- The difference between Checkov and tfsec and when to use each
- How to interpret SARIF results in the GitHub Security tab
- How to suppress a finding with inline `#checkov:skip` or `#tfsec:ignore` comments
- A table showing which tool covers which directory type

### 4. Update `security/README.md`

Add `iac-scanning/` to the existing categories table. Do not change anything else.

## Style rules

- Match the comment density and style of existing files in `ci/github-actions/`
- Every non-obvious YAML key must have a brief inline comment explaining why it exists
- Use `# <-- CHANGE THIS` markers on every value a team would customise
- Pin all action versions to explicit tags, never `@latest`
- Follow the maturity badge convention: Stable / Beta / Experimental