// ============================================================
// TEMPLATE: Pulumi — Azure AKS Cluster
// WHEN TO USE: Provisioning AKS with ACR integration
// PREREQUISITES: Azure subscription, Pulumi CLI, Node.js
// SECRETS NEEDED: Azure credentials (OIDC recommended)
// WHAT TO CHANGE: config values in Pulumi.<stack>.yaml
// RELATED FILES: cd/pulumi/deploy.yml, terraform/azure-aks/
// MATURITY: Stable
// ============================================================

import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure-native";

const config = new pulumi.Config();
const nodeCount = config.getNumber("nodeCount") || 3;
const nodeVmSize = config.get("nodeVmSize") || "Standard_D2s_v3";
const kubernetesVersion = config.get("kubernetesVersion") || "1.29";

const project = pulumi.getProject();
const stack = pulumi.getStack();
const prefix = `${project}-${stack}`;

// ── Resource Group ──────────────────────────────────────────
const resourceGroup = new azure.resources.ResourceGroup(`${prefix}-rg`, {
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── Container Registry ─────────────────────────────────────
const acr = new azure.containerregistry.Registry(`${prefix}acr`.replace(/-/g, ""), {
  resourceGroupName: resourceGroup.name,
  sku: { name: azure.containerregistry.SkuName.Basic },          // <-- CHANGE THIS: Standard or Premium for prod
  adminUserEnabled: false,
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── AKS Cluster ─────────────────────────────────────────────
const cluster = new azure.containerservice.ManagedCluster(`${prefix}-aks`, {
  resourceGroupName: resourceGroup.name,
  kubernetesVersion: kubernetesVersion,
  dnsPrefix: prefix,
  identity: { type: azure.containerservice.ResourceIdentityType.SystemAssigned },
  agentPoolProfiles: [{
    name: "system",
    count: nodeCount,
    vmSize: nodeVmSize,
    osType: azure.containerservice.OSType.Linux,
    mode: azure.containerservice.AgentPoolMode.System,
    enableAutoScaling: true,
    minCount: 1,
    maxCount: nodeCount * 2,
  }],
  networkProfile: {
    networkPlugin: "azure",
    networkPolicy: "calico",
    serviceCidr: "10.0.0.0/16",
    dnsServiceIP: "10.0.0.10",
  },
  addonProfiles: {
    omsagent: {
      enabled: true,
      config: {},                                                  // <-- CHANGE THIS: add logAnalyticsWorkspaceResourceID
    },
  },
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── ACR Pull Role Assignment ────────────────────────────────
const acrPull = new azure.authorization.RoleAssignment(`${prefix}-acr-pull`, {
  principalId: cluster.identityProfile.apply(p => p!["kubeletidentity"].objectId!),
  principalType: azure.authorization.PrincipalType.ServicePrincipal,
  roleDefinitionId: "/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d", // AcrPull
  scope: acr.id,
});

// ── Outputs ─────────────────────────────────────────────────
export const clusterName = cluster.name;
export const resourceGroupName = resourceGroup.name;
export const acrLoginServer = acr.loginServer;
export const kubeconfig = pulumi
  .all([resourceGroup.name, cluster.name])
  .apply(([rgName, clusterName]) =>
    azure.containerservice.listManagedClusterUserCredentials({
      resourceGroupName: rgName,
      resourceName: clusterName,
    }),
  )
  .apply(creds => {
    const encoded = creds.kubeconfigs[0].value;
    return Buffer.from(encoded, "base64").toString("utf-8");
  });
