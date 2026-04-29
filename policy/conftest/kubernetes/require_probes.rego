# require_probes.rego
# Deny Deployment containers that are missing liveness or readiness probes
# when the Deployment runs more than one replica. Single-replica workloads
# are exempt because a failed probe would cause immediate downtime with no
# benefit from automatic restarts; multi-replica workloads can tolerate a
# pod being temporarily removed from the load-balancer or restarted.
package main

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_multi_replica_deployment(input_obj) if {
	input_obj.kind == "Deployment"
	input_obj.spec.replicas > 1
}

_deployment_containers(input_obj) := containers if {
	input_obj.kind == "Deployment"
	containers := input_obj.spec.template.spec.containers
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

deny contains msg if {
	_multi_replica_deployment(input)
	some container in _deployment_containers(input)
	not container.livenessProbe
	msg := sprintf(
		"Deployment/%s (replicas=%d): container %q is missing livenessProbe",
		[input.metadata.name, input.spec.replicas, container.name],
	)
}

deny contains msg if {
	_multi_replica_deployment(input)
	some container in _deployment_containers(input)
	not container.readinessProbe
	msg := sprintf(
		"Deployment/%s (replicas=%d): container %q is missing readinessProbe",
		[input.metadata.name, input.spec.replicas, container.name],
	)
}
