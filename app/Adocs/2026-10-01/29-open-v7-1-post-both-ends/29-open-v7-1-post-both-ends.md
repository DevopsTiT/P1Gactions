# OPEN v7.1 Post Both Ends

## Decision tree

```
Davis problem CREATED
  1 extract-event-tags → 2 resolve-snow-values → 3 build-payload   (identical to PREVIEW v7.1)
  decision.create_incident false (maintenance or missing field)? → 4a and 4b both return "skipped"
  sample event (Run button) and ALLOW_SAMPLE_POST false?         → both "skipped"
  4a post-silva-incident
    open incident with same correlation_id? → "exists" (no new ticket)
    DRY_RUN true?                          → "dry_run" (logs body)
    else POST /api/now/v2/table/incident    → "created" + INC number
  4b trigger-pagerduty (same time as 4a)
    DRY_RUN true? → "dry_run"
    else POST events.pagerduty.com/v2/enqueue → "triggered" (same dedup_key = one PD incident)
```

## Short takeaway

| Question | Answer |
|---|---|
| File | `29-open-v7-1-post-both-ends.workflow.yaml` |
| Sends to | SILVA stg incident (POST) and PagerDuty Events API v2 (POST). |
| Parallel? | Yes. Both send tasks start after build-payload. |
| Same logic as the tested PREVIEW? | Yes. Tasks 1 to 3 were compared and are identical to PREVIEW v7.1. |
| Safety switches | DRY_RUN, ALLOW_SAMPLE_POST, USE_MAINTENANCE_TAG, duplicate check, dedup_key. |
| Checked | YAML parses, all five scripts pass a syntax check, parallel predecessors confirmed. |

## Summary

OPEN v7.1 is PREVIEW v7.1 plus two sending tasks. It creates the SILVA incident and triggers PagerDuty at the same time, but only when the decision is create. It never sends for the sample event, and it does not create a second SILVA ticket while one is open for the same problem.

## Tasks

| Task | Runs after | Network | Result field to read |
|---|---|---|---|
| 1 extract-event-tags | Trigger | Dynatrace Problems API (GET) | snow_inputs |
| 2 resolve-snow-values | Task 1 | SILVA GET | snow_required, ci_services, steps |
| 3 build-payload | Task 2 | None | decision, snow_incident_payload, pagerduty_payload |
| 4a post-silva-incident | Task 3 | SILVA GET (duplicate) and POST (incident) | action, number, url |
| 4b trigger-pagerduty | Task 3 | PagerDuty POST | action, status, dedup_key |

## Settings to check before importing

| Where | Setting | Current | What it means |
|---|---|---|---|
| Task 1 | USE_MAINTENANCE_TAG | true | AGO_Maintenance:True blocks both sends. Set false if only real maintenance windows should block. |
| Task 2 | BASE_URL | https://silvastg.service-now.com | Stg only. Production rejects this account. |
| Task 4a | DRY_RUN | false | true = build and log, never POST. |
| Task 4a | ALLOW_SAMPLE_POST | false | Keep false so the Run button never creates a ticket. |
| Task 4b | ROUTING_KEY | 222651db… | PagerDuty integration key. |
| Task 4b | DRY_RUN | false | true = never call PagerDuty. |
| Trigger | isActive | true | Runs on every new problem once imported. |
| Workflow | hourlyExecutionLimit | 1000 | Safety cap. |

## Task 4a post-silva-incident (sends)

| Step | Action | Returns |
|---|---|---|
| 1 | decision.create_incident is false | action skipped, reason |
| 2 | Sample event and ALLOW_SAMPLE_POST false | action skipped |
| 3 | GET incident where correlation_id=<problem id>^active=true | If found: action exists, number, url |
| 4 | DRY_RUN true | action dry_run, payload |
| 5 | POST /api/now/v2/table/incident with the body | action created, number, sys_id, assignment_group, u_business_service, service_offering_cmdb_ci, configuration_item, u_environment, url |
| 6 | HTTP error | Task fails with "SILVA POST failed <status>: <text>" |

## Task 4b trigger-pagerduty (sends)

| Step | Action | Returns |
|---|---|---|
| 1 | decision.create_incident is false | action skipped |
| 2 | Sample event and ALLOW_SAMPLE_POST false | action skipped |
| 3 | Add routing_key and a link to the Dynatrace problem | |
| 4 | DRY_RUN true | action dry_run, routing key hidden |
| 5 | POST https://events.pagerduty.com/v2/enqueue | action triggered, status, dedup_key, snow_correlation_id |
| 6 | HTTP error | Task fails with "PagerDuty failed <status>: <text>" |

PagerDuty does not wait for SILVA, so the page carries the problem ID (correlation_id), not the INC number.

## Safe first test

| Step | Action |
|---|---|
| 1 | Allowlist silvastg.service-now.com and events.pagerduty.com in Dynatrace outbound connections. |
| 2 | Disable PREVIEW, TEST and older OPEN workflows so one problem is not handled twice. |
| 3 | Optional: set DRY_RUN true in 4a and 4b for the first real problem, then set both back to false. |
| 4 | Import and wait for a real problem with complete data (not maintenance, offering found). |
| 5 | Check 4a: action created and an INC number. Open the url. |
| 6 | Check 4b: action triggered, status success. Check the PagerDuty incident. |
| 7 | Read the incident back (seq 21 line 10) to confirm nothing was dropped. |

## Data flow

```
problem → 1 tags → 2 SILVA GET → 3 payload + decision
                                     ├→ 4a GET dup → POST /incident → INC number
                                     └→ 4b POST /v2/enqueue        → PD incident (dedup dt-problem-<id>)
```

## Related files

| File | Purpose |
|---|---|
| `29-open-v7-1-post-both-ends.workflow.yaml` | The workflow to import. Contains the SILVA password and PD routing key, so never commit it. |
| `23-preview-v7-1-no-post-first/` | PREVIEW with identical tasks 1 to 3. |
| `21-silva-verify-checklist/` | Read-back check after the first real ticket. |
| `29.sh` | Validation and copy commands. |

## Commands

See `29.sh`.
