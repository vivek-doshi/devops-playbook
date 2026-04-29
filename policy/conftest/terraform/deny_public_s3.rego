# deny_public_s3.rego
# Deny aws_s3_bucket resources that expose data publicly via a permissive ACL.
# "public-read" and "public-read-write" make bucket contents visible or
# writable by anyone on the internet; use bucket policies with explicit
# IAM principals instead.
#
# Tested against Terraform plan JSON (conftest test <planfile>.json).
package main

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_public_acls := {"public-read", "public-read-write"}

# Walk the Terraform plan's resource_changes to find aws_s3_bucket resources.
_s3_resource_changes[resource] if {
	some resource in input.resource_changes
	resource.type == "aws_s3_bucket"
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

deny contains msg if {
	some resource in _s3_resource_changes
	acl := resource.change.after.acl
	_public_acls[acl]
	msg := sprintf(
		"aws_s3_bucket.%s: ACL is set to %q — public ACLs expose bucket contents to the internet; use bucket policies with explicit IAM principals instead",
		[resource.name, acl],
	)
}
