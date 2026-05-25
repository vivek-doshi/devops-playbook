# Runbooks

This folder contains operational response runbooks used during incidents and reliability events.

## Existing Runbooks

- `podcrashloobackoff.md`: Kubernetes crash-loop response flow.
- `slo-breach-response.md`: Burn-rate breach triage and mitigation.
- `slo-quarterly-review.md`: Quarterly reliability governance review.
- `template.md`: Template for creating new alert runbooks.

## Authoring Standard

Each runbook should include:
1. Alert context and user impact.
2. Immediate steps (first 5 minutes).
3. Diagnosis checklist.
4. Escalation and resolution criteria.
5. Post-incident follow-up actions.

## Integration Notes

- Alert rules should reference hosted runbook URLs.
- Runbooks should link back to relevant guides, ADRs, and architecture docs.
- Keep commands concrete and environment-safe.
