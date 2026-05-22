# Coding Standards

Language-independent standards for all templates, scripts, infrastructure, and docs in this repository.

## Baseline Standards

- Prefer reusable templates
- Avoid hardcoded environments
- Use descriptive naming

## Additional Required Standards

- Keep changes minimal and targeted; avoid broad refactors in template repositories.
- Use deterministic, reproducible tooling versions in pipelines and build steps.
- Keep files easy to scan: clear section ordering, direct labels, consistent naming.
- Favor explicit configuration over magic defaults hidden in scripts.
- Do not duplicate logic across CI systems; mirror intent using each platform's native syntax.

## Naming

- Use lowercase-kebab-case for directories and file names unless ecosystem conventions require otherwise.
- Use names that expose intent, scope, and runtime target.
- Include cloud or platform qualifiers where behavior differs.

## Environment Strategy

- Parameterize environment values through variables, overlays, values files, or pipeline inputs.
- Keep dev, staging, and production behavior aligned except where risk controls require differences.
- Do not embed secrets or account identifiers directly in templates.

## Reuse And Composition

- Reuse shared workflow patterns where available.
- Prefer extending base templates in docker/_base, compose/_templates, and cd/kubernetes/_base.
- Document every new pattern with when-to-use guidance.
