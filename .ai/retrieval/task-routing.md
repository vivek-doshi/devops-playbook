# Task Routing

Routes user intent to the minimum correct repository domain.

## Primary Routing

- "Containerize app" -> docker/ and compose/.
- "Set up CI" -> ci/<platform>/ and ci/.../_shared.
- "Deploy to cloud" -> cd/targets/<cloud>/ and terraform/<cloud-target>/.
- "Deploy to Kubernetes" -> cd/kubernetes/, cd/helm/, cd/gitops/.
- "Provision infrastructure" -> terraform/ (or cd/pulumi/ when explicitly requested).
- "Add security checks" -> security/ and policy/.
- "Incident response" -> secops/runbooks/ and docs/runbooks/.
- "Observability and alerting" -> observability/ and notifications/.
- "Cost control/FinOps" -> finops/.

## Secondary Routing

- If request is architecture/choice oriented -> docs/ARCHITECTURE_DECISION_GUIDE.md first.
- If request asks "where do I start" -> docs/golden-paths/ first.
- If request mixes domains (for example CI + Terraform + security), route to:
  1. golden path
  2. target domain files
  3. enforcement files (security/policy/finops)

## Conflict Resolution

When multiple valid routes exist:

1. Prefer simpler golden path.
2. Prefer production-grade templates over demo examples.
3. Prefer reusable/shared templates.
4. Prefer cloud target explicitly named by the user.
5. If no cloud named, default to cloud-agnostic guidance and list supported targets.
