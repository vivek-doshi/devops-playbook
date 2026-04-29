# require_labels.rego
# Deny Deployments missing required identification labels and Namespaces
# missing the environment label. Consistent labels enable cost attribution,
# network policy targeting, and observability dashboards to work correctly.
package main

import future.keywords.contains
import future.keywords.if

# ---------------------------------------------------------------------------
# Deployment rules — required: app, version
# ---------------------------------------------------------------------------

deny contains msg if {
	input.kind == "Deployment"
	not input.metadata.labels.app
	msg := sprintf(
		"Deployment/%s: missing required label 'app' — add metadata.labels.app to identify the workload",
		[input.metadata.name],
	)
}

deny contains msg if {
	input.kind == "Deployment"
	not input.metadata.labels.version
	msg := sprintf(
		"Deployment/%s: missing required label 'version' — add metadata.labels.version for traffic splitting and rollback tracking",
		[input.metadata.name],
	)
}

# ---------------------------------------------------------------------------
# Namespace rules — required: environment ∈ {dev, staging, production}
# ---------------------------------------------------------------------------

_valid_environments := {"dev", "staging", "production"}

deny contains msg if {
	input.kind == "Namespace"
	not input.metadata.labels.environment
	msg := sprintf(
		"Namespace/%s: missing required label 'environment' (must be one of: dev, staging, production)",
		[input.metadata.name],
	)
}

deny contains msg if {
	input.kind == "Namespace"
	env := input.metadata.labels.environment
	not _valid_environments[env]
	msg := sprintf(
		"Namespace/%s: label 'environment=%s' is not valid — must be one of: dev, staging, production",
		[input.metadata.name, env],
	)
}
