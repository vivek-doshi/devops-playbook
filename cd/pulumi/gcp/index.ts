// ============================================================
// TEMPLATE: Pulumi — GCP GKE Autopilot Cluster
// WHEN TO USE: Provisioning GKE Autopilot with Artifact Registry
// PREREQUISITES: GCP project, Pulumi CLI, Node.js
// SECRETS NEEDED: GCP credentials (Workload Identity Federation recommended)
// WHAT TO CHANGE: config values in Pulumi.<stack>.yaml
// RELATED FILES: cd/pulumi/deploy.yml, terraform/gcp-gke/
// MATURITY: Stable
// ============================================================

// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();
// Note 2: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const machineType = config.get("machineType") || "e2-medium";
const nodeCount = config.getNumber("nodeCount") || 3;

const project = pulumi.getProject();
// Note 3: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const stack = pulumi.getStack();
const prefix = `${project}-${stack}`;

// ── Enable required APIs ────────────────────────────────────
const apis = [
  // Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  "container.googleapis.com",
  "artifactregistry.googleapis.com",
  "compute.googleapis.com",
// Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
];

const enabledApis = apis.map(
  (api) => new gcp.projects.Service(`${prefix}-${api}`, {
    // Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    service: api,
    disableOnDestroy: false,
  }),
// Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
);

// ── VPC Network ─────────────────────────────────────────────
const network = new gcp.compute.Network(`${prefix}-vpc`, {
  autoCreateSubnetworks: false,
// Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}, { dependsOn: enabledApis });

const subnet = new gcp.compute.Subnetwork(`${prefix}-subnet`, {
  network: network.id,
  // Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  ipCidrRange: "10.0.0.0/20",
  secondaryIpRanges: [
    { rangeName: "pods", ipCidrRange: "10.4.0.0/14" },
    // Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    { rangeName: "services", ipCidrRange: "10.8.0.0/20" },
  ],
});

// ── GKE Cluster ─────────────────────────────────────────────
// Note 11: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const cluster = new gcp.container.Cluster(`${prefix}-gke`, {
  network: network.id,
  subnetwork: subnet.id,
  // Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location: gcp.config.region!,
  removeDefaultNodePool: true,
  initialNodeCount: 1,
  // Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  ipAllocationPolicy: {
    clusterSecondaryRangeName: "pods",
    servicesSecondaryRangeName: "services",
  // Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  },
  workloadIdentityConfig: {
    workloadPool: `${gcp.config.project}.svc.id.goog`,
  // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  },
  releaseChannel: { channel: "REGULAR" },
  resourceLabels: {
    // Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    project: project,
    environment: stack,
    "managed-by": "pulumi",
  // Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  },
}, { dependsOn: enabledApis });

// ── Node Pool ───────────────────────────────────────────────
const nodePool = new gcp.container.NodePool(`${prefix}-pool`, {
  // Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  cluster: cluster.name,
  location: gcp.config.region!,
  nodeCount: nodeCount,
  // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  autoscaling: {
    minNodeCount: 1,
    maxNodeCount: nodeCount * 2,
  // Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  },
  nodeConfig: {
    machineType: machineType,
    // Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    oauthScopes: ["https://www.googleapis.com/auth/cloud-platform"],
    workloadMetadataConfig: {
      mode: "GKE_METADATA",
    // Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    },
    shieldedInstanceConfig: {
      enableSecureBoot: true,
      // Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      enableIntegrityMonitoring: true,
    },
  },
  // Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  management: {
    autoRepair: true,
    autoUpgrade: true,
  // Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  },
});

// ── Artifact Registry ───────────────────────────────────────
const registry = new gcp.artifactregistry.Repository(`${prefix}-repo`, {
  // Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  format: "DOCKER",
  location: gcp.config.region!,
  description: `Container images for ${prefix}`,
  // Note 27: Resource identity and metadata drive automation, selectors, and operational traceability.
  labels: { project: project, environment: stack, "managed-by": "pulumi" },
}, { dependsOn: enabledApis });

// ── Outputs ─────────────────────────────────────────────────
export const clusterName = cluster.name;
// Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
export const clusterEndpoint = cluster.endpoint;
export const registryUrl = pulumi.interpolate`${registry.location}-docker.pkg.dev/${gcp.config.project}/${registry.repositoryId}`;
export const kubeconfig = pulumi.interpolate`
// Note 29: This Kubernetes style field captures a contract; keeping schema keys stable improves portability across environments.
apiVersion: v1
kind: Config
clusters:
// Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
- cluster:
    server: https://${cluster.endpoint}
    certificate-authority-data: ${cluster.masterAuth.clusterCaCertificate}
  // Note 31: Resource identity and metadata drive automation, selectors, and operational traceability.
  name: ${cluster.name}
contexts:
- context:
    // Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    cluster: ${cluster.name}
    user: ${cluster.name}
  name: ${cluster.name}
// Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
current-context: ${cluster.name}
users:
- name: ${cluster.name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for kubectl
`;
