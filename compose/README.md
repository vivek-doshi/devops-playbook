# Docker Compose — Local Dev Environments

Ready-to-use compose stacks for local development.

## Stacks

| Folder | Services |
|--------|---------|
| `dotnet-sqlserver/` | ASP.NET Core API + SQL Server |
| `python-postgres-redis/` | Python API + PostgreSQL + Redis |
| `microservices-example/` | Multiple services with shared network |
| `_templates/` | Annotated base template with all common patterns |

## Usage

```bash
# Start a stack
docker compose up -d

# Watch logs
docker compose logs -f

# Stop and remove volumes
docker compose down -v
```
