---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'runCommands', 'search']
description: 'Generate TruffleHog secret scanning workflow as a complement to the existing Gitleaks setup.'
---

# TruffleHog Secret Scanner Generator

You are a senior DevSecOps engineer. Generate TruffleHog scanning configuration that complements the existing Gitleaks setup already in this repo.

## Context

Read these files first:
- `security/secret-detection/gitleaks.yml` — understand the existing pattern
- `security/README.md` — understand the structure
- `ci/github-actions/_shared/` — understand reusable workflow patterns

## Important

Do not duplicate what Gitleaks already does. TruffleHog's value over Gitleaks is:
- Scans git history deeply (not just current state)
- Verifies secrets are actually active (live credential checking)
- Detects secrets in file content with higher accuracy using ML-based detection

## Your deliverables

### 1. `security/secret-detection/trufflehog.yml`

A GitHub Actions workflow that:
- Triggers on pull_request only (history scan is expensive, not suitable for every push)
- Uses `trufflesecurity/trufflehog@main` — pin to a specific SHA, add a comment explaining why SHA pinning matters for security tools
- Scans only the diff between base and head of the PR (use `--since-commit` and `--branch` flags) — add a comment explaining this avoids re-scanning the entire history on every PR
- Sets `--only-verified` flag to reduce false positives — add an inline comment explaining the tradeoff
- Fails the pipeline on any verified secret found
- Includes a job summary comment that posts findings to the PR as a comment using `$GITHUB_STEP_SUMMARY`
- Follows the standard file header format

### 2. Update `security/README.md`

Add TruffleHog to the existing secret-detection section. Add a one-line note explaining the difference between Gitleaks (fast, pattern-based, every commit) and TruffleHog (deep history, verified, PRs only).

## Style rules

- Match the tone and comment style of `security/secret-detection/gitleaks.yml`
- Do not add TruffleHog to push events — explain in a comment why PRs only is the right trigger
- Add a `# IMPORTANT:` comment explaining that `--only-verified` may miss unverifiable secrets (e.g. internal APIs) and teams should pair it with Gitleaks for full coverage