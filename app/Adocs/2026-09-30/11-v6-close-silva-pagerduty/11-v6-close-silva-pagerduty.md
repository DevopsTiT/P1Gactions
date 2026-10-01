# CLOSE Workflow For SILVA And PagerDuty

## Decision tree

```
Davis problem CLOSED / RESOLVED
 │
 ├─ 1 prepare-close
 │    ├─ real event? no → SAMPLE_EVENT
 │    ├─ correlationId = display_id
 │    ├─ dedupKey = dt-problem-<display_id>
 │    ├─ entity, host, group tag, start, end, duration
 │    └─ build close notes + work notes
 │
 ├─ 2 resolve-silva-incident                 ├─ 3 resolve-pagerduty (parallel)
 │    ├─ sample event? → skipped              │    ├─ sample event? → skipped
 │    ├─ open incident by correlation_id?     │    ├─ DRY_RUN? → dry_run
 │    │    ├─ no → any incident?              │    └─ POST resolve (dedup_key) → resolved
 │    │    │    ├─ yes → already_resolved
 │    │    │    └─ no  → not_found
 │    │    └─ yes
 │    ├─ DRY_RUN? → dry_run
 │    └─ PATCH state 6 + close_code + notes → resolved
```

## Short takeaway

| Question | Answer |
|---|---|
| File | `11-v6-close-silva-pagerduty.workflow.yaml` |
| When does it run? | When a Davis problem is CLOSED or its transition is RESOLVED or CLOSED |
| How is the incident found? | `correlation_id = display_id`, active incidents first |
| How is PagerDuty matched? | `dedup_key = dt-problem-<display_id>`, the same key OPEN v6 used |
| What if OPEN made no ticket? | `not_found`. Nothing fails. |
| What if it is already resolved? | `already_resolved`. No second update. |
| Does a SILVA error block PagerDuty? | No. Tasks 2 and 3 run in parallel. |

## Summary

CLOSE v6 is the partner of OPEN v6. It rebuilds the same two keys from the closed problem, resolves the SILVA incident with clear close notes, and resolves the PagerDuty incident. It is safe to run many times: if the ticket is missing or already resolved, it reports that and does nothing.

## Tasks

| Task | Network | What it does | Main output |
|---|---|---|---|
| 1 prepare-close | Problems API only | Builds keys, duration and notes from the closed event | `correlationId`, `dedupKey`, `closeNotes`, `workNotes` |
| 2 resolve-silva-incident | SILVA GET + PATCH | Finds the incident and sets it to Resolved | `action`, `number`, `state` |
| 3 resolve-pagerduty | PagerDuty POST | Sends the resolve event | `action`, `status`, `dedup_key` |

## Task 1 details

| Step | What happens |
|---|---|
| 1 | Use the trigger event, or SAMPLE_EVENT on manual Run |
| 2 | Call the Problems API for evidence and times (continues if the scope is missing) |
| 3 | Problem id from `display_id` |
| 4 | Entity from root cause, affected names or the entity field; host from the `host` tag |
| 5 | Group from any `*_ASSIGNMENT_GROUP` tag (for the notes only) |
| 6 | Start from `event.start`, end from `event.end` (Problems API as backup), then duration |
| 7 | Build close notes (short, for the resolution) and work notes (full, internal) |

## Task 2 details

| Step | Check | Result |
|---|---|---|
| 1 | Sample event and ALLOW_SAMPLE_SEND false | `skipped` |
| 2 | GET incident `correlation_id=<id>^active=true` | Found → go to step 4 |
| 3 | Not found: GET any incident with that correlation_id | Found → `already_resolved`; none → `not_found` |
| 4 | DRY_RUN true | `dry_run` with the body |
| 5 | PATCH `/incident/<sys_id>` | `resolved` |
| 6 | PATCH fails | Task fails with the SILVA message |

## Fields sent when resolving

| Field | Value | Meaning |
|---|---|---|
| state | 6 | Resolved |
| close_code | Solved (Permanently) | Resolution code (confirm stored value with `11.sh`) |
| close_notes | Close notes from task 1 | Why and when it closed |
| comments | "Resolved automatically: the Dynatrace problem is closed." | Customer visible comment |
| work_notes | Work notes from task 1 | Internal detail: times, duration, keys, link |
| extra | `EXTRA_RESOLVE_FIELDS` | Add fields here if SILVA demands more on resolve |

## Close notes example

```
[RESOLVED] Dynatrace problem P-260916434 closed at 2026-09-29T03:25:00.000Z
Problem   : Oracle DB Instance down
Entity    : DEA10B01 on host deaa310b
Duration  : 25 min
Recovery confirmed by Dynatrace: the problem condition is no longer detected.
Dynatrace : https://<tenant>/ui/apps/dynatrace.davis.problems/problem/<event.id>
```

## Task 3 details

| Step | Check | Result |
|---|---|---|
| 1 | Sample event and ALLOW_SAMPLE_SEND false | `skipped` |
| 2 | DRY_RUN true | `dry_run` (routing key hidden) |
| 3 | POST `{ event_action: "resolve", dedup_key }` | `resolved` |

PagerDuty accepts a resolve for a key it does not know and simply ignores it, so no special check is needed when OPEN did not page.

## OPEN and CLOSE together

| Key | OPEN v6 sets | CLOSE v6 uses |
|---|---|---|
| SILVA correlation_id | display_id | GET incident by it |
| PagerDuty dedup_key | dt-problem-<display_id> | Resolve with it |
| Routing key | 222651db... | Same key |
| Sample guard | ALLOW_SAMPLE_POST | ALLOW_SAMPLE_SEND |
| Dry run | DRY_RUN in tasks 4 and 5 | DRY_RUN in tasks 2 and 3 |

## Before activating

| Step | What to do |
|---|---|
| 1 | Allowlist silvastg.service-now.com and events.pagerduty.com |
| 2 | Confirm state and close_code values with `11.sh` |
| 3 | Test with DRY_RUN true and ALLOW_SAMPLE_SEND true (manual Run) |
| 4 | Set DRY_RUN false, ALLOW_SAMPLE_SEND false, activate |
| 5 | Deactivate the older CLOSE workflow (2026-09-28 seq 27) so incidents are not patched twice |

## Data flow

```
Problem CLOSED
  ▼
1 prepare-close → correlationId, dedupKey, closeNotes, workNotes
  ├──────────────────────────────┐
  ▼                              ▼
2 SILVA                         3 PagerDuty
  GET open incident               POST resolve
  ├─ none → already_resolved      (dedup_key dt-problem-<display_id>)
  │         or not_found
  └─ found → PATCH Resolved
```

## Related files

| File | What it is |
|---|---|
| `11-v6-close-silva-pagerduty.workflow.yaml` | CLOSE workflow |
| `../9-v6-full-open-silva-pagerduty/9-v6-full-open-silva-pagerduty.workflow.yaml` | OPEN workflow |
| `11.sh` | Checks and manual tests |

## Commands

See `11.sh`.
