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
FROM golang:1.22-alpine AS build
WORKDIR /app

# Install CA certificates for HTTPS calls and timezone data
RUN apk add --no-cache ca-certificates tzdata

# Download dependencies first for better layer caching
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source and build a statically-linked binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server                               # <-- CHANGE THIS: path to your main package

# ── Stage 2: Runtime (distroless — no shell, no package manager) ─────────────
FROM gcr.io/distroless/static-debian12 AS runtime

# Import CA certs and timezone data from build stage
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary
COPY --from=build /app/server /server

# Run as non-root (distroless uses UID 65534 = nonroot)
USER nonroot:nonroot

EXPOSE 8080                                    # <-- CHANGE THIS: your port

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/server", "healthcheck"]               # <-- CHANGE THIS: or remove if using K8s probes

ENTRYPOINT ["/server"]
