// ============================================================
// TEMPLATE: Pulumi — AWS ECS Fargate Service
// WHEN TO USE: Deploying containers on ECS Fargate with ALB
// PREREQUISITES: AWS account, Pulumi CLI, Node.js
// SECRETS NEEDED: AWS credentials (OIDC recommended)
// WHAT TO CHANGE: config values in Pulumi.<stack>.yaml
// RELATED FILES: cd/pulumi/deploy.yml, terraform/aws-ecs/
// MATURITY: Stable
// ============================================================

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";

const config = new pulumi.Config();
const containerPort = config.getNumber("containerPort") || 3000;  // <-- CHANGE THIS
const cpu = config.getNumber("cpu") || 256;
const memory = config.getNumber("memory") || 512;
const desiredCount = config.getNumber("desiredCount") || 2;
const imageName = config.require("imageName");                    // <-- CHANGE THIS in Pulumi.<stack>.yaml

const project = pulumi.getProject();
const stack = pulumi.getStack();
const prefix = `${project}-${stack}`;

// ── VPC ─────────────────────────────────────────────────────
const vpc = new awsx.ec2.Vpc(`${prefix}-vpc`, {
  numberOfAvailabilityZones: 2,
  natGateways: { strategy: awsx.ec2.NatGatewayStrategy.Single },
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── ECS Cluster ─────────────────────────────────────────────
const cluster = new aws.ecs.Cluster(`${prefix}-cluster`, {
  settings: [{ name: "containerInsights", value: "enabled" }],
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── Application Load Balancer ───────────────────────────────
const alb = new awsx.lb.ApplicationLoadBalancer(`${prefix}-alb`, {
  subnetIds: vpc.publicSubnetIds,
  tags: { Project: project, Environment: stack, ManagedBy: "pulumi" },
});

// ── ECS Fargate Service ─────────────────────────────────────
const service = new awsx.ecs.FargateService(`${prefix}-svc`, {
  cluster: cluster.arn,
  desiredCount: desiredCount,
  networkConfiguration: {
    subnets: vpc.privateSubnetIds,
    assignPublicIp: false,
  },
  taskDefinitionArgs: {
    container: {
      name: "app",
      image: imageName,
      cpu: cpu,
      memory: memory,
      essential: true,
      portMappings: [{
        containerPort: containerPort,
        targetGroup: alb.defaultTargetGroup,
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
