# Service Catalog

This directory is a Git-native service catalog.

One YAML file per service is registered in `catalog/services/`.
The catalog is the authoritative source for:

- service ownership
- on-call routing
- runbook location
- SLO target metadata
- FinOps cost center mapping

---

## Why Git, Not A Portal

This catalog lives in the same repository as deployment manifests, alert rules, and runbooks.
That means ownership and runtime changes happen in the same pull request as service changes.
A separate portal usually drifts from reality because teams must update two systems. In this model,
service metadata is updated where engineers already work, so inventory and ownership stay current.

---

## How To Find Information

Find a service:

```bash
grep -r "name: <service-name>" catalog/services/
```

Find all services owned by a team:

```bash
grep -r "owner: <team-name>" catalog/services/
```

Find who is on call for a namespace:

```bash
cat catalog/services/<service>.yaml | grep oncall
```

---

## Backstage Migration Path

When the organization reaches around 50 services, migrate to Backstage Software Catalog using the same catalog YAML data. The schema in `catalog/services/` is intentionally close to Backstage component metadata so migration is a one-time conversion step using `catalog/scripts/migrate-to-backstage.py`, not a redesign.

---

## Compliance

This catalog provides evidence for:

- SOC 2 CC1.2: ownership and responsibility definition
- SOC 2 CC2.1: asset inventory

Reference:

- `secops/compliance/control-library/soc2-controls.yaml`
