# Close Direct V3 Incident State

## Decision tree

```
v2 run on INC30341416 (16:27)
 Incident State: Resolved was New   → resolved in ONE step (no In Progress entry)
 Resolved by: Dynatrace JP          → SILVA accepted the API user as resolver
 Resolver Group: InfraSupport_Dist-WindowsHK_L2_ASIA
 → SILVA's real state field is incident_state

Did the v2 task say resolved or failed?
 resolved → fine
 failed but ticket Resolved → v2 checked only "state"; v3 checks state OR incident_state
Close Notes written twice (16:17 and 16:27)?
 → v2 resent close_notes on retry; v3 sends them only once
```

## Short takeaway

| Question | Answer |
|---|---|
| Is INC30341416 resolved? | Yes. Incident State Resolved, Resolved by Dynatrace JP. |
| What fixed it? | Sending `incident_state` together with `state`. One step, no In Progress needed. |
| Is close_code confirmed? | Yes. Solved (Permanently) was accepted. |
| Is Assigned to needed? | No. It is still empty and the ticket resolved. |
| Why v3? | Success and "already resolved" checks now use incident_state too, and close notes are not repeated. |
| File | `43-close-direct-v3-incident-state.workflow.yaml` |

## Summary

The close path now works end to end on SILVA stg. The key discovery is that SILVA drives the ticket through `incident_state` (form label "Incident State"), not only `state`. Version 3 keeps everything from v2 and fixes two small things so future runs report correctly and do not write the same notes twice.

## What the screenshots show

| Evidence | Meaning |
|---|---|
| Field change "Incident State: Resolved was New" | incident_state moved New → Resolved directly. |
| No "In Progress" field change | The step-through was not needed. |
| "Resolved by: Dynatrace JP" | SILVA filled the resolver automatically. |
| "Resolver Group: InfraSupport_Dist-WindowsHK_L2_ASIA" | Taken from the assignment group. |
| Form: Incident State Resolved, Assigned to empty | Assigned to not required. |
| "Close Notes ..." at 16:17 and 16:27 | close_notes sent in both runs. |
| Work note "=== Dynatrace problem closed ===" only at 16:17 | v2 correctly did not repeat the work note. |

## Confirmed SILVA close rules

| Rule | Value |
|---|---|
| Field that resolves the ticket | `incident_state` (send `state` too) |
| Resolved value | From sys_choice "Resolved" |
| close_code | Solved (Permanently) |
| close_notes | Required text, accepted |
| Assigned to | Not required |
| State path | New → Resolved allowed directly |

## What v3 changes (close-silva-incident only)

| Change | Why |
|---|---|
| Success = `state` OR `incident_state` is Resolved | In SILVA `incident_state` is the real one; `state` may not follow. |
| Already-resolved filter uses both fields | Avoids PATCHing a Resolved ticket again on a rerun. |
| `close_notes` only sent if close_code is empty | Stops the duplicate "Close Notes" entry. |

## Which close workflow to keep

| Workflow | Status |
|---|---|
| Seq 39 direct v1 | Replace. Does not set incident_state. |
| Seq 42 direct v2 | Works, but may report failure wrongly and repeat close notes. |
| Seq 43 direct v3 | Use this one. |
| Seq 37 preview close | Same incident_state gap; needs the same fix before use. |

## Go-live steps

| Step | Action |
|---|---|
| 1 | Deactivate seq 39 and seq 42 close workflows. |
| 2 | Import seq 43. Keep `ALLOW_SAMPLE_POST = false`. |
| 3 | Optional: Run once. Expected `skipped` because INC30341416 is already Resolved. |
| 4 | Save / Deploy. |
| 5 | On the next real problem, check OPEN creates the INC and CLOSE resolves it. |

## Data flow map

```
Problem CLOSED
   ▼
prepare-close
   ├─► close-silva-incident (v3)
   │     GET incidents correlation_id, drop ones where state OR incident_state = Resolved
   │     PATCH state + incident_state = Resolved, close_code (+ close_notes, work_notes first time only)
   │     resolved? (state OR incident_state) ── no ─► In Progress → Resolved
   └─► close-pagerduty  resolve dt-problem-<id>
```

## Related files

| File | Purpose |
|---|---|
| `43-close-direct-v3-incident-state.workflow.yaml` | Close workflow to use. Secrets inside, never commit. |
| `42-close-direct-v2-state-fix/` | v2 (unchanged). |
| `36-standard-flow-preview-then-post/` | OPEN partner (unchanged). |
| `43.sh` | Check INC30341416 final fields. |

## Commands

See `43.sh`. Line 1 shows INC30341416 state, incident_state, resolved_by and close_code.
