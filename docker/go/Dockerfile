# syntax=docker/dockerfile:1
# ============================================================
# TEMPLATE: Dockerfile — Go API / Service
# WHEN TO USE: Any Go application (API, CLI, worker)
# PREREQUISITES: go.mod and go.sum in project root
# SECRETS NEEDED: None
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: docker/go/.dockerignore
# MATURITY: Stable
# ============================================================

# ── Stage 1: Build ───────────────────────────────────────────────────────────
# Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
FROM golang:1.24-alpine AS build
# Note 2: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
WORKDIR /app

# Install CA certificates for HTTPS calls and timezone data
# Note 3: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN apk add --no-cache ca-certificates tzdata

# Download dependencies first for better layer caching
# Note 4: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY go.mod go.sum ./
# Note 5: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN go mod download && go mod verify

# Copy source and build a statically-linked binary
# Note 6: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY . .
# Note 7: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server                               # <-- CHANGE THIS: path to your main package

# ── Stage 2: Runtime (distroless — no shell, no package manager) ─────────────
# Note 11: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
FROM gcr.io/distroless/static-debian12 AS runtime

# Import CA certs and timezone data from build stage
# Note 12: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# Note 13: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed.
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary
COPY --from=build /app/server /server

# Run as non-root (distroless uses UID 65534 = nonroot)
USER nonroot:nonroot

# <-- CHANGE THIS: your port
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/server", "healthcheck"]               # <-- CHANGE THIS: or remove if using K8s probes

ENTRYPOINT ["/server"]
