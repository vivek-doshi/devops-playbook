# Security Scanning Templates

Pipeline templates for security scanning across different tool categories.

## Categories

| Folder | Tools | Purpose |
|--------|-------|---------|
| `sast/` | SonarQube, Snyk, Semgrep | Static Application Security Testing |
| `container-scanning/` | Trivy, Grype | Container image vulnerability scanning |
| `secret-detection/` | Gitleaks | Detect secrets committed to Git |
| `dependency-audit/` | npm audit, pip-audit, NuGet | Dependency vulnerability audit |

## Recommended Scanning Strategy

1. **Every PR**: SAST (fast), secret detection
2. **Every merge to main**: Full SAST + container scan + dependency audit
3. **Weekly scheduled**: Full scan of all images in registry
