<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Docker Templates

Dockerfile templates for each supported technology stack.

## Structure

<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Folder | Content |
|--------|---------|
| `dotnet/` | ASP.NET Core API and worker Dockerfiles |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `angular/` | Angular multi-stage build with nginx |
| `react/` | React multi-stage (prod) and dev hot-reload |
| `python/` | Flask, FastAPI, Django Dockerfiles |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `node/` | Express and Next.js Dockerfiles |
| `java/` | Spring Boot and Gradle Dockerfiles |
| `_base/` | Teaching examples and security-hardened patterns |

<!-- Note 5: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Usage

1. Copy the relevant Dockerfile to your project root
2. Copy the `.dockerignore` to your project root
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
3. Replace `<app-name>`, `<port>`, and other placeholders
4. Build: `docker build -t my-app .`

## Best Practices Applied

<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Multi-stage builds to minimize final image size
- Non-root user in production images
- `.dockerignore` to exclude dev artifacts
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Health checks defined
- Layer caching optimized (dependencies before source code)
- Pinned base image versions

<!-- Note 9: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Security Notes

See [`_base/security-hardened.Dockerfile`](_base/security-hardened.Dockerfile) for an example using:
- Distroless base images
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Non-root execution
- Read-only filesystem
- Dropped capabilities
