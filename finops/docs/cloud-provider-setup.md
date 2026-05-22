# Cloud Provider Setup for FinOps Cost Monitoring

This document provides comprehensive instructions for configuring AWS, Azure, and GCP to integrate with Kubecost or OpenCost for accurate cloud cost monitoring and allocation.

## Overview

To enable accurate cost monitoring, Kubecost and OpenCost require access to cloud provider billing APIs. This access is granted through IAM roles (AWS), service principals (Azure), or service accounts (GCP) with specific permissions to read billing and cost data.

### Prerequisites

- Administrative access to your cloud provider account
- Kubernetes cluster deployed on the target cloud provider
- Kubecost or OpenCost installed in the `finops` namespace (see installation guide)

---

## AWS Configuration

### Architecture

Kubecost/OpenCost running in EKS uses IAM Roles for Service Accounts (IRSA) to access AWS Cost and Usage Reports (CUR) and AWS Cost Explorer API.

### Step 1: Enable AWS Cost and Usage Reports (CUR)

1. **Navigate to AWS Cost and Usage Reports**:
   - Open the AWS Console and go to **Billing and Cost Management** > **Cost & Usage Reports**

2. **Create a new report**:
   - Report name: `kubecost-cur`
   - Time granularity: **Hourly**
   - Enable **Resource IDs** (required for accurate pod-level cost allocation)
   - Enable **Split cost allocation data** (optional, for ECS/Fargate)
   - Report data integration: **Amazon Athena**

3. **Configure S3 bucket**:
   - Create or select an S3 bucket: `s3://your-company-cur-reports`
   - Report path prefix: `kubecost/`
   - Enable **versioning** on the S3 bucket

4. **Wait for first report**:
   - CUR reports are generated within 24 hours of creation
   - Reports are updated multiple times per day

### Step 2: Create IAM Policy for Cost Access

