# =============================================================================
# CICD Reference Kit — Developer Makefile
# =============================================================================
# Run `make help` (or just `make`) to see all available targets.
#
# PREREQUISITES: bash, docker, kubectl, kind, helm, pre-commit
# Run `make check-prereqs` to verify your environment before first use.
#
# WHAT TO CHANGE:
#   IMAGE_NAME   — your container registry / image name
#   IMAGE_TAG    — default tag for local builds
#   COMPOSE_FILE — path to your docker-compose file for local dev
#   K8S_OVERLAY  — kustomize overlay to use for local deploys
# =============================================================================

# ── Configuration ─────────────────────────────────────────────────────────────
IMAGE_NAME   ?= localhost:5001/webapp             # <-- CHANGE THIS: your image name
IMAGE_TAG    ?= dev-latest                        # <-- CHANGE THIS: local build tag
COMPOSE_FILE ?= compose/python-postgres-redis/docker-compose.yml  # <-- CHANGE THIS
K8S_OVERLAY  ?= cd/kubernetes/_overlays/dev      # <-- CHANGE THIS: overlay for local deploy
CLUSTER_NAME ?= devops-playbook                  # must match local-dev/kind/kind-config.yaml

# Script runner selection for cross-platform support.
ifeq ($(OS),Windows_NT)
ENV_CHECKER_CMD    := powershell -ExecutionPolicy Bypass -File scripts/env-checker.ps1
K8S_ROLLOUT_CMD    := powershell -ExecutionPolicy Bypass -File scripts/k8s-rollout-check.ps1
TAG_RELEASE_CMD    := powershell -ExecutionPolicy Bypass -File scripts/tag-release.ps1
DOCKER_CLEANUP_CMD := powershell -ExecutionPolicy Bypass -File scripts/docker-cleanup.ps1
else
ENV_CHECKER_CMD    := bash scripts/env-checker.sh
K8S_ROLLOUT_CMD    := bash scripts/k8s-rollout-check.sh
TAG_RELEASE_CMD    := bash scripts/tag-release.sh
DOCKER_CLEANUP_CMD := bash scripts/docker-cleanup.sh
endif

