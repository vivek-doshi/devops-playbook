<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Docker Compose — Local Dev Environments

Ready-to-use compose stacks for local development.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Stacks

| Folder | Services |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|--------|---------|
| `dotnet-sqlserver/` | ASP.NET Core API + SQL Server |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `python-postgres-redis/` | Python API + PostgreSQL + Redis |
| `java-postgres/` | Spring Boot API + PostgreSQL (+ optional pgAdmin) |
| `microservices-example/` | Multiple services with shared network |
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `_templates/` | Annotated base template with all common patterns |

## Usage

<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
# Start a stack
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
docker compose up -d

# Watch logs
docker compose logs -f

# Stop and remove volumes
docker compose down -v
```
