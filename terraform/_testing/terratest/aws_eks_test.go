// ============================================================
// TEMPLATE: Terratest — AWS EKS integration tests (Go)
// WHEN TO USE: Full infrastructure integration tests that provision
//   real AWS resources and verify them end-to-end. Complements the
//   native terraform test file (../../../aws-eks/tests/unit.tftest.hcl).
//
// WHEN NOT TO USE: Fast PR feedback — use unit.tftest.hcl instead.
//
// PREREQUISITES:
//   - Go >= 1.21
//   - Run from this directory: go mod init github.com/your-org/tf-tests
//   - go get github.com/gruntwork-io/terratest/modules/terraform
//   - go get github.com/gruntwork-io/terratest/modules/aws
//   - go get github.com/gruntwork-io/terratest/modules/k8s
//   - go get github.com/stretchr/testify/assert
//   - AWS credentials with EKS / VPC / IAM permissions
//
// HOW TO RUN:
//   cd terraform/_testing/terratest
//   go test -v -timeout 10m  -run TestEKSPlanOnly     # fast, no real resources
//   go test -v -timeout 60m  -run TestEKSCluster      # creates real resources
//   go test -v -timeout 60m  -run TestEKSNodeGroupScaling
//
// WARNING: TestEKSCluster creates real AWS resources and incurs cost.
//   Run ONLY in a dedicated test account, never against production.
//   Resources are always cleaned up via defer terraform.Destroy().
//
// WHAT TO CHANGE: Lines marked  // <-- CHANGE THIS
// RELATED FILES:
//   terraform/aws-eks/main.tf
//   terraform/aws-eks/tests/unit.tftest.hcl   (native terraform test)
// ============================================================

package test

import (
	"fmt"
	"testing"
	"time"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	awsRegion   = "us-east-1"     // <-- CHANGE THIS: region for integration tests
	tfModuleDir = "../../aws-eks" // <-- CHANGE THIS: path from this file to the module
)

// TestEKSPlanOnly runs plan-only validation — no real resources created.
// Fast (~30s). Use this in every PR pipeline for rapid feedback.
func TestEKSPlanOnly(t *testing.T) {
	t.Parallel()

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tfModuleDir,
		Vars: map[string]interface{}{
			"project":     "test",        // <-- CHANGE THIS: match your variable names
			"environment": "test",
			"aws_region":  awsRegion,
			"vpc_cidr":    "10.0.0.0/16",
		},
		PlanFilePath: t.TempDir() + "/tfplan",
	})

	plan := terraform.InitAndPlanAndShowWithStruct(t, opts)

	// Note 1: ResourcePlannedValuesMap keys are the Terraform resource addresses
	// from the plan JSON. If a test fails with "nil", run:
	//   terraform show -json tfplan | jq '.planned_values.root_module.resources[].address'
	vpc, ok := plan.ResourcePlannedValuesMap["aws_vpc.main"]
	require.True(t, ok, "aws_vpc.main must appear in the plan")
	assert.Equal(t, "10.0.0.0/16", vpc.AttributeValues["cidr_block"])
	assert.Equal(t, true, vpc.AttributeValues["enable_dns_hostnames"])
	assert.Equal(t, true, vpc.AttributeValues["enable_dns_support"])
}

// TestEKSCluster creates a real EKS cluster, verifies it is healthy,
// then destroys everything. Takes ~25 minutes.
// Run in a DEDICATED TEST AWS ACCOUNT — never production.
func TestEKSCluster(t *testing.T) {
	t.Parallel()

	// Note 2: UniqueId generates a 6-char random suffix so parallel runs
	// don't collide on resource names (e.g., IAM roles, VPC names).
	uid     := random.UniqueId()
	project := fmt.Sprintf("tt-%s", uid) // <-- CHANGE THIS prefix if desired

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tfModuleDir,
		Vars: map[string]interface{}{
			"project":     project,
			"environment": "test",
			"aws_region":  awsRegion,
			"vpc_cidr":    "10.99.0.0/16",
			// Add all required variables from your variables.tf  // <-- CHANGE THIS
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	})

	// Note 3: Always defer Destroy so resources are cleaned up even on test failure.
	// Without this, a failed test leaves orphaned AWS resources incurring cost.
	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)

	// ── Verify Terraform outputs ──────────────────────────────────────────
	clusterName := terraform.Output(t, opts, "cluster_name") // <-- CHANGE THIS: match your output
	require.NotEmpty(t, clusterName, "cluster_name output must not be empty")

	// ── Verify cluster via AWS SDK ────────────────────────────────────────
	cluster := aws.GetEksCluster(t, awsRegion, clusterName)
	assert.Equal(t, "ACTIVE", awssdk.StringValue(cluster.Status),
		"EKS cluster must reach ACTIVE status after apply")

	// ── Verify kubectl connectivity ───────────────────────────────────────
	// Note 4: Your module should output a kubeconfig file path.
	// Adjust the output name to match what your module exposes.
	kubeconfig := terraform.Output(t, opts, "kubeconfig_path") // <-- CHANGE THIS
	k8sOpts    := k8s.NewKubectlOptions("", kubeconfig, "kube-system")

	// Note 5: kube-system pods starting confirms control plane + CNI health.
	// Retries up to 30 times with 10s between attempts (~5 min total).
	k8s.WaitUntilAllPodsAvailable(t, k8sOpts, map[string]string{}, 30, 10*time.Second)
}

// TestEKSNodeGroupScaling verifies autoscaling config is applied correctly.
// Plan-only — no real resources created.
func TestEKSNodeGroupScaling(t *testing.T) {
	t.Parallel()

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tfModuleDir,
		Vars: map[string]interface{}{
			"project":             "test",
			"environment":         "test",
			"aws_region":          awsRegion,
			"vpc_cidr":            "10.0.0.0/16",
			"node_group_min_size": 1, // <-- CHANGE THIS: match your variable names
			"node_group_max_size": 5,
			"node_group_desired":  2,
		},
		PlanFilePath: t.TempDir() + "/tfplan",
	})

	plan := terraform.InitAndPlanAndShowWithStruct(t, opts)

	ng, ok := plan.ResourcePlannedValuesMap["aws_eks_node_group.main"] // <-- CHANGE THIS: match your resource address
	require.True(t, ok, "aws_eks_node_group.main must appear in the plan")

	// Note 6: scaling_config is a list with one element in the plan JSON.
	scalingConfig := ng.AttributeValues["scaling_config"].([]interface{})[0].(map[string]interface{})
	assert.Equal(t, float64(1), scalingConfig["min_size"])
	assert.Equal(t, float64(5), scalingConfig["max_size"])
	assert.Equal(t, float64(2), scalingConfig["desired_size"])
}
