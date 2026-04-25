# Terraform Tests

This directory contains automated tests for Terraform modules using the native `terraform test` framework (introduced in Terraform 1.6).

## Why Test Terraform?

Terraform modules can silently violate naming conventions, resource sizing guardrails, or security policies. Tests catch these mistakes in CI before they reach a real cloud environment.

## Testing Approaches

### 1. `terraform test` (native — recommended)

Built into Terraform 1.6+. Uses `.tftest.hcl` files placed next to the module under test or in a `tests/` subdirectory.

**Pros:**
- No extra tools to install
- Runs with `terraform test` — same CLI already used for plan/apply
- Supports `mock_provider` blocks — no cloud credentials needed for unit tests
- Validates output values, resource attributes, and variable constraints

**Cons:**
- Cannot test for resources that should NOT be created (negative assertions are verbose)
- Mock providers cannot cover all resource types

### 2. Terratest (Go-based — for integration tests)

A Go testing library that actually provisions real cloud infrastructure, runs assertions, then destroys it.

**Pros:**
- Validates the real cloud API response (not mocked)
- Can SSH into VMs, call HTTP endpoints, query k8s clusters

**Cons:**
- Requires Go and real cloud credentials in CI
- Tests take 10-30 minutes and cost money
- Overkill for naming / structural validation

**Recommendation:** Use `terraform test` with mocks for unit tests (fast, free, runs in every PR). Use Terratest only for integration tests in nightly or release pipelines.

---

## Running Tests

```bash
# Run all tests for a module (from the module directory)
cd terraform/aws-eks
terraform test

# Run a specific test file
terraform test -filter=tests/aws-eks.tftest.hcl

# Run with verbose output
terraform test -verbose

# Run tests in a specific directory
terraform test -test-directory=tests/
```

### In CI

Tests are run automatically in `ci/github-actions/terraform/plan-apply.yml` before every plan. No additional workflow needed.

---

## File Naming Convention

| File | Purpose |
|------|---------|
| `<module>.tftest.hcl` | Unit tests with mock providers (no cloud credentials) |
| `<module>-integration.tftest.hcl` | Integration tests (requires real credentials, run in nightly pipeline) |

---

## Writing a Test

```hcl
# Minimal structure of a .tftest.hcl file

# Mock providers replace real cloud APIs with in-memory fakes.
# Required fields (like location, account_id) are specified in mock_data blocks.
mock_provider "azurerm" {}

# variables{} block sets input variables for this test run.
variables {
  project     = "my-project"
  environment = "test"
}

# run blocks are individual test cases.
run "resource_naming" {
  command = plan   # 'plan' = no cloud calls; 'apply' = actually create resources

  assert {
    condition     = azurerm_resource_group.main.name == "rg-my-project-test"
    error_message = "Resource group name does not follow 'rg-<project>-<environment>' convention"
  }
}
```

---

## Related Files

- [`terraform/aws-eks/`](../aws-eks/) — AWS EKS module being tested
- [`terraform/azure-aks/`](../azure-aks/) — Azure AKS module being tested
- [`ci/github-actions/terraform/plan-apply.yml`](../../ci/github-actions/terraform/plan-apply.yml) — runs tests in CI
- [`ci/github-actions/terraform/drift-detection.yml`](../../ci/github-actions/terraform/drift-detection.yml)
