# Sep 24 Open And Close Enrich Only

Mirror of CursorFiles `Daily Files/2026-09-28/6-sep24-open-close-enrich-only/6-sep24-open-close-enrich-only.md` (the full version, with the example notes and common problems, is there).

## Decision tree

```
Ticket INC30339599 shows blanks
 Environment empty       → OPEN now sends u_environment (env tag, default Production)
 Business service empty  → OPEN now sends business_service = EIP (or snow-service tag)
 Category / Subcategory  → OPEN now sends them (title keyword, then severity, then default)
 Impact                  → already sent; now sent as the SILVA label (3 - Medium etc.)
 Assignment group empty  → OPEN now sends L1 group; production outage goes to L2
 No customer notes       → OPEN now sends comments block: cause, links, service, dashboard, application, DT link
 Still blank after import? → read notFilled in post-silva-incident-http result → fix that label
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Only the enrichment. Tasks, positions, parallel posting, sync keys, trigger and error handling match Sep 24. |
| Which tasks changed? | OPEN: all three. CLOSE: `prepare-close-ids` and `resolve-silva-incident-http`. |
| Which task did not change? | CLOSE `resolve-pagerduty`. |
| Any new task? | No. |
| What must I fill? | `__EIP_L2_GROUP__`, `__EIP_L3_GROUP__`, `__EIP_DASHBOARD_URL__`, `__PD_SERVICE_URL__`, plus password and routing key. |

## Requirement to change map

| Requirement | Where it is now | Source of the value |
|---|---|---|
| Business service EIP | OPEN `business_service` | `snow-service` tag, else "EIP" |
| Category | OPEN `category` | Title keyword, else severity map, else "Monitoring" |
| Subcategory | OPEN `subcategory` | Same rule as category |
| Impact | OPEN `impact` and `urgency` | Sep 24 severity rule, sent as label |
| Assignment group L1 L2 L3 | OPEN `assignment_group` | L1 by default; production outage goes to L2; notes show the full path |
| Environment | OPEN `u_environment` | `env` tag, else "Production" |
| Notes: cause | `comments` | Title, root cause entity, up to 3 evidence items |
| Notes: links | `comments` | Dynatrace, PagerDuty service with dedup key, dashboard |
| Notes: service | `comments` | Business service, environment, affected entity, zone |
| Notes: dashboard | `comments` | `dashboard` tag, else `DASHBOARD_URL` |
| Notes: application EIP | `comments` | `app` tag, else "EIP" |
| Notes: DT link | `comments` and `description` | Event URL, else built from tenant URL |

## Values to confirm with SILVA

| Item | Why |
|---|---|
| Impact labels | Only "3 - Medium" is confirmed by the screenshot. |
| Category labels | Must match SILVA's choice list exactly. |
| "EIP" service name | Must match a business service record. |
| L2 and L3 group names | Must match active groups. |
| `u_environment` column | Assumed name. |

## Data flow map

```
OPEN:  Problem ACTIVE → prepare-payload (event + Problems API → fields + customer notes)
                          ├─► post-silva-incident-http (all fields + comments)  ┐ same time
                          └─► trigger-pagerduty (same details)                  ┘
CLOSE: Problem CLOSED → prepare-close-ids (duration, cause, notes)
                          ├─► resolve-silva-incident-http (state 6 + close_notes + comments) ┐
                          └─► resolve-pagerduty (unchanged)                                  ┘
```

## Related files

| File | What it is |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | Updated OPEN |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | Updated CLOSE |
| `6.sh` | Diff commands and SILVA label checks |
