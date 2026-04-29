# deny_privileged.rego
# Deny containers that run with elevated Linux privileges.
# Privileged containers can escape the container boundary and compromise
# the host node. These checks mirror the Kubernetes Restricted Pod
# Security Standard (https://kubernetes.io/docs/concepts/security/pod-security-standards/).
package main

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Collect containers (and initContainers) from Deployments and bare Pods.
_all_containers(input_obj) := containers if {
	input_obj.kind == "Deployment"
	pod_spec := input_obj.spec.template.spec
	containers := array.concat(
		object.get(pod_spec, "containers", []),
		object.get(pod_spec, "initContainers", []),
	)
}

_all_containers(input_obj) := containers if {
	input_obj.kind == "Pod"
	containers := array.concat(
		object.get(input_obj.spec, "containers", []),
		object.get(input_obj.spec, "initContainers", []),
	)
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

# 1. securityContext.privileged must not be true.
deny contains msg if {
	some container in _all_containers(input)
	container.securityContext.privileged == true
	msg := sprintf(
		"%s/%s: container %q has securityContext.privileged=true — remove or set to false",
		[input.kind, input.metadata.name, container.name],
	)
}

# 2. allowPrivilegeEscalation must not be true.
deny contains msg if {
	some container in _all_containers(input)
	container.securityContext.allowPrivilegeEscalation == true
	msg := sprintf(
		"%s/%s: container %q has securityContext.allowPrivilegeEscalation=true — set to false",
		[input.kind, input.metadata.name, container.name],
	)
}

# 3. runAsNonRoot must be explicitly set to true (i.e. runAsRoot must be false).
deny contains msg if {
	some container in _all_containers(input)
	not container.securityContext.runAsNonRoot == true
	msg := sprintf(
		"%s/%s: container %q does not set securityContext.runAsNonRoot=true — add it to prevent running as root",
		[input.kind, input.metadata.name, container.name],
	)
}
