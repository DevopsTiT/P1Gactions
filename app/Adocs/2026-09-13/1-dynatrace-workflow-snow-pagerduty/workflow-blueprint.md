# Workflow blueprint (builder checklist)

## Workflow A — Create (Problem ACTIVE)

1. Trigger: Problem / Active / severity >= Error (tune filters)
2. Task `prepare` — JavaScript — map app, P3/P4, groups, L1-3, runbook, dedup_key
3. Task `snow_create` — ServiceNow **Create Incident** (depends on prepare)
4. Task `pd_trigger` — HTTP POST `https://events.pagerduty.com/v2/enqueue` (depends on prepare, **parallel** with snow_create)
5. Task `snow_comment` — ServiceNow **Comment on an incident** — attach PD dedup_key + link (depends on snow_create + pd_trigger)
6. Optional: notify Slack/Teams with INC + PD + Problem URL

## Workflow B — Close (Problem CLOSED)

1. Trigger: Problem / Closed
2. Task `find_inc` — ServiceNow **Search incidents** by correlation_id = Problem ID
3. Task `snow_resolve` — **Resolve incident**
4. Task `pd_resolve` — HTTP resolve with same `dedup_key`

## ServiceNow Create Incident fields to set

- Connection: your SNOW connector
- Correlation ID: Problem ID
- Caller: Dynatrace integration user
- Category / Subcategory: org standard
- Impact / Urgency: from prepare (P3/P4)
- Assignment Group: from prepare map
- Configuration item / business service: from prepare
- Short description: `[Dynatrace] {title} — {app}`
- Description: DT link, app, L1/L2/L3, runbook
