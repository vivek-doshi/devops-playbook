# syntax=docker/dockerfile:1
# ============================================================
# TEMPLATE: Security-Hardened Dockerfile
# WHEN TO USE: High-security environments, compliance requirements
# PREREQUISITES: Node.js project with build script producing dist/
# SECRETS NEEDED: None
# WHAT TO CHANGE: Adapt patterns to your stack
# RELATED FILES: docker/_base/Dockerfile.multistage
# MATURITY: Stable
# ============================================================
# Patterns: distroless base, non-root user, read-only FS, dropped capabilities

FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# Use Google distroless — no shell, no package manager, minimal CVE surface
FROM gcr.io/distroless/nodejs20-debian12 AS runtime
WORKDIR /app

# Copy only what is needed
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules

# Distroless images run as nonroot (uid 65532) by default
USER nonroot

EXPOSE 3000

# Note: when using distroless, use exec JSON array form only
CMD ["dist/index.js"]

# ── Runtime hardening (apply via docker run or K8s securityContext) ───────────
# docker run --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges ...
#
# Kubernetes securityContext equivalent:
# securityContext:
#   readOnlyRootFilesystem: true
#   allowPrivilegeEscalation: false
#   runAsNonRoot: true
#   capabilities:
#     drop: ["ALL"]
