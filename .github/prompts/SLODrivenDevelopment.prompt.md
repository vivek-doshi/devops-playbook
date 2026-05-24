---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Generate a complete SLO-driven development implementation: SLO definition schemas, Prometheus recording rules, multi-window burn-rate alerts, Grafana dashboards, PagerDuty routing integration, quarterly review runbook, and a golden path guide — wired end-to-end into the existing observability stack.'
---

# SLO-Driven Development Implementation Generator

You are a senior SRE with deep expertise in SLO design, Prometheus recording rules, and burn-rate alerting. Your task is to generate a complete, production-grade SLO-driven development implementation for this repository.

## Mandatory context reads (do these before writing any file)

Read every file listed. Your output must be consistent with all of them.

- `observability/prometheus/slos/availability-slo.yaml` — existing SLO pattern; your new files extend this schema exactly
- `observability/prometheus/slos/latency-slo.yaml` — existing latency SLO; understand the recording rule naming convention
- `observability/prometheus/slos/README.md` — existing SLO docs; your output must be a superset
- `observability/prometheus/alerts/slo-rules.yaml` — existing burn-rate alert rules; extend, do not replace
- `observability/prometheus/alerts/pod-alerts.yaml` — mirror this file's header format and annotation structure
- `observability/prometheus/alerts/deployment-alerts.yaml` — mirror the `runbook_url` annotation pattern
- `observability/prometheus/dashboards/slo-burn-rate.json` — existing dashboard; understand what metrics it uses
- `observability/prometheus/dashboards/slo-burn-rate-configmap.yaml` — understand how dashboards are delivered to Grafana
- `observability/prometheus/values.yaml` — understand the kube-prometheus-stack Helm config
- `notifications/pagerduty-notify.yml` — understand the PagerDuty routing format; your SLO alerts must route here
- `notifications/slack-notify.yml` — understand the Slack routing format; your SLO alerts route here too
- `docs/golden-paths/kubernetes-microservice.md` — Step 12 references SLOs; your golden path is the detailed version of that step
- `docs/golden-paths/platform-onboarding.md` — Step 8 sets up Prometheus; your path assumes this is done
- `docs/golden-paths/incident-response.md` — SLO burn-rate alerts trigger the incident response path; cross-link correctly
- `docs/runbooks/template.md` — your quarterly review runbook follows this template structure
- `secops/compliance/control-library/soc2-controls.yaml` — CC7.2 and CC7.4 require monitoring evidence; your SLOs provide this
- `.ai/instructions/engineering-principles.md` — apply all principles
- `.ai/context/terminology.md` — use canonical terms

## What you are building

A complete SLO-driven development system with five layers:

1. **SLO definition schema** — a standardized YAML schema teams use to define their SLOs
2. **Prometheus recording rules** — the multi-window burn-rate rules that power alerting
3. **Alert rules** — fast/slow burn-rate alerts with correct severity and routing
4. **Grafana dashboards** — SLO status dashboard delivered via ConfigMap
5. **Operational runbooks** — quarterly SLO review process and SLO breach response

## SLO theory foundation (apply this throughout)

The Google SRE Book multi-window, multi-burn-rate approach is the only alerting model used in this repo. Understand it before writing any alert rule:

- **Error budget**: `1 - SLO_target`. For 99.9% availability, error budget = 0.1% of requests can fail.
- **Burn rate**: how fast the error budget is being consumed relative to normal. Burn rate 1 = consuming budget at exactly the rate that would exhaust it over the window. Burn rate 14 = consuming 14× faster.
- **Multi-window**: every alert fires on TWO windows — a short window (confirms the problem is current) and a long window (confirms it is significant). A 1-hour short window with 5-minute long window catches fast burns. A 6-hour short window with 30-minute long window catches slow burns.
- **Four alert tiers**:
  - Page immediately (SEV-1): burn rate ≥ 14.4 over 1h AND 5m → would exhaust budget in 2 hours
  - Page immediately (SEV-2): burn rate ≥ 6 over 6h AND 30m → would exhaust budget in 5 days  
  - Ticket (SEV-3): burn rate ≥ 3 over 24h AND 2h → would exhaust budget in 10 days
  - Warning only: burn rate ≥ 1 over 72h AND 6h → on track to miss SLO at month end

