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
	bash scripts/env-checker.sh

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
	bash scripts/k8s-rollout-check.sh

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
	bash scripts/k8s-rollout-check.sh

# =============================================================================
# RELEASE
# =============================================================================

.PHONY: tag-release
## tag-release: Create and push a signed semver git tag (prompts for version)
tag-release:
	bash scripts/tag-release.sh

# =============================================================================
# CLEANUP
# =============================================================================

.PHONY: clean
## clean: Remove local build artefacts and prune Docker resources
clean:
	@echo "$(BOLD)Cleaning Docker resources...$(RESET)"
	bash scripts/docker-cleanup.sh
	@echo "$(GREEN)Clean complete.$(RESET)"

.PHONY: clean-all
## clean-all: Full cleanup including local kind cluster
clean-all: teardown clean
