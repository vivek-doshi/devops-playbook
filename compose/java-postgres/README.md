# Spring Boot + PostgreSQL Compose Stack

Local development stack for a Spring Boot application backed by PostgreSQL.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Base stack with `api` and `postgres` |
| `docker-compose.debug.yml` | Optional override that adds `pgadmin` |
| `.env.example` | Required environment variable template |

## Quick Start

```bash
cp .env.example .env
docker compose -f docker-compose.yml up --build
```

Open the application at `http://localhost:8080`.

If your app exposes Spring Boot Actuator, health should be available at:

```text
http://localhost:8080/actuator/health
```

## Start With pgAdmin

```bash
cp .env.example .env
docker compose -f docker-compose.yml -f docker-compose.debug.yml up --build
```

Open pgAdmin at `http://localhost:5050`.

Default login values from `.env.example`:

| Setting | Value |
|---------|-------|
| Email | `admin@example.com` |
| Password | `admin123` |

To register the bundled PostgreSQL server in pgAdmin:

| Field | Value |
|-------|-------|
| Host name/address | `postgres` |
| Port | `5432` |
| Maintenance database | value of `POSTGRES_DB` |
| Username | value of `POSTGRES_USER` |
| Password | value of `POSTGRES_PASSWORD` |

## Notes

- The API container builds from `docker/java/Dockerfile.gradle` but runs the Gradle `bootRun` task for local iteration.
- `../../src/main` is bind-mounted into `/app/src/main` so source changes are visible inside the container.
- The datasource URL targets the `postgres` service on the shared `app-net` network.

## Troubleshooting

- If `api` fails immediately with a Gradle or build file error, verify your application repository root contains `build.gradle`, `settings.gradle`, and `src/` because the compose build context is the repo root.
- If source changes are not reflected, confirm your project code actually lives under `src/main`. If not, update the bind mount in `docker-compose.yml`.
- If database login fails, keep `SPRING_DATASOURCE_USERNAME` and `SPRING_DATASOURCE_PASSWORD` aligned with `POSTGRES_USER` and `POSTGRES_PASSWORD` in `.env`.
- If pgAdmin starts but cannot connect, use `postgres` as the hostname instead of `localhost` because pgAdmin runs inside the compose network.
- If port binding fails, check whether `8080`, `5432`, or `5050` are already in use on your machine and change the host-side port mapping if needed.
- If the healthcheck stays unhealthy, verify your app exposes `/actuator/health` and that the runtime image still includes `wget`.

## Stop The Stack

```bash
docker compose -f docker-compose.yml -f docker-compose.debug.yml down
```

To also remove the PostgreSQL data volume:

```bash
docker compose -f docker-compose.yml -f docker-compose.debug.yml down -v
```