# Alert triage

Use this runbook for platform alerts that do not have a service-specific procedure.

1. Acknowledge the alert and identify its namespace, workload, and owner from the labels.
2. Check recent deployments, Kubernetes events, and the affected workload's logs.
3. Restore service safely: roll back through the protected GitOps promotion path, scale only when capacity is the cause, and do not bypass policy controls.
4. Escalate to the service owner when the alert exceeds its severity response target.
5. Record the trigger, mitigation, and follow-up action in the incident ticket. Replace this generic runbook with a service-specific one once the alert is owned.
