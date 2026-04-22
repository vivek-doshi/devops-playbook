// ============================================================
// TEMPLATE: Pulumi — AWS ECS Fargate Service
// WHEN TO USE: Deploying containers on ECS Fargate with ALB
// PREREQUISITES: AWS account, Pulumi CLI, Node.js
// SECRETS NEEDED: AWS credentials (OIDC recommended)
// WHAT TO CHANGE: config values in Pulumi.<stack>.yaml
// RELATED FILES: cd/pulumi/deploy.yml, terraform/aws-ecs/
// MATURITY: Stable
// ============================================================

// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
// Note 2: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import * as awsx from "@pulumi/awsx";

const config = new pulumi.Config();
// Note 3: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const containerPort = config.getNumber("containerPort") || 3000;  // <-- CHANGE THIS
const cpu = config.getNumber("cpu") || 256;
// Note 4: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const memory = config.getNumber("memory") || 512;
const desiredCount = config.getNumber("desiredCount") || 2;
// Note 5: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const imageName = config.require("imageName");                    // <-- CHANGE THIS in Pulumi.<stack>.yaml

const project = pulumi.getProject();
// Note 6: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const stack = pulumi.getStack();
const prefix = `${project}-${stack}`;

// ── VPC ─────────────────────────────────────────────────────
// Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const vpc = new awsx.ec2.Vpc(`${prefix}-vpc`, {
  numberOfAvailabilityZones: 2,
  // Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  natGateways: { strategy: awsx.ec2.NatGatewayStrategy.Single },
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
// Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
});

// ── ECS Cluster ─────────────────────────────────────────────
const cluster = new aws.ecs.Cluster(`${prefix}-cluster`, {
  // Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  settings: [{ name: "containerInsights", value: "enabled" }],
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
// Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
});

// ── Application Load Balancer ───────────────────────────────
const alb = new awsx.lb.ApplicationLoadBalancer(`${prefix}-alb`, {
  // Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  subnetIds: vpc.publicSubnetIds,
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
// Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
});

// ── ECS Fargate Service ─────────────────────────────────────
const service = new awsx.ecs.FargateService(`${prefix}-svc`, {
  // Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  cluster: cluster.arn,
  desiredCount: desiredCount,
  // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  networkConfiguration: {
    subnets: vpc.privateSubnetIds,
    // Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    assignPublicIp: false,
  },
  // Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  taskDefinitionArgs: {
    container: {
      // Note 18: Resource identity and metadata drive automation, selectors, and operational traceability.
      name: "app",
      image: imageName,
      // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      cpu: cpu,
      memory: memory,
      // Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      essential: true,
      portMappings: [{
        // Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        containerPort: containerPort,
        targetGroup: alb.defaultTargetGroup,
      // Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      }],
      environment: [
        { name: "PORT", value: containerPort.toString() },
      ],
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          "awslogs-group": `/ecs/${prefix}`,
          "awslogs-region": aws.config.region!,
          "awslogs-stream-prefix": "app",
          "awslogs-create-group": "true",
        },
      },
    },
  },
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── Outputs ─────────────────────────────────────────────────
export const clusterName = cluster.name;
export const serviceArn = service.service.id;
export const albDnsName = alb.loadBalancer.dnsName;
export const url = pulumi.interpolate`http://${alb.loadBalancer.dnsName}`;
export const vpcId = vpc.vpcId;
