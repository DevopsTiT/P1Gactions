# Full OPEN Workflow With SILVA And PagerDuty

## Decision tree

```
Davis problem ACTIVE + CREATED
 │
 ├─ 1 extract-event-tags ── tags, alert fields, group candidates, environment, maintenance
 │
 ├─ 2 resolve-snow-values ── SILVA GET
 │     ├─ group: GROUP_MAP → tag (checked) → tag name → service group → CI group → default
 │     ├─ service: SERVICE_MAP → CI link → scored search → first answer by group → default
 │     └─ both missing? → DEFAULT SET (QA Platforms, Ops_Middleware_Monitoring_AXAJP, PoC / VoA / Demo)
 │
 ├─ 3 display-result ── build SNOW body + PagerDuty body + snow_form_check
 │     ├─ maintenance on? → create_incident false
 │     ├─ mandatory field missing? → create_incident false
 │     └─ otherwise → create_incident true
 │
 ├─ 4 post-silva-incident
 │     ├─ create_incident false → skipped
 │     ├─ sample event (manual Run) → skipped unless ALLOW_SAMPLE_POST
 │     ├─ open incident with same correlation_id? → exists (no new ticket)
 │     ├─ DRY_RUN → log body only
 │     └─ POST /api/now/v2/table/incident → created (number, sys_id)
 │
 └─ 5 trigger-pagerduty
       ├─ SILVA skipped → skipped
       ├─ incident already existed → skipped (unless SEND_WHEN_INCIDENT_EXISTS)
       ├─ DRY_RUN → show body only
       └─ POST events.pagerduty.com/v2/enqueue → triggered (dedup_key dt-problem-<display_id>)
```

## Short takeaway

| Question | Answer |
|---|---|
| File | `9-v6-full-open-silva-pagerduty.workflow.yaml` |
| How many tasks? | Five, in a straight line |
| Which tasks send data? | Task 4 (SILVA POST) and task 5 (PagerDuty POST) |
| How are duplicates avoided? | Task 4 looks for an open incident with the same correlation_id first |
| Can I test safely? | Yes. Manual Run uses the sample event and does not post. Or set `DRY_RUN = true`. |
| What closes the ticket? | The CLOSE workflow (2026-09-28 seq 27) finds it by correlation_id and resolves PagerDuty by the same dedup_key |

## Summary

v6 is the full OPEN workflow. The first three tasks are the v5 logic (extract, look up, build). Task 4 creates the SILVA incident only when the decision allows it and no open incident exists for the same problem. Task 5 pages PagerDuty with the incident number in the details.

## All tasks

| Task | Network | What it does | Main output |
|---|---|---|---|
| 1 extract-event-tags | Problems API only | Parse tags and alert fields | `dynatrace_alert`, `snow_inputs`, `event_properties`, `tags` |
| 2 resolve-snow-values | SILVA GET | Find group, service, offering, CI, company; default set | `snow_required`, `servicenow_enrichment`, `lookup` data |
| 3 display-result | None | Build bodies, check the form, decide | `decision`, `snow_incident_payload`, `pagerduty_payload`, `snow_form_check` |
| 4 post-silva-incident | SILVA GET + POST | Duplicate check, then create the incident | `action`, `number`, `sys_id`, `url` |
| 5 trigger-pagerduty | PagerDuty POST | Send the trigger event | `action`, `status`, `dedup_key` |

## Task 4 results

| `action` | Meaning |
|---|---|
| `skipped` | Maintenance, missing mandatory field, or sample event |
| `exists` | An open incident already has this correlation_id |
| `dry_run` | Body logged, nothing sent |
| `created` | New incident created |

If the POST fails, the task fails with the SILVA error text, so the workflow run shows red.

## Task 5 results

| `action` | Meaning |
|---|---|
| `skipped` | Task 4 skipped, or the incident already existed |
| `dry_run` | Body shown with the routing key hidden |
| `triggered` | PagerDuty accepted the event |

## Settings to check

| Task | Setting | Default | What it does |
|---|---|---|---|
| 2 | `SERVICE_MAP` | empty | Fixed business service per trigram or entity |
| 2 | `GROUP_MAP` | empty | Fixed group per trigram or entity |
| 2 | `DEFAULT_BUSINESS_SERVICE` | QA Platforms | Default service |
| 2 | `DEFAULT_GROUP` | Ops_Middleware_Monitoring_AXAJP | Default group |
| 2 | `DEFAULT_ENVIRONMENT_LABEL` | PoC / VoA / Demo | Environment for the default set |
| 3 | `SKIP_WHEN_MAINTENANCE` | true | No ticket during maintenance |
| 3 | `CATEGORY`, `SUBCATEGORY`, `IMPACT`, `URGENCY` | other, other, 4, 4 | Choice values; confirm with the INC30340215 GET |
| 4 | `DRY_RUN` | false | true = never POST |
| 4 | `ALLOW_SAMPLE_POST` | false | true = manual Run creates a real ticket |
| 5 | `DRY_RUN` | false | true = never page |
| 5 | `SEND_WHEN_INCIDENT_EXISTS` | false | true = page again for an existing incident |

## Before activating

| Step | What to do |
|---|---|
| 1 | Allowlist `silvastg.service-now.com` and `events.pagerduty.com` in External requests |
| 2 | Add scope `environment-api:problems:read` |
| 3 | Confirm the choice values and field names with `9.sh` |
| 4 | First run with `DRY_RUN = true` in tasks 4 and 5 |
| 5 | Switch `DRY_RUN` to false and activate |
| 6 | Keep the CLOSE workflow active, with the same correlation_id and dedup_key rules |

## Data flow

```
Dynatrace problem
  │
  ▼
1 extract ──► 2 SILVA GET ──► 3 build + decide
                                  │
                        create_incident?
                          ├─ no  → 4 skipped → 5 skipped
                          └─ yes
                               ▼
                      4 GET incident (correlation_id, active)
                          ├─ found → exists → 5 skipped
                          └─ none  → POST incident → number
                                         ▼
                      5 POST PagerDuty (dedup_key dt-problem-<display_id>, snow number)

Later: problem CLOSED → CLOSE workflow → GET by correlation_id → PATCH resolved → PagerDuty resolve
```

## Related files

| File | What it is |
|---|---|
| `9-v6-full-open-silva-pagerduty.workflow.yaml` | Full OPEN workflow |
| `../8-v5-default-qa-platforms-fallback/` | v5 (read-only version of tasks 1 to 3) |
| `../../2026-09-28/27-open-match-inc30339746/2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow |
| `9.sh` | Manual checks and test commands |

## Commands

See `9.sh`.
