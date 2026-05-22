# File Selection Guide

How to pick the right files quickly and safely.

## Selection Heuristics

- Start broad, then narrow:
  1. repo-level docs
  2. domain-level README
  3. target-specific templates
- Prefer paths that include explicit platform and workload type.
- Favor files used in golden paths over isolated examples.
- Prefer policy-enforced templates over unconstrained samples.

## By Specificity

- Highest specificity: target + stack + environment.
- Medium specificity: target + stack.
- Low specificity: generic base templates and docs.

Use highest specificity available that still matches user intent.

## Anti-Patterns

- Do not start directly in deep target folders without reading the decision guide.
- Do not mix deployment targets in one answer unless user asks for comparison.
- Do not ignore guardrail files (security, policy, finops) in production scenarios.

## Minimal Retrieval Set

For most implementation tasks, retrieve:

1. one architecture or golden-path document
2. one stack template
3. one CI template
4. one deployment target template
5. one guardrail file (security/policy/finops)