# ── Formatting helpers ────────────────────────────────────────────────────────
BOLD   := \033[1m
RESET  := \033[0m
GREEN  := \033[32m
YELLOW := \033[33m
CYAN   := \033[36m

# ── Default target ─────────────────────────────────────────────────────────────
.DEFAULT_GOAL := help

.PHONY: help
## help: Show this help message (default target)
help:
	@echo ""
	@echo "  $(BOLD)CICD Reference Kit$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  $(CYAN)%-22s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "  Run $(BOLD)make check-prereqs$(RESET) if this is your first time."
	@echo ""

# =============================================================================
# LOCAL DEVELOPMENT
# =============================================================================

.PHONY: check-prereqs
## check-prereqs: Verify all required tools are installed
check-prereqs:
	@echo "$(BOLD)Checking prerequisites...$(RESET)"
	$(ENV_CHECKER_CMD)

.PHONY: dev
## dev: Start local dev environment (kind cluster + registry + ingress)
dev: check-prereqs
	@echo "$(BOLD)Starting local kind cluster...$(RESET)"
	bash local-dev/kind/setup.sh
	@echo ""
	@echo "$(GREEN)Local cluster ready. Access at http://localhost$(RESET)"
	@echo "Run $(BOLD)make deploy-dev$(RESET) to deploy the app."

.PHONY: dev-compose
## dev-compose: Start local dev stack via Docker Compose (no Kubernetes)
dev-compose:
	@echo "$(BOLD)Starting Docker Compose stack: $(COMPOSE_FILE)$(RESET)"
	docker compose -f $(COMPOSE_FILE) up --build -d
	@echo "$(GREEN)Stack running. Use 'make logs' or 'make stop' to manage it.$(RESET)"

.PHONY: stop
## stop: Stop Docker Compose stack
stop:
	docker compose -f $(COMPOSE_FILE) down

.PHONY: logs
## logs: Follow Docker Compose logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

.PHONY: teardown
## teardown: Destroy local kind cluster and registry
teardown:
	@echo "$(YELLOW)Destroying local kind cluster '$(CLUSTER_NAME)'...$(RESET)"
	bash local-dev/kind/teardown.sh

# =============================================================================
# BUILD
# =============================================================================

.PHONY: build
## build: Build the Docker image (tag: IMAGE_NAME:IMAGE_TAG)
build:
	@echo "$(BOLD)Building $(IMAGE_NAME):$(IMAGE_TAG)$(RESET)"
	docker build \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-f docker/dotnet/Dockerfile.api .   # <-- CHANGE THIS: path to your Dockerfile

.PHONY: build-push
## build-push: Build and push the image to the local kind registry
build-push: build
	@echo "$(BOLD)Pushing $(IMAGE_NAME):$(IMAGE_TAG) to local registry...$(RESET)"
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

# =============================================================================
# CODE QUALITY
# =============================================================================

.PHONY: lint
## lint: Run all pre-commit hooks against all files
lint:
	@echo "$(BOLD)Running pre-commit hooks...$(RESET)"
	pre-commit run --all-files

.PHONY: lint-staged
## lint-staged: Run pre-commit hooks against staged files only
lint-staged:
	@echo "$(BOLD)Running pre-commit hooks on staged files...$(RESET)"
	pre-commit run

.PHONY: hooks
## hooks: Install pre-commit hooks (run once after cloning)
hooks:
	pre-commit install
	pre-commit install --hook-type pre-push
	@echo "$(GREEN)Pre-commit hooks installed.$(RESET)"

.PHONY: test
## test: Run unit tests (override this target in your project)
test:
	@echo "$(YELLOW)No default test target. Add your test command here.$(RESET)"
	@echo "Examples:"
	@echo "  dotnet test"
	@echo "  pytest -v"
	@echo "  go test ./..."

# =============================================================================
# KUBERNETES — local deploy via kustomize
# =============================================================================

.PHONY: deploy-dev
## deploy-dev: Apply kustomize dev overlay to local kind cluster
deploy-dev: build-push
	@echo "$(BOLD)Deploying to local cluster (overlay: $(K8S_OVERLAY))$(RESET)"
	kubectl apply -k $(K8S_OVERLAY)
	@echo "$(BOLD)Waiting for rollout...$(RESET)"
	$(K8S_ROLLOUT_CMD)

.PHONY: deploy-staging
## deploy-staging: Apply kustomize staging overlay (requires kubeconfig for staging cluster)
deploy-staging:
	@echo "$(YELLOW)Deploying to staging — ensure your kubeconfig points to staging.$(RESET)"
	kubectl apply -k cd/kubernetes/_overlays/staging

.PHONY: k8s-status
## k8s-status: Show pod/service/ingress status in all overlays' namespaces
k8s-status:
	@echo "$(BOLD)=== Pods ===$(RESET)"
	kubectl get pods --all-namespaces -o wide
	@echo ""
	@echo "$(BOLD)=== Services ===$(RESET)"
	kubectl get svc --all-namespaces
	@echo ""
	@echo "$(BOLD)=== Ingress ===$(RESET)"
	kubectl get ingress --all-namespaces

.PHONY: rollout-status
## rollout-status: Check rollout health for all deployments
rollout-status:
	$(K8S_ROLLOUT_CMD)

# =============================================================================
# SERVICE CATALOG
# =============================================================================

.PHONY: catalog-validate
## catalog-validate: Validate all service and team catalog entries (CI gate equivalent)
catalog-validate:
	@echo "$(BOLD)Validating service catalog...$(RESET)"
	python3 catalog/scripts/validate-catalog.py --strict --skip-url-check
	@echo "$(GREEN)Catalog validation passed.$(RESET)"

.PHONY: catalog-codeowners
## catalog-codeowners: Regenerate .github/CODEOWNERS from catalog team definitions
catalog-codeowners:
	@echo "$(BOLD)Regenerating .github/CODEOWNERS from catalog/teams/...$(RESET)"
	python3 catalog/scripts/generate-codeowners.py --output .github/CODEOWNERS
	@echo "$(GREEN)CODEOWNERS updated.$(RESET)"

# =============================================================================
# FINOPS — Optimization Loop
# =============================================================================

.PHONY: finops-rightsizing
## finops-rightsizing: Analyze CPU/memory rightsizing across all namespaces
finops-rightsizing:
	@echo "$(BOLD)Running rightsizing analysis (requires Kubecost access)...$(RESET)"
	python3 finops/scripts/analyze-rightsizing.py --all-namespaces

.PHONY: finops-optimize-pr
## finops-optimize-pr: Generate a draft optimization PR with rightsizing changes
finops-optimize-pr:
	@echo "$(BOLD)Generating optimization PR draft...$(RESET)"
	python3 finops/scripts/generate-optimization-pr.py --all-namespaces

.PHONY: finops-normalize-costs
## finops-normalize-costs: Normalize cross-cloud costs to a standard unit for comparison
finops-normalize-costs:
	@echo "$(BOLD)Normalizing cloud costs...$(RESET)"
	python3 finops/scripts/normalize-cloud-costs.py

.PHONY: finops-reserved-capacity
## finops-reserved-capacity: Evaluate reserved instance / savings plan recommendations
finops-reserved-capacity:
	@echo "$(BOLD)Running reserved capacity advisor...$(RESET)"
	python3 finops/scripts/reserved-capacity-advisor.py

# =============================================================================
# SECURITY AND POLICY
# =============================================================================

.PHONY: policy-report
## policy-report: Show Kyverno policy violation report across all namespaces
policy-report:
	@echo "$(BOLD)Policy violation report:$(RESET)"
	kubectl get policyreport --all-namespaces 2>/dev/null || \
		kubectl get clusterpolicyreport --all-namespaces 2>/dev/null || \
		echo "No policy reports found. Ensure Kyverno is installed."

.PHONY: compliance-report
## compliance-report: Generate SOC 2 / CIS / ISO 27001 compliance evidence report
compliance-report:
	@echo "$(BOLD)Generating compliance report...$(RESET)"
	python3 secops/compliance/scripts/generate-compliance-report.py \
		--fail-below 80 \
		--output compliance-report.json
	@echo "$(GREEN)Report written to compliance-report.json.$(RESET)"

.PHONY: slo-validate
## slo-validate: Lint SLO YAML files and verify recording rule naming conventions
slo-validate:
	@echo "$(BOLD)Validating SLO files...$(RESET)"
	@find observability/prometheus/slos/ -name '*.yaml' -o -name '*.yml' 2>/dev/null | \
		xargs -I{} yq eval '.' {} > /dev/null && echo "$(GREEN)All SLO YAML files parse successfully.$(RESET)" || \
		(echo "$(YELLOW)SLO YAML parse errors found.$(RESET)"; exit 1)
	@echo "$(BOLD)Checking recording rule naming convention slo:<service>:<metric>:<window>...$(RESET)"
	@find observability/prometheus/recording-rules/ -name '*.yaml' -o -name '*.yml' 2>/dev/null | \
		xargs grep -h 'record:' | grep -v 'slo:' && \
		echo "$(YELLOW)WARNING: Recording rules found that do not follow slo:<service>:<metric>:<window> convention.$(RESET)" || \
		echo "$(GREEN)Recording rule naming convention check passed.$(RESET)"

# =============================================================================
# RELEASE
# =============================================================================

.PHONY: tag-release
## tag-release: Create and push a signed semver git tag (prompts for version)
tag-release:
	$(TAG_RELEASE_CMD)

# =============================================================================
# CLEANUP
# =============================================================================

.PHONY: clean
## clean: Remove local build artefacts and prune Docker resources
clean:
	@echo "$(BOLD)Cleaning Docker resources...$(RESET)"
	$(DOCKER_CLEANUP_CMD)
	@echo "$(GREEN)Clean complete.$(RESET)"

.PHONY: clean-all
## clean-all: Full cleanup including local kind cluster
clean-all: teardown clean
