# deny_latest_tag.rego
# Deny container images that use the :latest tag or have no tag at all.
# Pinning images to a specific digest or semver tag ensures reproducible
# deployments and prevents silent image drift between rollouts.
package main

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Collect containers from Deployment pods and bare Pods.
_containers(input_obj) := containers if {
	input_obj.kind == "Deployment"
	containers := input_obj.spec.template.spec.containers
} else := containers if {
	input_obj.kind == "Pod"
	containers := input_obj.spec.containers
}

# Return true when the image string has no tag or uses :latest.
_latest_or_untagged(image) if {
	not contains(image, ":")
}

_latest_or_untagged(image) if {
	endswith(image, ":latest")
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

deny contains msg if {
	some container in _containers(input)
	_latest_or_untagged(container.image)
	msg := sprintf(
		"%s/%s: container %q uses image %q — pin to a specific version tag or digest (not :latest or untagged)",
		[input.kind, input.metadata.name, container.name, container.image],
	)
}
