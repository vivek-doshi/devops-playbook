# Teams Catalog

This directory registers teams that can own services.

Rules:

- A team entry must exist before a service can reference it in `metadata.owner`.
- Team identifiers are the source of truth for routing and ownership discovery.
- Team records are used by catalog tooling to generate CODEOWNERS and validate ownership references.

Create a team entry by copying:

- `catalog/teams/schema/team.yaml`

Save as:

- `catalog/teams/<team-name>.yaml`
