// ============================================================
// TEMPLATE: Pulumi — Azure AKS Cluster
// WHEN TO USE: Provisioning AKS with ACR integration
// PREREQUISITES: Azure subscription, Pulumi CLI, Node.js
// SECRETS NEEDED: Azure credentials (OIDC recommended)
// WHAT TO CHANGE: config values in Pulumi.<stack>.yaml
// RELATED FILES: cd/pulumi/deploy.yml, terraform/azure-aks/
// MATURITY: Stable
// ============================================================

// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure-native";

// Note 2: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const config = new pulumi.Config();
const nodeCount = config.getNumber("nodeCount") || 3;
// Note 3: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const nodeVmSize = config.get("nodeVmSize") || "Standard_D2s_v3";
const kubernetesVersion = config.get("kubernetesVersion") || "1.29";

// Note 4: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const project = pulumi.getProject();
const stack = pulumi.getStack();
// Note 5: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const prefix = `${project}-${stack}`;

// ── Resource Group ──────────────────────────────────────────
const resourceGroup = new azure.resources.ResourceGroup(`${prefix}-rg`, {
  // Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── Container Registry ─────────────────────────────────────
// Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const acr = new azure.containerregistry.Registry(`${prefix}acr`.replace(/-/g, ""), {
  resourceGroupName: resourceGroup.name,
  // Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  sku: { name: azure.containerregistry.SkuName.Basic },          // <-- CHANGE THIS: Standard or Premium for prod
  adminUserEnabled: false,
  // Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── AKS Cluster ─────────────────────────────────────────────
// Note 10: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const cluster = new azure.containerservice.ManagedCluster(`${prefix}-aks`, {
  resourceGroupName: resourceGroup.name,
  // Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  kubernetesVersion: kubernetesVersion,
  dnsPrefix: prefix,
  // Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  identity: { type: azure.containerservice.ResourceIdentityType.SystemAssigned },
  agentPoolProfiles: [{
    // Note 13: Resource identity and metadata drive automation, selectors, and operational traceability.
    name: "system",
    count: nodeCount,
    // Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    vmSize: nodeVmSize,
    osType: azure.containerservice.OSType.Linux,
    // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    mode: azure.containerservice.AgentPoolMode.System,
    enableAutoScaling: true,
    // Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    minCount: 1,
    maxCount: nodeCount * 2,
  // Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }],
  networkProfile: {
    // Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    networkPlugin: "azure",
    networkPolicy: "calico",
    // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    serviceCidr: "10.0.0.0/16",
    dnsServiceIP: "10.0.0.10",
  // Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  },
  addonProfiles: {
    // Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    omsagent: {
      enabled: true,
      // Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      config: {},                                                  // <-- CHANGE THIS: add logAnalyticsWorkspaceResourceID
    },
  // Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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
