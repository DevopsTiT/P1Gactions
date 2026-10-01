# Close Workflow Preview Then Resolve

## Decision tree

```
Dynatrace problem CLOSED
 └─ find-silva-incident: incident with correlation_id = problem id?
     NO  → SILVA branch skips ("OPEN may have skipped it"), PagerDuty still resolves
     YES → still open (active true)?
            NO  → skip ("already Resolved / Closed")
            YES → preview-silva-close checks state and close_code against SILVA choice lists
                   WRONG     → fix RESOLVED_STATE or CLOSE_CODE in build-close-payload (preview lists real values)
                   UNVERIFIED→ choice list not readable; PATCH still runs, check result
                   OK        → resolve-silva-incident PATCH → state Resolved?
                                NO  → SILVA needs more close fields → add to EXTRA_FIELDS
                                YES → done
 └─ preview-pagerduty-resolve → resolve-pagerduty (dedup_key dt-problem-<id>)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it do? | When a problem closes, it resolves the matching SILVA incident and the PagerDuty alert. |
| How does it find the ticket? | `correlation_id` = problem id (for example P-261090), the same key OPEN wrote. |
| How does it find the PagerDuty alert? | `dedup_key` = `dt-problem-<problem id>`, the same key OPEN sent. |
| Layout | The standard flow: 3 shared tasks, then preview → send on each branch. |
| File | `37-close-workflow-preview-then-resolve.workflow.yaml` |
| Unconfirmed value | `close_code` "Solved (Permanently)". The preview checks it against SILVA's real list. |

## Summary

This is the CLOSE partner of the standard OPEN flow (seq 36). It uses the same layout and the same two sync keys. The SILVA branch only resolves an open incident and only if the preview found no wrong values. The PagerDuty branch always sends a resolve, which PagerDuty ignores if no alert is open.

## Tasks

| # | Task | Position | Runs after | What it does | API |
|---|---|---|---|---|---|
| 0 | Problem trigger | top | — | Fires when a problem closes (`event.status == "CLOSED"`, onProblemClose true). | — |
| 1 | prepare-close | (0,1) | trigger | Problem id, correlation_id, dedup_key, start, end, duration, cause, evidence. | Dynatrace Problems API v2 |
| 2 | find-silva-incident | (0,2) | prepare-close | Finds the incident by correlation_id (open one first). Reads the state and close_code choice lists. | SILVA GET incident, GET sys_choice |
| 3 | build-close-payload | (0,3) | find-silva-incident | Builds the SILVA PATCH body and the PagerDuty resolve body. Decides resolve or skip. | none |
| 4a | preview-silva-close | (0,4) | build-close-payload | Field check for incident, open, state, close_code, close_notes. Sends nothing. | none |
| 5a | resolve-silva-incident | (0,5) | preview-silva-close | Re-reads the incident, then PATCHes it to Resolved. Fails loudly if state did not change. | SILVA GET + PATCH incident |
| 4b | preview-pagerduty-resolve | (1,4) | build-close-payload | Checks event_action resolve and dedup_key. Sends nothing. | none |
| 5b | resolve-pagerduty | (1,5) | preview-pagerduty-resolve | Sends the resolve event. | PagerDuty Events v2 |

## SILVA resolve body

| Field | Value | Note |
|---|---|---|
| `state` | Resolved (value from SILVA list, usually 6) | Setting RESOLVED_STATE |
| `close_code` | Solved (Permanently) | Setting CLOSE_CODE. Not yet confirmed. Preview shows WRONG with the real list if it does not match. |
| `close_notes` | Problem id, close time, duration, cause, evidence | Built automatically |
| `work_notes` | Block with group, business service, offering, CI, Dynatrace link, PagerDuty key | Setting NOTES_FIELD. Change to `comments` if the caller should see it. |
| Extra fields | none by default | Setting EXTRA_FIELDS, for example `{ u_resolution_type: "Automatic" }` if SILVA requires it |

## PagerDuty resolve body

| Field | Value |
|---|---|
| `routing_key` | Same key as OPEN (hidden in preview) |
| `event_action` | resolve |
| `dedup_key` | dt-problem-<problem id> |

## Settings you can change

| Setting | Task | What it means |
|---|---|---|
| `RESOLVED_STATE` | build-close-payload | Target state, value or label. |
| `CLOSE_CODE` | build-close-payload | Resolution code, value or label. |
| `NOTES_FIELD` | build-close-payload | `work_notes` (internal) or `comments` (visible to caller). |
| `EXTRA_FIELDS` | build-close-payload | Any field SILVA needs before it allows Resolved. |
| `DRY_RUN` | resolve-silva-incident, resolve-pagerduty | true = build only, send nothing. |
| `ALLOW_SAMPLE_POST` | resolve-silva-incident, resolve-pagerduty | true = a manual Run really resolves P-261090. |

## How to test

| Step | Action | Expected |
|---|---|---|
| 1 | Run `37.sh` lines 1 and 2 | Real state and close_code values. Make sure "Resolved" and "Solved (Permanently)" exist. |
| 2 | Import the YAML, press Run (no event) | Sample close of P-261090. Previews show the incident and checks. Both send tasks skip (sample). |
| 3 | If close_code is WRONG | The preview note lists the real labels. Put the right one in CLOSE_CODE. |
| 4 | To really close P-261090 | Set ALLOW_SAMPLE_POST = true in 5a and 5b, Run again. |
| 5 | Run `37.sh` line 3 | Incident shows state Resolved, close_code filled, active false. |
| 6 | Save / Deploy | Real problem closes now trigger it. |

## Data flow map

```
Problem CLOSED (P-261090)
   │
   ▼
prepare-close ─► find-silva-incident ─► build-close-payload
                  │ GET incident correlation_id=P-261090
                  │ GET sys_choice state, close_code
                                          │
                ┌─────────────────────────┴─────────────────────────┐
                ▼                                                   ▼
       preview-silva-close                              preview-pagerduty-resolve
                │ ready, no problems                                │ ready
                ▼                                                   ▼
       resolve-silva-incident                           resolve-pagerduty
       PATCH incident → Resolved                        POST enqueue resolve dt-problem-P-261090
```

## Related files

| File | Purpose |
|---|---|
| `37-close-workflow-preview-then-resolve.workflow.yaml` | The CLOSE workflow. Secrets inside, never commit. |
| `36-standard-flow-preview-then-post/` | The OPEN partner (unchanged). |
| `37.sh` | Choice list checks and post-close check. |

## Commands

See `37.sh`. Line 1 lists state choices. Line 2 lists close_code choices. Line 3 shows the P-261090 incident after closing.