## Your deliverables

### 1. `observability/prometheus/slos/slo-schema.yaml`

A documented YAML schema file that teams copy and fill in to define their SLOs. This is the input to everything else — recording rules, alerts, and dashboards are generated from this schema.

**Schema structure**:

```yaml
# SLO Definition Schema
# Copy this file to observability/prometheus/slos/<your-service>-slo.yaml
# Then run: make slo-generate SERVICE=<your-service>
# This generates the recording rules and alert rules for your SLO.
#
# MATURITY: Stable
# WHEN TO USE: Any service that needs a reliability target and alerting

apiVersion: slo/v1
kind: ServiceLevelObjective
metadata:
  name: my-service-availability          # kebab-case, globally unique
  service: my-service                    # must match the Prometheus `job` label
  namespace: production                  # Kubernetes namespace
  team: platform                         # must match team label on Deployment
  owner: platform-team@example.com       # <-- CHANGE THIS: team email or PagerDuty service key
  runbook_url: https://github.com/your-org/repo/blob/main/docs/runbooks/my-service.md  # <-- CHANGE THIS

spec:
  # SLO type: availability | latency | throughput | error-rate
  type: availability

  # The reliability target. Start conservative — it is easier to tighten than to loosen.
  # 99.9% = 43.8 minutes/month downtime budget
  # 99.5% = 3.6 hours/month downtime budget  
  # 99.0% = 7.3 hours/month downtime budget
  target: 99.9

  # The window over which the SLO is measured.
  # 30d is the standard for most services.
  # Use 7d for new services while you establish the baseline.
  window: 30d

  # Good events: requests that were served successfully
  good_events:
    metric: http_requests_total
    filters:
      job: my-service                    # <-- CHANGE THIS: must match your Prometheus job label
      status_code: "2xx"                 # <-- CHANGE THIS: adjust to your success criteria
    # For latency SLOs, replace with:
    # metric: http_request_duration_seconds_bucket
    # filters:
    #   job: my-service
    #   le: "0.5"                        # requests completing within 500ms

  # Total events: all requests (good + bad)
  total_events:
    metric: http_requests_total
    filters:
      job: my-service                    # <-- CHANGE THIS

  # Alert routing overrides (optional — defaults come from the team label above)
  # alerts:
  #   critical:
  #     pagerduty_service: PXXXXXX      # <-- CHANGE THIS if this service has its own PD service
  #   warning:
  #     slack_channel: "#my-team-alerts"  # <-- CHANGE THIS

  # Annotations for compliance evidence
  compliance:
    soc2_controls: ["CC7.2", "CC7.4"]   # which controls this SLO satisfies
    review_cadence: quarterly            # quarterly | monthly
```

