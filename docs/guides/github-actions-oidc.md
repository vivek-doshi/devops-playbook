# GitHub Actions OIDC Guide (Azure, AWS, GCP)

Use OpenID Connect (OIDC) to remove long-lived cloud credentials from GitHub Actions.

## Why This Matters

Compared to static credentials, OIDC gives:
- Short-lived tokens per workflow run.
- Better auditability tied to repo, ref, and workflow claims.
- Lower rotation burden and smaller blast radius.

## Common Workflow Requirement

Every deploy job using OIDC must include:

```yaml
permissions:
  id-token: write
  contents: read
```

## Azure Setup (Workload Identity Federation)

1. Create app registration and service principal.
2. Add federated credential scoped to repo/ref or environment.
3. Grant least-privilege role assignments at required scope.
4. Store only non-secret identifiers in GitHub secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

Workflow auth action:

```yaml
- name: Azure Login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## AWS Setup (IAM OIDC Provider + Role)

1. Create IAM OIDC provider for `https://token.actions.githubusercontent.com`.
2. Create IAM role with trust policy constrained by `sub` and `aud` claims.
3. Assign least-privilege policies for deployment scope.
4. Store role ARN as `AWS_DEPLOY_ROLE_ARN`.

Workflow auth action:

```yaml
- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
    aws-region: us-east-1
```

## GCP Setup (Workload Identity Federation)

1. Create Workload Identity Pool and OIDC provider.
2. Map required token attributes and set restrictive conditions.
3. Create service account and grant least-privilege roles.
4. Bind pool principals to service account with `roles/iam.workloadIdentityUser`.
5. Store:
   - `GCP_WORKLOAD_IDENTITY_PROVIDER`
   - `GCP_SERVICE_ACCOUNT`

Workflow auth action:

```yaml
- name: Authenticate to Google Cloud (OIDC)
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
```

## Trust Policy Recommendations

1. Restrict by repository and branch/environment claims.
2. Use separate identities per environment (dev/staging/prod).
3. Use least privilege for each role/service account.
4. Add environment approvals for production deploy jobs.
5. Pin action versions (and SHAs for high-security contexts).

## Troubleshooting Quick Checks

- Token or subject mismatch: verify claim filters and workflow trigger context.
- Authorization errors: verify role assignment/policy scope.
- Wrong tenant/account/project: verify secret values and cloud context.

## Repository References

- GitHub Actions templates: `ci/github-actions/`
- Cloud deployment targets: `cd/targets/`
- Secret lifecycle guidance: `secrets/guides/secret-lifecycle.md`
- Secrets strategy: `docs/guides/secrets-management.md`
