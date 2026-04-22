<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Security Scanning Templates

Pipeline templates for security scanning across different tool categories.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Categories

| Folder | Tools | Purpose |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|--------|-------|---------|
| `sast/` | SonarQube, Snyk, Semgrep | Static Application Security Testing |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `container-scanning/` | Trivy, Grype | Container image vulnerability scanning |
| `secret-detection/` | Gitleaks | Detect secrets committed to Git |
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `dependency-audit/` | npm audit, pip-audit, NuGet | Dependency vulnerability audit |

## Recommended Scanning Strategy

1. **Every PR**: SAST (fast), secret detection
2. **Every merge to main**: Full SAST + container scan + dependency audit
3. **Weekly scheduled**: Full scan of all images in registry
