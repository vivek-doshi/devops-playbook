# Docker Templates

Dockerfile templates for each supported technology stack.

## Structure

| Folder | Content |
|--------|---------|
| `dotnet/` | ASP.NET Core API and worker Dockerfiles |
| `angular/` | Angular multi-stage build with nginx |
| `react/` | React multi-stage (prod) and dev hot-reload |
| `python/` | Flask, FastAPI, Django Dockerfiles |
| `node/` | Express and Next.js Dockerfiles |
| `java/` | Spring Boot and Gradle Dockerfiles |
| `_base/` | Teaching examples and security-hardened patterns |

## Usage

1. Copy the relevant Dockerfile to your project root
2. Copy the `.dockerignore` to your project root
3. Replace `<app-name>`, `<port>`, and other placeholders
4. Build: `docker build -t my-app .`

## Best Practices Applied

- Multi-stage builds to minimize final image size
- Non-root user in production images
- `.dockerignore` to exclude dev artifacts
- Health checks defined
- Layer caching optimized (dependencies before source code)
- Pinned base image versions

## Security Notes

See [`_base/security-hardened.Dockerfile`](_base/security-hardened.Dockerfile) for an example using:
- Distroless base images
- Non-root execution
- Read-only filesystem
- Dropped capabilities
