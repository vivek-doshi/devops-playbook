# Docker Templates

This folder contains production-oriented Dockerfile templates by technology stack.

## Purpose

Use `docker/` to standardize image build patterns with secure defaults and predictable runtime behavior.

## What's Inside

- `dotnet/`, `angular/`, `react/`, `python/`, `node/`, `java/`, `go/`, `ruby/`
- `_base/`: shared and educational base patterns, including hardened examples

## Use This Component Alone

- Containerize one service quickly with stack-specific best practices.
- Reuse multi-stage and non-root defaults without redesigning build logic.

## Use This Component With Others

- With `ci/`: Build and publish artifacts in pipelines.
- With `cd/`: Deploy images to Kubernetes, serverless, or platform targets.
- With `ci-security/`: Scan images before promotion.
- With `local-dev/` and `compose/`: Run and validate locally.

## Quick Start

1. Copy the relevant Dockerfile.
2. Copy matching `.dockerignore`.
3. Replace placeholders.
4. Build and run locally.

```bash
docker build -t my-app:dev .
docker run --rm -p 8080:8080 my-app:dev
```
