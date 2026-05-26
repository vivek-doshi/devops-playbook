# Session Summary — 2026-05-27 — Windows PowerShell script parity

## Request
Create PowerShell equivalents for shell scripts in scripts/ and review onboarding guidance for Windows usage.

## Changes made
- Added scripts/env-checker.ps1
  - Equivalent behavior to scripts/env-checker.sh (validates required env vars passed as arguments).
- Added scripts/docker-cleanup.ps1
  - Equivalent behavior to scripts/docker-cleanup.sh including -DryRun support.
- Added scripts/k8s-rollout-check.ps1
  - Equivalent behavior to scripts/k8s-rollout-check.sh (namespace, deployment, optional timeout).
- Added scripts/tag-release.ps1
  - Equivalent behavior to scripts/tag-release.sh (MAJOR/MINOR/PATCH bump, create and push annotated tag).
- Updated docs/guides/onboarding.md
  - Added Windows PowerShell command example for env checker.
  - Updated Windows note to clarify: full workflow still relies on bash/WSL, while scripts/ now has native PowerShell alternatives.
- Updated Makefile
  - Added OS-aware command variables so these targets use PowerShell scripts on Windows and bash scripts elsewhere:
    - check-prereqs
    - deploy-dev
    - rollout-status
    - tag-release
    - clean

## Validation
- Workspace diagnostics checked with get_errors for all updated files.
- No errors reported.

## Notes
- Local kind setup/teardown targets still run bash scripts under local-dev/kind, so full local cluster setup on Windows still requires WSL2 or Git Bash.