Add a comment block at the top explaining the three most common mistakes teams make when defining SLOs:
1. Setting the target too high (99.99% for a service that doesn't need it — creates alert fatigue)
2. Using the wrong total events metric (using only 5xx as bad events misses timeouts and 4xx errors that indicate service problems)
3. Starting with 30d window before establishing a baseline (start with 7d, then move to 30d)

### 2. `observability/prometheus/slos/my-service-availability-slo.yaml`

A complete, filled-in example of the schema above for a hypothetical `api-gateway` service. This is the file teams copy and adapt. Use realistic metric names that match the `cd/kubernetes/_base/deployment.yaml` pattern. Mark every `# <-- CHANGE THIS` field.

### 3. `observability/prometheus/slos/my-service-latency-slo.yaml`

A complete latency SLO example for the same `api-gateway` service. Latency SLOs are harder to get right — add extensive comments explaining:
- Why you use histogram buckets (`_bucket`) not summaries (`_p99`) for Prometheus SLOs
- How to choose the right `le` threshold (use the 95th percentile of your current latency, not an aspirational value)
- The difference between latency at the pod level vs the ingress level and which to use

### 4. `observability/prometheus/recording-rules/slo-burn-rates.yaml`

A PrometheusRule resource containing the multi-window burn-rate recording rules for the example service. These rules are the computational foundation — alerts reference these, dashboards graph these.

**Required recording rules** (generate for both availability and latency SLO types):

```yaml
# For each SLO, generate ALL of these recording rules:
# The naming convention is: slo:<service>:<metric>:<window>

# 1-minute error ratio (used for fast-burn detection)
- record: slo:api_gateway:error_ratio:1m
  expr: |
    sum(rate(http_requests_total{job="api-gateway", status_code=~"5.."}[1m]))
    /
    sum(rate(http_requests_total{job="api-gateway"}[1m]))

# 5-minute error ratio
- record: slo:api_gateway:error_ratio:5m
  expr: ...

# 30-minute error ratio
- record: slo:api_gateway:error_ratio:30m
  expr: ...

# 1-hour error ratio (the primary alerting window)
- record: slo:api_gateway:error_ratio:1h
  expr: ...

# 6-hour error ratio
- record: slo:api_gateway:error_ratio:6h
  expr: ...

# 24-hour error ratio
- record: slo:api_gateway:error_ratio:24h
  expr: ...

# 72-hour error ratio (warning window)
- record: slo:api_gateway:error_ratio:72h
  expr: ...

# Error budget remaining (0 to 1, where 1 = full budget, 0 = exhausted)
- record: slo:api_gateway:error_budget_remaining:30d
  expr: |
    1 - (
      sum(increase(http_requests_total{job="api-gateway", status_code=~"5.."}[30d]))
      /
      sum(increase(http_requests_total{job="api-gateway"}[30d]))
    ) / (1 - 0.999)

# Current burn rate (relative to the 30d budget)
- record: slo:api_gateway:burn_rate:1h
  expr: slo:api_gateway:error_ratio:1h / (1 - 0.999)

# Generate burn rate recording rules for all windows
```

Add a comment explaining why recording rules are required rather than computing directly in alerts: at fleet scale, computing multi-window ratios in alert expressions creates O(n) query load on the Prometheus API at every evaluation interval. Pre-computing into recording rules reduces this to O(1) lookups.

### 5. `observability/prometheus/alerts/slo-burn-rate-alerts.yaml`

A PrometheusRule resource with the four-tier multi-window burn-rate alerts. Extend the existing `observability/prometheus/alerts/slo-rules.yaml` — do not replace it. Create this as a separate file for the new service example.

**Alert structure** (generate all four tiers for the example service):

```yaml
# TIER 1: Page immediately — budget will exhaust in ~2 hours
# Fast burn: ≥ 14.4x over 1h AND 5m
- alert: SLOBurnRateCritical
  expr: |
    slo:api_gateway:burn_rate:1h >= 14.4
    AND
    slo:api_gateway:burn_rate:5m >= 14.4
  for: 2m  # Brief stabilization — 2m prevents flapping on transient spikes
  labels:
    severity: critical
    team: platform                     # Routes to PagerDuty via notifications/pagerduty-notify.yml
    slo: api-gateway-availability
  annotations:
    summary: "API Gateway burning error budget at {{ $value | humanize }}x rate"
    description: |
      Error budget will be exhausted in approximately 2 hours.
      Current error ratio: {{ $value | humanizePercentage }}.
      Error budget remaining: see slo:api_gateway:error_budget_remaining:30d metric.
    runbook_url: "https://github.com/your-org/repo/blob/main/docs/runbooks/api-gateway.md"  # <-- CHANGE THIS
    dashboard_url: "https://grafana.example.com/d/slo-api-gateway"                          # <-- CHANGE THIS

# TIER 2: Page — budget will exhaust in ~5 days
# Slow burn: ≥ 6x over 6h AND 30m
- alert: SLOBurnRateHigh
  expr: ...
  for: 15m
  labels:
    severity: critical
    ...

# TIER 3: Ticket — budget will exhaust in ~10 days
# ≥ 3x over 24h AND 2h
- alert: SLOBurnRateMedium
  expr: ...
  for: 1h
  labels:
    severity: warning
    ...

# TIER 4: Warning only — on track to miss SLO at month end
# ≥ 1x over 72h AND 6h  
- alert: SLOBurnRateLow
  expr: ...
  for: 3h
  labels:
    severity: info
    ...

# Budget exhaustion alert — fires when error budget is fully consumed
- alert: SLOErrorBudgetExhausted
  expr: slo:api_gateway:error_budget_remaining:30d <= 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "API Gateway error budget exhausted for this month"
    description: "All error budget has been consumed. Every additional error violates the SLO."
```

For each alert, add a comment explaining:
- What the burn rate means in plain English
- How long until budget exhaustion at this rate
- What action the on-call should take (link to appropriate runbook section)

### 6. Update `notifications/pagerduty-notify.yml`

Add SLO-specific routing rules. Add a new `routes` entry that:
- Routes `severity: critical` SLO alerts to the service's PagerDuty key (from the `slo` label)
- Routes `severity: warning` SLO alerts to Slack only (not PagerDuty)
- Uses the `team` label to route to the correct PagerDuty service

Add a comment: "SLO critical alerts bypass the standard team routing and go directly to the on-call rotation. This is intentional — SLO exhaustion is a user-impacting event regardless of which team's code caused it."

Add `# <-- CHANGE THIS` on every routing key with an explanation of where to find the PagerDuty service key.

### 7. `observability/prometheus/dashboards/slo-status-configmap.yaml`

A Grafana dashboard ConfigMap (mirror the exact format of `observability/prometheus/dashboards/slo-burn-rate-configmap.yaml`) for the SLO status overview.

The dashboard JSON must include these panels:
- **SLO Status** (stat panel): green/yellow/red based on error budget remaining. Green > 50%, yellow 10-50%, red < 10%.
- **Error Budget Remaining** (gauge panel): 0-100% remaining, with threshold coloring at 50% and 10%.
- **Burn Rate History** (time series): all four burn rate windows on one graph. Include a horizontal reference line at 14.4 (critical threshold) and 6 (high threshold).
- **Error Ratio** (time series): raw error ratio over time, with an SLO target reference line.
- **Good/Total Requests** (time series): absolute request counts to contextualize the ratio.
- **Error Budget Consumption This Month** (bar gauge): how much budget has been consumed in the current 30d window.

Use the `slo:api_gateway:*` recording rules as the data source for every panel — not raw metrics. This ensures the dashboard works correctly even under high query load.

### 8. `docs/runbooks/slo-breach-response.md`

An operational runbook for responding to SLO burn-rate alerts. Follows the exact format of `docs/runbooks/podcrashloobackoff.md`.

**Sections**:

**Symptoms** — what the alert looks like, which tier fired, what the burn rate value means

**Severity triage** (table):

| Alert tier | Burn rate | Time to exhaustion | Immediate action |
|---|---|---|---|
| Critical (Tier 1) | ≥ 14.4x | ~2 hours | Page, open incident channel NOW |
| High (Tier 2) | ≥ 6x | ~5 days | Page, investigate within 15 minutes |
| Medium (Tier 3) | ≥ 3x | ~10 days | Ticket, investigate within 1 hour |
| Low (Tier 4) | ≥ 1x | End of month | Review in next standup |

**Investigation steps**:
1. Check the SLO dashboard: what is the current error ratio vs the SLO target?
2. Identify which request types are failing: `http_requests_total{job="<service>", status_code=~"5.."}`
3. Correlate with recent deployments: `kubectl rollout history deployment/<name> -n <namespace>`
4. Check pod health: cross-link to `docs/runbooks/podcrashloobackoff.md`
5. Check error budget remaining: if < 10%, escalate to SEV-1 regardless of current burn rate

**Mitigation options** (parallel to `docs/golden-paths/incident-response.md` Phase 3):
- Roll back the deployment if a recent change caused the burn
- Scale up if the burn is load-related
- Disable a feature flag if the burn is isolated to a feature
- If budget < 10%: halt all non-critical deployments to this service until budget recovers

**Post-incident**: document the incident in the quarterly SLO review template

### 9. `docs/runbooks/slo-quarterly-review.md`

A structured runbook for the quarterly SLO review process.

**Purpose**: The quarterly review is not an incident response — it is a reliability planning session. Its output is either a confirmed SLO target or a revision to the target, the error budget policy, or the alerting thresholds.

**Who attends**: service team, platform engineer, one stakeholder (product or engineering manager)

**Inputs required** (with commands to generate each):
- Error budget consumption over the past quarter: `kubectl exec -n monitoring <prometheus-pod> -- promtool query instant 'slo:<service>:error_budget_remaining:30d'`
- Alert history: how many times each tier fired, and MTTR
- Incident log: incidents caused by SLO violations from `docs/golden-paths/incident-response.md`

**Agenda** (60 minutes):

1. (10 min) Review error budget consumption — did we use more or less than expected?
2. (10 min) Review alert history — were the alerts accurate (right severity, right timing)?
3. (15 min) Review incidents — what caused SLO violations and are the fixes in place?
4. (15 min) Decision: tighten, maintain, or relax the SLO target?
5. (10 min) Update error budget policy if needed

**Error budget policy** (this is the most important output — add a template):

```yaml
# docs/slo-policies/<service>-error-budget-policy.yaml
service: api-gateway
slo_target: 99.9%
error_budget_monthly_minutes: 43.8

# What we do at each budget consumption level:
policy:
  below_50_percent_remaining:
    action: normal operations, proceed with planned changes
  below_25_percent_remaining:
    action: pause non-critical feature work, prioritize reliability improvements
    owner: engineering manager
  below_10_percent_remaining:
    action: halt all deployments except rollbacks and critical fixes
    owner: engineering director approval required
  exhausted:
    action: incident response, all hands on reliability
    escalation: VP Engineering
```

**Decision criteria** (when to change the target):

- **Tighten** (e.g. 99.9% → 99.95%): if budget was consistently >80% remaining AND the service is business-critical AND the team has the capacity to maintain the higher target
- **Maintain**: default — if the budget was used meaningfully and the team responded well
- **Relax** (e.g. 99.9% → 99.5%): if the budget was exhausted every month despite effort AND the business impact of brief outages is acceptable AND the team needs the space to ship features

### 10. `docs/golden-paths/slo-driven-development.md`

A complete golden path in the exact format of `docs/golden-paths/kubernetes-microservice.md`.

**When to use this path**: any team that has a deployed service and wants to define a reliability target, get alerted when that target is at risk, and run a structured reliability review process.

**Not the right path**: reference `platform-onboarding.md` Step 8 for setting up the Prometheus stack. This path assumes Prometheus and Alertmanager are already running.

**Prerequisites table**:

| Requirement | Why | How to verify |
|---|---|---|
| Prometheus stack running | Recording rules and alerts are Prometheus resources | `kubectl get pods -n monitoring -l app=kube-prometheus-stack` |
| Your service exposes `/metrics` | SLOs require Prometheus metrics | `curl http://<service>:<port>/metrics \| grep http_requests_total` |
| Alertmanager configured | Alerts need a routing destination | `kubectl get secret alertmanager-config -n monitoring` |
| PagerDuty or Slack configured | Alert routing | `notifications/pagerduty-notify.yml` or `notifications/slack-notify.yml` |

**Flow**:
```
define SLO (schema) → write recording rules → define burn-rate alerts
→ deploy dashboard → connect alert routing → test with synthetic load
→ run first quarterly review → refine targets
```

**Steps** (numbered, with exact file references):

1. Define your SLO: copy `observability/prometheus/slos/slo-schema.yaml`, fill in the fields, save as `observability/prometheus/slos/<your-service>-slo.yaml`
2. Write the recording rules: copy `observability/prometheus/recording-rules/slo-burn-rates.yaml`, replace `api-gateway` with your service name, apply with `kubectl apply -f`
3. Write the burn-rate alerts: copy `observability/prometheus/alerts/slo-burn-rate-alerts.yaml`, replace service name, apply
4. Deploy the SLO dashboard: copy `observability/prometheus/dashboards/slo-status-configmap.yaml`, apply, verify in Grafana
5. Wire alert routing: update `notifications/pagerduty-notify.yml` with your service's PagerDuty key
6. Test the alerts: temporarily lower the SLO target to 100% to force an alert, verify it routes correctly, restore the target
7. Establish the error budget policy: create `docs/slo-policies/<service>-error-budget-policy.yaml`
8. Schedule the quarterly review: add a recurring calendar event, link to `docs/runbooks/slo-quarterly-review.md`

**SLO target selection guide** (add as a dedicated section, not just a table):

Most teams pick 99.9% by default. This is usually wrong. Guide teams through:
- What is the actual user impact of 1 minute of downtime? (Low = 99.5% is fine. High = 99.99% might be needed.)
- What is our current actual availability? (Never set the SLO target above your measured baseline — you will immediately be in violation.)
- Can our team sustain the on-call burden of a high target? (99.99% = 4.3 minutes/month budget — one slow deployment exhausts it.)

**Compliance mapping section**: explain that SOC 2 CC7.2 (monitoring of system operations) and CC7.4 (detection of security events) can be evidenced by SLO recording rules and alert history. Link to `secops/compliance/control-library/soc2-controls.yaml`.

**Guardrails table**:

| Rule | Enforced by |
|---|---|
| SLO target must not exceed measured baseline | Code review, quarterly review process |
| All four burn-rate tiers required | `slo-burn-rate-alerts.yaml` template |
| Recording rules required (no direct metric in alerts) | Alert rule review + comment in template |
| Error budget policy documented before going to production | `slo-quarterly-review.md` checklist |
| PagerDuty routing verified before first deploy | Step 6 test procedure |

### 11. Update `observability/prometheus/slos/README.md`

Rewrite to be a complete SLO reference, superseding the current content. Include:
- Link to the new golden path as the starting point
- The four burn-rate tiers as a reference table
- The naming convention for recording rules (`slo:<service>:<metric>:<window>`)
- How to list all active SLOs: `kubectl get prometheusrule -A -l slo=true`
- How to check current error budget: the promtool command
- The quarterly review cadence and link to the review runbook

### 12. Update `GETTING_STARTED.md`

Add under "📊 I need observability":

| Define reliability targets and get alerted when at risk | [`docs/golden-paths/slo-driven-development.md`](docs/golden-paths/slo-driven-development.md) |

### 13. Update `docs/golden-paths/kubernetes-microservice.md`

Step 12 currently says "copy an existing alert file." Replace that with:

"For a complete SLO implementation with burn-rate alerting, quarterly review process, and error budget policy, follow the [SLO-Driven Development golden path](slo-driven-development.md). For a quick alert setup, copy `observability/prometheus/alerts/pod-alerts.yaml` and adapt the job label."

## Style rules

- Every alert must have `runbook_url` and `dashboard_url` annotations with `# <-- CHANGE THIS` on each
- Every recording rule name must follow the `slo:<service>:<metric>:<window>` convention — document this convention with a comment in the recording rules file
- Burn-rate thresholds (14.4, 6, 3, 1) must not be changed — they are derived from the Google SRE Workbook and are correct. Add a comment citing the source.
- The `for` duration on alerts must match the tier: 2m for Tier 1, 15m for Tier 2, 1h for Tier 3, 3h for Tier 4 — these prevent flapping while preserving alerting value. Add a comment explaining why each value was chosen.
- Dashboard JSON must use the recording rule metrics, not raw metrics — add a comment in the ConfigMap explaining why
- The quarterly review runbook must be actionable in 60 minutes — no theoretical content, only concrete questions and decisions
- The error budget policy template must include all four consumption levels — a policy that only covers the exhausted state is not a policy
- Every `# <-- CHANGE THIS` must explain what to change, what the valid options are, and where to find the right value
