## Change Type

<!-- Mark all that apply with an x: [x] -->
- [ ] `feat` — new template, Dockerfile, pipeline, or K8s pattern
- [ ] `fix` — correction to existing file (bug, typo, broken config)
- [ ] `docs` — documentation only
- [ ] `chore` — tooling, dependencies, repo config
- [ ] `refactor` — restructure without functional change
- [ ] `security` — security hardening or vulnerability fix
- [ ] `infra` — Terraform / IaC change

---

## Description

<!-- What does this change do? Why? One or two sentences. -->

---

## Testing Done

<!-- How did you verify the change works? -->
- [ ] Ran `make lint` — pre-commit hooks pass
- [ ] Validated YAML/HCL syntax locally
- [ ] Tested with `make deploy-dev` on a local kind cluster _(Kubernetes changes)_
- [ ] Ran `terraform validate` + `terraform plan` _(Terraform changes)_
- [ ] Ran `docker build` successfully _(Dockerfile changes)_
- [ ] N/A — documentation or comment-only change

---

## Checklist

- [ ] Commit message follows [Conventional Commits](../docs/guides/conventional-commits.md) (`type(scope): description`)
- [ ] All `# <-- CHANGE THIS` markers replaced or documented as intentional placeholders
- [ ] Related docs updated (README, guide, GETTING_STARTED.md)
- [ ] No secrets, credentials, or real hostnames committed
- [ ] CODEOWNERS-required reviewers added _(if applicable)_

---

## Related Issues / PRs

<!-- Closes #<issue-number> -->
<!-- Related to #<pr-number> -->
