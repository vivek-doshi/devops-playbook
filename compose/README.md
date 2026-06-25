# Docker Compose Local Stacks

This folder contains ready-to-run Docker Compose environments for local development.

## Purpose

Use `compose/` when you need fast local feedback with realistic service dependencies.

## What's Inside

- `dotnet-sqlserver/`: .NET API with SQL Server.
- `python-postgres-redis/`: Python service with PostgreSQL and Redis.
- `java-postgres/`: Java service with PostgreSQL.
- `microservices-example/`: Multi-service composition pattern.
- `_templates/`: Base annotated compose template.

## Use This Component Alone

- Run local app dependencies without provisioning cloud infrastructure.
- Validate containerized behavior before CI/CD integration.

## Use This Component With Others

- With `docker/`: Build images used by compose services.
- With `local-dev/`: Transition from local containers to local Kubernetes.
- With `ci/`: Mirror startup checks in integration tests.

## Quick Start

```bash
cd compose/python-postgres-redis
docker compose up -d
docker compose logs -f
docker compose down -v
```
