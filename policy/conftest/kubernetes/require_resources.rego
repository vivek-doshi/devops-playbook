# require_resources.rego
# Deny Deployment containers that are missing CPU or memory requests/limits.
# Without resource constraints the Kubernetes scheduler cannot make accurate
# placement decisions, and a runaway process can starve neighbouring workloads.
package main

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_deployment_containers(input_obj) := containers if {
	input_obj.kind == "Deployment"
	containers := input_obj.spec.template.spec.containers
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

deny contains msg if {
	some container in _deployment_containers(input)
	not container.resources.requests.cpu
	msg := sprintf(
		"Deployment/%s: container %q is missing resources.requests.cpu",
		[input.metadata.name, container.name],
	)
}

deny contains msg if {
	some container in _deployment_containers(input)
	not container.resources.requests.memory
	msg := sprintf(
		"Deployment/%s: container %q is missing resources.requests.memory",
		[input.metadata.name, container.name],
	)
}

deny contains msg if {
	some container in _deployment_containers(input)
	not container.resources.limits.cpu
	msg := sprintf(
		"Deployment/%s: container %q is missing resources.limits.cpu",
		[input.metadata.name, container.name],
	)
}

deny contains msg if {
	some container in _deployment_containers(input)
	not container.resources.limits.memory
	msg := sprintf(
		"Deployment/%s: container %q is missing resources.limits.memory",
		[input.metadata.name, container.name],
	)
}
