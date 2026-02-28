# CI Pipeline Templates

Templates for each CI platform and technology combination.

## Platform Matrix

| Tech | GitHub Actions | GitLab CI | Azure Pipelines | Jenkins |
|------|---------------|-----------|-----------------|---------|
| .NET | ✅ | ✅ | ✅ | ✅ |
| Angular | ✅ | — | ✅ | — |
| React | ✅ | — | — | — |
| Python | ✅ | ✅ | ✅ | ✅ |
| Java | ✅ | — | — | — |

## Choosing a Platform

- **GitHub Actions**: Best for repos hosted on GitHub; generous free tier
- **GitLab CI**: Best native option for GitLab repos; powerful include system
- **Azure Pipelines**: Best for teams in the Microsoft ecosystem; tight AKS/ACR integration
- **Jenkins**: When you need full control or have on-premise requirements

## Shared Patterns

- [`github-actions/_shared/`](github-actions/_shared/) — Reusable GitHub Actions workflows
- [`gitlab-ci/_includes/`](gitlab-ci/_includes/) — GitLab CI include templates
- [`azure-pipelines/_templates/`](azure-pipelines/_templates/) — Azure YAML extends templates
