# Conventional Commits & Release Management

## Why Conventional Commits?

Two tools in this repo — `release-please` and `semantic-release` — parse commit messages to
determine the next version and auto-generate changelogs. Both require commits to follow the
[Conventional Commits 1.0.0](https://www.conventionalcommits.org/) specification.

Without this contract your release automation silently produces wrong version bumps.

---

## The format

```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

### Types and their version impact

| Type | SemVer bump | Example |
|------|-------------|---------|
| `feat` | **minor** (0.x.0) | `feat(auth): add OAuth2 login` |
| `fix` | **patch** (0.0.x) | `fix(db): handle null cursor on retry` |
| `feat!` or `BREAKING CHANGE:` footer | **major** (x.0.0) | `feat!: remove /v1 API endpoints` |
| `perf` | patch | `perf(cache): use LRU eviction` |
| `refactor` | none | `refactor(user): extract validation logic` |
| `docs` | none | `docs: add ADR for retry strategy` |
| `test` | none | `test: add integration tests for payment flow` |
| `chore` | none | `chore(deps): bump golang.org/x/net to v0.25` |
| `ci` | none | `ci: add SLSA provenance step` |
| `build` | none | `build: switch to Buildx cache` |
| `style` | none | `style: run gofmt` |
| `revert` | patch | `revert: feat(auth): add OAuth2 login` |

### Scopes

Scopes are optional but recommended in monorepos. Match them to your service/package names:

```
feat(api): ...
feat(worker): ...
feat(frontend): ...
fix(payments): ...
```

### Breaking changes — two ways to declare

```
feat!: remove /v1 API endpoints
```

or with a body footer:

```
feat(api): drop XML response format

BREAKING CHANGE: all responses are now JSON only.
Clients using Accept: application/xml will receive 406.
```

---

## Tooling comparison

| | `release-please` | `semantic-release` |
|---|---|---|
| **Best for** | Single-package repos, Google/open-source style | Multi-package monorepos, Node-first |
| **Creates PR?** | Yes — a "Release PR" you merge to trigger release | No — creates release directly on push |
| **Changelog** | Auto-generated in `CHANGELOG.md` | Auto-generated, pluggable |
| **Non-Node support** | Native (python, go, java, rust, etc.) | Needs plugins |
| **Config file** | `.release-please-manifest.json` + `release-please-config.json` | `.releaserc.json` |
| **Template in this repo** | `_strategies/release-please.yml` | `_strategies/semantic-release.yml` |

---

## Enforcing the convention in PRs

Use the commit enforcer workflow (`_shared/pr-conventional-commit.yml`) which runs
`commitlint` on every PR. It will fail the check if any commit in the PR violates the format.

Configure allowed types in `commitlint.config.js` at the repo root:

```js
// commitlint.config.js
// Note 1: Types listed here must match what release-please / semantic-release
// are configured to parse. Adding a custom type here that's not in your
// release config will mean it never appears in the changelog.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,        // 2 = error (not warning)
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore', 'ci', 'build', 'revert'],
    ],
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [1, 'always', 120],   // 1 = warning only
  },
};
```

---

## release-please — multi-stack config

For a monorepo with Go backend + Node frontend + Python service:

```json
// release-please-config.json
{
  "bootstrap-sha": "abc123",
  "packages": {
    "services/api": {
      "release-type": "go",
      "component": "api"
    },
    "services/worker": {
      "release-type": "python",
      "component": "worker"
    },
    "frontend": {
      "release-type": "node",
      "component": "frontend",
      "package-name": "@myorg/frontend"
    }
  }
}
```

```json
// .release-please-manifest.json  (auto-updated by release-please, commit this file)
{
  "services/api":    "1.3.2",
  "services/worker": "0.9.1",
  "frontend":        "2.1.0"
}
```

---

## Git hooks for local enforcement (optional but recommended)

Install `commitlint` + `husky` locally so developers get feedback before push:

```bash
# Node projects
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky
npx husky init
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
chmod +x .husky/commit-msg
```

```bash
# Non-Node projects — use pre-commit (Python-based, language-agnostic)
pip install pre-commit
# Add to .pre-commit-config.yaml:
#   - repo: https://github.com/compilerla/conventional-pre-commit
#     rev: v3.4.0
#     hooks:
#       - id: conventional-pre-commit
#         stages: [commit-msg]
pre-commit install --hook-type commit-msg
```

---

## Related files

- `ci/github-actions/_strategies/release-please.yml` — release-please workflow (Node default)
- `ci/github-actions/_strategies/semantic-release.yml` — semantic-release alternative
- `ci/github-actions/_shared/pr-conventional-commit.yml` — CI enforcer for commit conventions
