<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# CI Pipeline Templates

Templates for each CI platform and technology combination.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Platform Matrix

| Tech | GitHub Actions | GitLab CI | Azure Pipelines | Jenkins |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|------|---------------|-----------|-----------------|---------|
| .NET | ✅ | ✅ | ✅ | ✅ |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Angular | ✅ | — | ✅ | — |
| React | ✅ | — | — | — |
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Python | ✅ | ✅ | ✅ | ✅ |
| Java | ✅ | — | — | — |

<!-- Note 6: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Choosing a Platform

- **GitHub Actions**: Best for repos hosted on GitHub; generous free tier
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **GitLab CI**: Best native option for GitLab repos; powerful include system
- **Azure Pipelines**: Best for teams in the Microsoft ecosystem; tight AKS/ACR integration
- **Jenkins**: When you need full control or have on-premise requirements

## Shared Patterns

- [`github-actions/_shared/`](github-actions/_shared/) — Reusable GitHub Actions workflows
- [`gitlab-ci/_includes/`](gitlab-ci/_includes/) — GitLab CI include templates
- [`azure-pipelines/_templates/`](azure-pipelines/_templates/) — Azure YAML extends templates