Create an IAM policy that grants read access to CUR data and Cost Explorer API:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CostExplorerAccess",
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostAndUsageWithResources",
        "ce:GetCostForecast",
        "ce:GetDimensionValues",
        "ce:GetReservationUtilization",
        "ce:GetSavingsPlansUtilization",
        "ce:GetTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CURBucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-company-cur-reports",
        "arn:aws:s3:::your-company-cur-reports/*"
      ]
    },
    {
      "Sid": "AthenaQueryAccess",
      "Effect": "Allow",
      "Action": [
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StartQueryExecution"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GlueAccess",
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetPartitions"
      ],
      "Resource": [
        "arn:aws:glue:*:*:catalog",
        "arn:aws:glue:*:*:database/athenacurcfn_kubecost_cur",
        "arn:aws:glue:*:*:table/athenacurcfn_kubecost_cur/*"
      ]
    },
    {
      "Sid": "EC2PricingAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:DescribeRegions",
        "pricing:GetProducts"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKSAccess",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
```

**Save this policy as**: `KubecostCostAccess`

### Step 3: Create IAM Role for Service Account (IRSA)

1. **Get your EKS cluster's OIDC provider**:
   ```bash
   aws eks describe-cluster --name your-cluster-name --query "cluster.identity.oidc.issuer" --output text
   # Output: https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE
   ```

2. **Create IAM role with trust policy**:
   
   Create a file `trust-policy.json`:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC_ID"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:sub": "system:serviceaccount:finops:kubecost-cost-analyzer",
             "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:aud": "sts.amazonaws.com"
           }
         }
       }
     ]
   }
   ```

   Replace:
   - `YOUR_ACCOUNT_ID` with your AWS account ID
   - `REGION` with your EKS cluster region
   - `OIDC_ID` with your OIDC provider ID
   - `kubecost-cost-analyzer` with your service account name (use `opencost` for OpenCost)

3. **Create the IAM role**:
   ```bash
   aws iam create-role \
     --role-name KubecostCostAnalyzerRole \
     --assume-role-policy-document file://trust-policy.json
   ```

4. **Attach the policy to the role**:
   ```bash
   aws iam attach-role-policy \
     --role-name KubecostCostAnalyzerRole \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/KubecostCostAccess
   ```

### Step 4: Annotate Kubernetes Service Account

Annotate the Kubecost/OpenCost service account with the IAM role ARN:

```bash
kubectl annotate serviceaccount -n finops kubecost-cost-analyzer \
  eks.amazonaws.com/role-arn=arn:aws:iam::YOUR_ACCOUNT_ID:role/KubecostCostAnalyzerRole
```

### Step 5: Configure Kubecost/OpenCost Helm Values

Add the following to your Helm values file (`finops/helm/kubecost-values.yaml` or `finops/helm/opencost-values.yaml`):

**For Kubecost**:
```yaml
kubecostProductConfigs:
  awsServiceKeyName: ""  # Leave empty when using IRSA
  awsServiceKeyPassword: ""  # Leave empty when using IRSA
  athenaProjectID: "YOUR_ACCOUNT_ID"
  athenaBucketName: "s3://your-company-cur-reports"
  athenaRegion: "us-east-1"
  athenaDatabase: "athenacurcfn_kubecost_cur"
  athenaTable: "kubecost_cur"
  
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/KubecostCostAnalyzerRole
```

**For OpenCost**:
```yaml
opencost:
  exporter:
    cloudProviderApiKey: ""  # Leave empty when using IRSA
    aws:
      access_key_id: ""  # Leave empty when using IRSA
      secret_access_key: ""  # Leave empty when using IRSA
      
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/KubecostCostAnalyzerRole
```

### Step 6: Verify Configuration

1. **Check service account annotation**:
   ```bash
   kubectl get serviceaccount -n finops kubecost-cost-analyzer -o yaml | grep eks.amazonaws.com/role-arn
   ```

2. **Check pod logs for AWS authentication**:
   ```bash
   kubectl logs -n finops -l app=cost-analyzer --tail=100 | grep -i aws
   ```

3. **Verify CUR data access**:
   - Navigate to Kubecost/OpenCost UI
   - Check that AWS costs are being populated (may take 24-48 hours for initial data)

---

## Azure Configuration

### Architecture

Kubecost/OpenCost running in AKS uses Azure Managed Identity or Service Principal to access Azure Cost Management API.

### Step 1: Enable Azure Cost Management

Azure Cost Management is enabled by default for all subscriptions. No additional setup required.

### Step 2: Create Service Principal

**Option A: Using Azure CLI**:

```bash
# Create service principal
az ad sp create-for-rbac --name kubecost-cost-reader --skip-assignment

# Output:
# {
#   "appId": "12345678-1234-1234-1234-123456789012",
#   "displayName": "kubecost-cost-reader",
#   "password": "your-client-secret",
#   "tenant": "87654321-4321-4321-4321-210987654321"
# }

# Save these values:
# - appId (Client ID)
# - password (Client Secret)
# - tenant (Tenant ID)
```

**Option B: Using Azure Portal**:

1. Navigate to **Azure Active Directory** > **App registrations** > **New registration**
2. Name: `kubecost-cost-reader`
3. Supported account types: **Accounts in this organizational directory only**
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID**
6. Go to **Certificates & secrets** > **New client secret**
7. Description: `kubecost-access`
8. Expiration: **24 months** (set reminder to rotate)
9. Click **Add** and copy the **Value** (client secret)

### Step 3: Assign Cost Management Reader Role

Assign the service principal the **Cost Management Reader** role at the subscription level:

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get the service principal object ID
SP_OBJECT_ID=$(az ad sp list --display-name kubecost-cost-reader --query [0].id -o tsv)

# Assign Cost Management Reader role
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Cost Management Reader" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

**Alternative: Assign via Azure Portal**:

1. Navigate to **Subscriptions** > Select your subscription > **Access control (IAM)**
2. Click **Add** > **Add role assignment**
3. Role: **Cost Management Reader**
4. Assign access to: **User, group, or service principal**
5. Select: `kubecost-cost-reader`
6. Click **Save**

### Step 4: Create Kubernetes Secret

Create a Kubernetes secret with the service principal credentials:

```bash
kubectl create secret generic azure-cost-credentials -n finops \
  --from-literal=azure-client-id="YOUR_CLIENT_ID" \
  --from-literal=azure-client-secret="YOUR_CLIENT_SECRET" \
  --from-literal=azure-tenant-id="YOUR_TENANT_ID" \
  --from-literal=azure-subscription-id="YOUR_SUBSCRIPTION_ID"
```

### Step 5: Configure Kubecost/OpenCost Helm Values

Add the following to your Helm values file:

**For Kubecost**:
```yaml
kubecostProductConfigs:
  azureSubscriptionID: "YOUR_SUBSCRIPTION_ID"
  azureClientID: "YOUR_CLIENT_ID"
  azureTenantID: "YOUR_TENANT_ID"
  azureClientPassword: "YOUR_CLIENT_SECRET"
  azureOfferDurableID: "MS-AZR-0003P"  # Pay-As-You-Go (adjust for your offer type)
  
# Alternative: Use existing secret
kubecostProductConfigs:
  azureSubscriptionID: "YOUR_SUBSCRIPTION_ID"
  createServiceKeySecret: false
  serviceKeySecretName: azure-cost-credentials
```

**For OpenCost**:
```yaml
opencost:
  exporter:
    cloudProviderApiKey: ""
    azure:
      subscription_id: "YOUR_SUBSCRIPTION_ID"
      client_id: "YOUR_CLIENT_ID"
      client_secret: "YOUR_CLIENT_SECRET"
      tenant_id: "YOUR_TENANT_ID"
      
# Alternative: Use existing secret
opencost:
  exporter:
    existingSecret: azure-cost-credentials
```

### Step 6: (Optional) Use Azure Managed Identity

For enhanced security, use Azure Managed Identity instead of service principal:

1. **Enable managed identity on AKS**:
   ```bash
   az aks update --name your-cluster-name --resource-group your-rg --enable-managed-identity
   ```

2. **Create user-assigned managed identity**:
   ```bash
   az identity create --name kubecost-identity --resource-group your-rg
   ```

3. **Assign Cost Management Reader role**:
   ```bash
   IDENTITY_PRINCIPAL_ID=$(az identity show --name kubecost-identity --resource-group your-rg --query principalId -o tsv)
   
   az role assignment create \
     --assignee $IDENTITY_PRINCIPAL_ID \
     --role "Cost Management Reader" \
     --scope /subscriptions/$SUBSCRIPTION_ID
   ```

4. **Configure pod identity**:
   ```bash
   # Install AAD Pod Identity (if not already installed)
   kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
   
   # Create AzureIdentity
   IDENTITY_CLIENT_ID=$(az identity show --name kubecost-identity --resource-group your-rg --query clientId -o tsv)
   IDENTITY_RESOURCE_ID=$(az identity show --name kubecost-identity --resource-group your-rg --query id -o tsv)
   
   cat <<EOF | kubectl apply -f -
   apiVersion: "aadpodidentity.k8s.io/v1"
   kind: AzureIdentity
   metadata:
     name: kubecost-identity
     namespace: finops
   spec:
     type: 0
     resourceID: $IDENTITY_RESOURCE_ID
     clientID: $IDENTITY_CLIENT_ID
   ---
   apiVersion: "aadpodidentity.k8s.io/v1"
   kind: AzureIdentityBinding
   metadata:
     name: kubecost-identity-binding
     namespace: finops
   spec:
     azureIdentity: kubecost-identity
     selector: kubecost
   EOF
   ```

5. **Update Helm values to use managed identity**:
   ```yaml
   podLabels:
     aadpodidbinding: kubecost
   ```

### Step 7: Verify Configuration

1. **Check secret creation**:
   ```bash
   kubectl get secret -n finops azure-cost-credentials
   ```

2. **Check pod logs for Azure authentication**:
   ```bash
   kubectl logs -n finops -l app=cost-analyzer --tail=100 | grep -i azure
   ```

3. **Verify cost data**:
   - Navigate to Kubecost/OpenCost UI
   - Check that Azure costs are being populated (may take 24-48 hours for initial data)

### Azure Offer Types

Common Azure offer types for `azureOfferDurableID`:

| Offer Type | Offer ID |
|------------|----------|
| Pay-As-You-Go | MS-AZR-0003P |
| Enterprise Agreement | MS-AZR-0017P |
| Dev/Test Pay-As-You-Go | MS-AZR-0023P |
| Enterprise Dev/Test | MS-AZR-0148P |
| CSP | MS-AZR-0145P |

Find your offer type: **Azure Portal** > **Subscriptions** > **Properties** > **Offer ID**

---

## GCP Configuration

### Architecture

Kubecost/OpenCost running in GKE uses Workload Identity to access GCP Billing Export data stored in BigQuery.

### Step 1: Enable GCP Billing Export

1. **Navigate to Billing Export**:
   - Open GCP Console > **Billing** > **Billing export**

2. **Enable BigQuery export**:
   - Click **Edit settings** for **Detailed usage cost**
   - Select or create a BigQuery dataset: `billing_export`
   - Project: Select your billing project (can be different from GKE project)
   - Click **Save**

3. **Enable Standard usage cost export** (optional, for detailed resource-level costs):
   - Click **Edit settings** for **Standard usage cost**
   - Use the same BigQuery dataset: `billing_export`
   - Click **Save**

4. **Wait for data**:
   - Billing data starts appearing within 24 hours
   - Historical data is not backfilled

### Step 2: Create Service Account

Create a GCP service account for Kubecost/OpenCost:

```bash
# Set variables
PROJECT_ID="your-gcp-project-id"
BILLING_PROJECT_ID="your-billing-project-id"  # May be same as PROJECT_ID
SERVICE_ACCOUNT_NAME="kubecost-cost-reader"

# Create service account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="Kubecost Cost Reader" \
  --project=$PROJECT_ID
```

### Step 3: Grant BigQuery Permissions

Grant the service account permissions to read billing data from BigQuery:

```bash
# Grant BigQuery Data Viewer role on billing dataset
gcloud projects add-iam-policy-binding $BILLING_PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"

# Grant BigQuery Job User role (required to run queries)
gcloud projects add-iam-policy-binding $BILLING_PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"

# Grant Compute Viewer role (for instance metadata)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"
```

**Minimum Required Permissions**:

If you prefer a custom role with least privilege, create a custom role with these permissions:

```yaml
title: "Kubecost Cost Reader"
description: "Minimum permissions for Kubecost/OpenCost to read billing data"
stage: "GA"
includedPermissions:
  # BigQuery permissions
  - bigquery.datasets.get
  - bigquery.tables.get
  - bigquery.tables.getData
  - bigquery.tables.list
  - bigquery.jobs.create
  
  # Compute permissions
  - compute.instances.list
  - compute.instances.get
  - compute.disks.list
  - compute.disks.get
  - compute.zones.list
  - compute.regions.list
  
  # GKE permissions
  - container.clusters.get
  - container.clusters.list
```

### Step 4: Configure Workload Identity

Enable Workload Identity binding between the GCP service account and Kubernetes service account:

```bash
# Enable Workload Identity on GKE cluster (if not already enabled)
gcloud container clusters update your-cluster-name \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --region=your-region

# Create Kubernetes service account (if not exists)
kubectl create serviceaccount kubecost-cost-analyzer -n finops

# Bind GCP service account to Kubernetes service account
gcloud iam service-accounts add-iam-policy-binding \
  ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[finops/kubecost-cost-analyzer]"

# Annotate Kubernetes service account
kubectl annotate serviceaccount kubecost-cost-analyzer -n finops \
  iam.gke.io/gcp-service-account=${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

### Step 5: Configure Kubecost/OpenCost Helm Values

Add the following to your Helm values file:

**For Kubecost**:
```yaml
kubecostProductConfigs:
  gcpProjectID: "YOUR_GCP_PROJECT_ID"
  gcpBillingDataDataset: "billing_export.gcp_billing_export_v1_XXXXXX"  # Replace with your table name
  gcpServiceKeyName: ""  # Leave empty when using Workload Identity
  
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: kubecost-cost-reader@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com
```

**For OpenCost**:
```yaml
opencost:
  exporter:
    cloudProviderApiKey: ""  # Leave empty when using Workload Identity
    gcp:
      project_id: "YOUR_GCP_PROJECT_ID"
      billing_dataset: "billing_export.gcp_billing_export_v1_XXXXXX"
      
  serviceAccount:
    create: true
    annotations:
      iam.gke.io/gcp-service-account: kubecost-cost-reader@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com
```

**Finding your BigQuery table name**:

```bash
# List tables in billing dataset
bq ls --project_id=$BILLING_PROJECT_ID billing_export

# Output will show table name like: gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX
```

### Step 6: (Alternative) Use Service Account Key

If Workload Identity is not available, use a service account key (less secure):

1. **Create service account key**:
   ```bash
   gcloud iam service-accounts keys create kubecost-key.json \
     --iam-account=${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
   ```

2. **Create Kubernetes secret**:
   ```bash
   kubectl create secret generic gcp-cost-credentials -n finops \
     --from-file=key.json=kubecost-key.json
   ```

3. **Update Helm values**:
   ```yaml
   kubecostProductConfigs:
     gcpProjectID: "YOUR_GCP_PROJECT_ID"
     gcpBillingDataDataset: "billing_export.gcp_billing_export_v1_XXXXXX"
     gcpServiceKeyName: "gcp-cost-credentials"
     gcpServiceKeySecret: "key.json"
   ```

4. **Securely delete the key file**:
   ```bash
   shred -u kubecost-key.json
   ```

### Step 7: Verify Configuration

1. **Check service account annotation**:
   ```bash
   kubectl get serviceaccount -n finops kubecost-cost-analyzer -o yaml | grep iam.gke.io/gcp-service-account
   ```

2. **Check pod logs for GCP authentication**:
   ```bash
   kubectl logs -n finops -l app=cost-analyzer --tail=100 | grep -i gcp
   ```

3. **Verify billing data access**:
   - Navigate to Kubecost/OpenCost UI
   - Check that GCP costs are being populated (may take 24-48 hours for initial data)

4. **Test BigQuery access from pod**:
   ```bash
   kubectl exec -n finops -it deployment/kubecost-cost-analyzer -- \
     bq query --project_id=YOUR_BILLING_PROJECT_ID --use_legacy_sql=false \
     'SELECT COUNT(*) FROM `billing_export.gcp_billing_export_v1_XXXXXX` LIMIT 1'
   ```

---

## Multi-Cloud Configuration

If you're running Kubernetes clusters across multiple cloud providers, configure each cluster with its respective cloud provider credentials. Kubecost/OpenCost will automatically detect the cloud provider based on cluster metadata.

### Centralized Multi-Cloud Monitoring

For centralized cost visibility across multiple clusters and cloud providers:

1. **Deploy Kubecost/OpenCost on each cluster** with appropriate cloud provider configuration
2. **Use Kubecost Federation** (Kubecost Enterprise) or **OpenCost multi-cluster** to aggregate data
3. **Configure Grafana dashboards** to query cost data from multiple Prometheus instances

---

## Troubleshooting

### AWS

**Issue**: CUR data not appearing in Kubecost/OpenCost

**Solutions**:
- Verify CUR report is enabled and first report has been generated (check S3 bucket)
- Verify IAM role has correct permissions and trust policy
- Check service account annotation: `kubectl get sa -n finops kubecost-cost-analyzer -o yaml`
- Check pod logs for authentication errors: `kubectl logs -n finops -l app=cost-analyzer`
- Verify Athena database and table exist: `aws athena list-databases --catalog-name AwsDataCatalog`

**Issue**: "Access Denied" errors in logs

**Solutions**:
- Verify IAM policy includes all required permissions (see Step 2)
- Verify S3 bucket policy allows access from IAM role
- Check IRSA trust policy includes correct OIDC provider and service account

### Azure

**Issue**: Azure cost data not appearing

**Solutions**:
- Verify service principal has "Cost Management Reader" role at subscription level
- Check secret exists and contains correct credentials: `kubectl get secret -n finops azure-cost-credentials -o yaml`
- Verify subscription ID, client ID, tenant ID are correct
- Check pod logs for authentication errors: `kubectl logs -n finops -l app=cost-analyzer`
- Test service principal authentication: `az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID`

**Issue**: "Unauthorized" or "Forbidden" errors

**Solutions**:
- Verify client secret has not expired (Azure Portal > App registrations > Certificates & secrets)
- Verify service principal has not been deleted
- Check role assignment: `az role assignment list --assignee CLIENT_ID --scope /subscriptions/SUBSCRIPTION_ID`

### GCP

**Issue**: BigQuery billing data not appearing

**Solutions**:
- Verify billing export is enabled and data exists in BigQuery: `bq query 'SELECT COUNT(*) FROM billing_export.gcp_billing_export_v1_XXXXXX LIMIT 1'`
- Verify service account has BigQuery Data Viewer and Job User roles
- Check Workload Identity binding: `gcloud iam service-accounts get-iam-policy SERVICE_ACCOUNT_EMAIL`
- Check pod logs for authentication errors: `kubectl logs -n finops -l app=cost-analyzer`
- Verify BigQuery dataset name is correct in Helm values

**Issue**: "Permission denied" errors

**Solutions**:
- Verify Workload Identity is enabled on GKE cluster
- Verify service account annotation on Kubernetes service account
- Check IAM policy binding: `gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:serviceAccount:SERVICE_ACCOUNT_EMAIL"`

---

## Security Best Practices

### Credential Rotation

- **AWS**: IAM roles with IRSA do not require credential rotation (uses temporary credentials)
- **Azure**: Rotate service principal client secrets every 12-24 months (set expiration reminder)
- **GCP**: Workload Identity does not require credential rotation; if using service account keys, rotate every 90 days

### Least Privilege

- Grant only the minimum required permissions listed in this document
- Use read-only roles (Cost Management Reader, BigQuery Data Viewer)
- Avoid granting admin or write permissions

### Secret Management

- Store credentials in Kubernetes Secrets with encryption at rest enabled
- Consider using external secret management (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) with External Secrets Operator
- Never commit credentials to version control

### Audit Logging

- Enable cloud provider audit logging for cost API access
- Monitor for unusual access patterns or unauthorized access attempts
- Set up alerts for failed authentication attempts

---

## Cost Optimization Tips

### AWS

- Enable **Resource IDs** in CUR for accurate pod-level cost allocation
- Use **Savings Plans** or **Reserved Instances** for stable workloads (see reserved capacity recommendations)
- Enable **EBS volume optimization** to identify unused volumes

### Azure

- Use **Azure Reservations** for stable workloads
- Enable **Azure Hybrid Benefit** if you have Windows Server or SQL Server licenses
- Review **Azure Advisor** recommendations alongside Kubecost/OpenCost data

### GCP

- Use **Committed Use Discounts** for stable workloads
- Enable **Sustained Use Discounts** (automatic)
- Use **Preemptible VMs** for fault-tolerant workloads

---

## Next Steps

After completing cloud provider configuration:

1. **Verify cost data is flowing** (allow 24-48 hours for initial data)
2. **Deploy Grafana dashboards** for cost visibility (see `finops/dashboards/`)
3. **Configure budget alerts** to monitor spending (see `finops/config/budgets.yaml`)
4. **Implement Kyverno cost policies** for governance (see `finops/policies/`)
5. **Review rightsizing recommendations** to optimize resource usage (see `finops/scripts/analyze-rightsizing.py`)

---

## References

- [AWS Cost and Usage Reports Documentation](https://docs.aws.amazon.com/cur/latest/userguide/what-is-cur.html)
- [Azure Cost Management API Documentation](https://learn.microsoft.com/en-us/rest/api/cost-management/)
- [GCP Billing Export Documentation](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [Kubecost Cloud Integration Documentation](https://docs.kubecost.com/install-and-configure/install/cloud-integration)
- [OpenCost Cloud Costs Documentation](https://www.opencost.io/docs/configuration/cloud-costs)
- [EKS IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [AKS Managed Identity](https://learn.microsoft.com/en-us/azure/aks/use-managed-identity)
- [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-15  
**Maintained By**: Platform Engineering Team
