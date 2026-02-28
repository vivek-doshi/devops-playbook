// ============================================================
// TEMPLATE: Pulumi — GCP GKE Autopilot Cluster
// WHEN TO USE: Provisioning GKE Autopilot with Artifact Registry
// PREREQUISITES: GCP project, Pulumi CLI, Node.js
// SECRETS NEEDED: GCP credentials (Workload Identity Federation recommended)
// WHAT TO CHANGE: config values in Pulumi.<stack>.yaml
// RELATED FILES: cd/pulumi/deploy.yml, terraform/gcp-gke/
// MATURITY: Stable
// ============================================================

import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();
const machineType = config.get("machineType") || "e2-medium";
const nodeCount = config.getNumber("nodeCount") || 3;

const project = pulumi.getProject();
const stack = pulumi.getStack();
const prefix = `${project}-${stack}`;

// ── Enable required APIs ────────────────────────────────────
const apis = [
  "container.googleapis.com",
  "artifactregistry.googleapis.com",
  "compute.googleapis.com",
];

const enabledApis = apis.map(
  (api) => new gcp.projects.Service(`${prefix}-${api}`, {
    service: api,
    disableOnDestroy: false,
  }),
);

// ── VPC Network ─────────────────────────────────────────────
const network = new gcp.compute.Network(`${prefix}-vpc`, {
  autoCreateSubnetworks: false,
}, { dependsOn: enabledApis });

const subnet = new gcp.compute.Subnetwork(`${prefix}-subnet`, {
  network: network.id,
  ipCidrRange: "10.0.0.0/20",
  secondaryIpRanges: [
    { rangeName: "pods", ipCidrRange: "10.4.0.0/14" },
    { rangeName: "services", ipCidrRange: "10.8.0.0/20" },
  ],
});

// ── GKE Cluster ─────────────────────────────────────────────
const cluster = new gcp.container.Cluster(`${prefix}-gke`, {
  network: network.id,
  subnetwork: subnet.id,
  location: gcp.config.region!,
  removeDefaultNodePool: true,
  initialNodeCount: 1,
  ipAllocationPolicy: {
    clusterSecondaryRangeName: "pods",
    servicesSecondaryRangeName: "services",
  },
  workloadIdentityConfig: {
    workloadPool: `${gcp.config.project}.svc.id.goog`,
  },
  releaseChannel: { channel: "REGULAR" },
  resourceLabels: {
    project: project,
    environment: stack,
    "managed-by": "pulumi",
  },
}, { dependsOn: enabledApis });

// ── Node Pool ───────────────────────────────────────────────
const nodePool = new gcp.container.NodePool(`${prefix}-pool`, {
  cluster: cluster.name,
  location: gcp.config.region!,
  nodeCount: nodeCount,
  autoscaling: {
    minNodeCount: 1,
    maxNodeCount: nodeCount * 2,
  },
  nodeConfig: {
    machineType: machineType,
    oauthScopes: ["https://www.googleapis.com/auth/cloud-platform"],
    workloadMetadataConfig: {
      mode: "GKE_METADATA",
    },
    shieldedInstanceConfig: {
      enableSecureBoot: true,
      enableIntegrityMonitoring: true,
    },
  },
  management: {
    autoRepair: true,
    autoUpgrade: true,
  },
});

// ── Artifact Registry ───────────────────────────────────────
const registry = new gcp.artifactregistry.Repository(`${prefix}-repo`, {
  format: "DOCKER",
  location: gcp.config.region!,
  description: `Container images for ${prefix}`,
  labels: { project: project, environment: stack, "managed-by": "pulumi" },
}, { dependsOn: enabledApis });

// ── Outputs ─────────────────────────────────────────────────
export const clusterName = cluster.name;
export const clusterEndpoint = cluster.endpoint;
export const registryUrl = pulumi.interpolate`${registry.location}-docker.pkg.dev/${gcp.config.project}/${registry.repositoryId}`;
export const kubeconfig = pulumi.interpolate`
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://${cluster.endpoint}
    certificate-authority-data: ${cluster.masterAuth.clusterCaCertificate}
  name: ${cluster.name}
contexts:
- context:
    cluster: ${cluster.name}
    user: ${cluster.name}
  name: ${cluster.name}
current-context: ${cluster.name}
users:
- name: ${cluster.name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for kubectl
`;
