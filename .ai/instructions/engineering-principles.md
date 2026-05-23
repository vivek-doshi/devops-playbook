# Engineering Principles

Most important file in the entire system.

## Core Principles

- Prefer clarity over abstraction
- Golden paths over unlimited flexibility
- Production-grade defaults only
- Security by default
- Explicit resource limits required

## How To Apply These Principles In This Repository

- Prefer composable templates from existing folders before introducing a new pattern.
- Use existing golden paths in docs/golden-paths as the default implementation route.
- Keep CI and CD definitions explicit and readable; avoid hidden control flow.
- Enforce policy and security checks in pipelines, not as optional local steps.
- Require CPU and memory requests and limits for Kubernetes workloads.
- Keep cloud-agnostic structure where practical; isolate cloud-specific details in cloud target folders.

## Decision Filter

Before merging any change, confirm:

- Is the implementation understandable by a new team member in one read?
- Does it follow an established golden path already present in this repo?
- Are runtime, security, and failure defaults safe for production?
- Are secrets, identities, and access controls configured safely by default?
- Are resource constraints and cost controls explicitly defined?

If any answer is no, revise the change before merge.
