# Close Direct SILVA And PagerDuty

## Decision tree

```
Dynatrace problem CLOSED
 └─ prepare-close: display_id → correlation_id + dedup_key
     ├─ close-silva-incident
     │    open incidents with correlation_id?  NO  → skipped (already resolved or never created)
     │                                         YES → state / close_code valid in SILVA list?
     │                                                NO  → task fails, error lists allowed values → fix CLOSE_CODE
     │                                                YES → PATCH each → state Resolved?
     │                                                       NO  → task fails → add EXTRA_FIELDS
     │                                                       YES → resolved
     └─ close-pagerduty → resolve dt-problem-<id> (runs even if SILVA fails)
```

## Short takeaway

| Question | Answer |
|---|---|
| What triggers it? | A Dynatrace problem closing (`event.status == "CLOSED"`). |
| What does it close? | Every open SILVA incident with correlation_id = problem id, and the PagerDuty alert with dedup_key `dt-problem-<id>`. |
| How is it different from seq 37? | No preview tasks. 3 tasks only. SILVA and PagerDuty run in parallel right after prepare-close. |
| Input needed? | None on a real close. For manual Run, edit `SAMPLE_EVENT.display_id`. |
| File | `39-close-direct-silva-pagerduty.workflow.yaml` |

## Summary

This is the short CLOSE version. It is useful once you trust the values and just want the close to happen. It still checks `state` and `close_code` against SILVA's real choice list before sending, and fails with the allowed values if they do not match. Use this one or seq 37, not both.

## Tasks

| Task | Position | Runs after | What it does | API |
|---|---|---|---|---|
| Problem trigger | top | — | Fires when a problem closes. | — |
| prepare-close | (0,1) | trigger | Display id, correlation_id, dedup_key, duration, cause. | Dynatrace Problems API v2 |
| close-silva-incident | (0,2) | prepare-close | GET open incidents by correlation_id. Checks state and close_code choices. PATCHes each to Resolved. | SILVA GET + PATCH |
| close-pagerduty | (1,2) | prepare-close | Sends event_action resolve with the same dedup_key. | PagerDuty Events v2 |

## Seq 37 vs seq 39

| Topic | Seq 37 (preview then resolve) | Seq 39 (direct) |
|---|---|---|
| Number of tasks | 7 | 3 |
| Preview before sending | Yes | No |
| Wrong close_code | Preview shows WRONG, send skips | Task fails with the allowed values |
| More than one open incident | Resolves the newest open one | Resolves all open ones (up to 5) |
| PagerDuty if SILVA fails | Still resolves | Still resolves |
| Best for | First tests and auditing | Day-to-day once values are confirmed |

## SILVA resolve body

| Field | Value |
|---|---|
| `state` | Resolved (SILVA value, usually 6) |
| `close_code` | Solved (Permanently), not yet confirmed |
| `close_notes` | Problem id, close time, duration, cause |
| `work_notes` | Group, business service, offering, CI, Dynatrace link, PagerDuty key |

## Settings

| Setting | Task | What it means |
|---|---|---|
| `RESOLVED_STATE` | close-silva-incident | Target state, value or label. |
| `CLOSE_CODE` | close-silva-incident | Resolution code, value or label. |
| `NOTES_FIELD` | close-silva-incident | `work_notes` (internal) or `comments` (caller sees it). |
| `EXTRA_FIELDS` | close-silva-incident | Fields SILVA needs before Resolved. |
| `DRY_RUN` | both close tasks | true = send nothing. |
| `ALLOW_SAMPLE_POST` | both close tasks | true = manual Run really resolves `SAMPLE_EVENT.display_id`. |
| `SAMPLE_EVENT.display_id` | prepare-close | Problem to close on manual Run. |

## How to test

| Step | Action | Expected |
|---|---|---|
| 1 | `39.sh` line 1 | Allowed close_code values. Put the right one in CLOSE_CODE. |
| 2 | Import, Run with defaults | Both close tasks skip (sample). SILVA result lists `would_resolve`. |
| 3 | ALLOW_SAMPLE_POST true in both close tasks, Run | SILVA `action: resolved`, PagerDuty `action: resolved`. |
| 4 | `39.sh` line 2 | Incident state Resolved, active false. |
| 5 | ALLOW_SAMPLE_POST back to false, Save / Deploy | Real closes now trigger it. |
| 6 | Deactivate seq 37 if imported | One close is handled once. |

## Data flow map

```
Problem CLOSED (P-261090)
   │
   ▼
prepare-close  display_id → correlation_id P-261090, dedup_key dt-problem-P-261090
   │
   ├─► close-silva-incident ─► GET incident correlation_id=P-261090^active=true
   │                           GET sys_choice state, close_code
   │                           PATCH each → Resolved
   │
   └─► close-pagerduty ──────► POST events.pagerduty.com/v2/enqueue  event_action resolve
```

## Related files

| File | Purpose |
|---|---|
| `39-close-direct-silva-pagerduty.workflow.yaml` | This workflow. Secrets inside, never commit. |
| `37-close-workflow-preview-then-resolve/` | Preview version (unchanged). |
| `36-standard-flow-preview-then-post/` | OPEN partner (unchanged). |
| `39.sh` | Choice list and post-close checks. |

## Commands

See `39.sh`. Line 1 lists close_code choices. Line 2 shows the P-261090 incident after closing.
