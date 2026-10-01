# Close Direct V2 State Fix

## Decision tree

```
close-silva-incident Error: "INC30341416 state did not change"
 What DID change?  close_code Solved (Permanently), close notes, work note → PATCH reached SILVA, auth OK
 What did NOT?     state → SILVA ignored or reverted it
   Cause 1: SILVA's real state field is incident_state (form label "Incident State")
            → v2 sends state AND incident_state
   Cause 2: State model blocks New → Resolved
            → v2 steps New → In Progress → Resolved
   Cause 3: Resolve needs Assigned to
            → INC30340215 was Resolved with Assigned to empty, so unlikely; ASSIGNED_TO setting if needed
   Still failing?
            → 42.sh lines 1-6: compare with resolved INC30340215 and read sys_audit
```

## Short takeaway

| Question | Answer |
|---|---|
| Did the close reach SILVA? | Yes. Close code, close notes and the work note were saved on INC30341416. |
| What failed? | Only the state. SILVA kept it at its old value. |
| Is the workflow logic wrong? | No. It correctly detected that the state did not change and failed loudly. |
| Most likely cause | SILVA uses `incident_state` (form "Incident State") or does not allow New → Resolved in one jump. |
| Fix | `42-close-direct-v2-state-fix.workflow.yaml` sends both state fields and steps through In Progress. |
| PagerDuty | Runs in its own branch, so it should be resolved. Check close-pagerduty result. |

## Summary

The first real close run proved the connection, login, search and PATCH all work. SILVA simply refused the state change. Version 2 tries the two most likely fixes automatically and writes in its result which attempt worked, so after one run we know SILVA's rule for sure. Notes are not added again for INC30341416 because its close code is already set.

## What the screenshots show

| Evidence | Meaning |
|---|---|
| Task error "INC30341416 state did not change" | PATCH returned success but `state` stayed the same. |
| Work note "=== Dynatrace problem closed (P-261090) ===" | `work_notes` saved. |
| Work note "Close Notes: Dynatrace problem P-261090 closed automatically..." | `close_notes` saved (SILVA logs it in activities). |
| Field change "Close code: Solved (Permanently)" | `close_code` value is valid in SILVA. One open question answered. |
| Duration 2 h 12 min | Problems API worked; start and end time are real. |

## What v2 changes (only the close-silva-incident task)

| Change | Why |
|---|---|
| Sends `state` and `incident_state` | SILVA's form shows "Incident State", which is `incident_state`. Some instances only move the ticket when this field changes. |
| Step through In Progress if refused | Many ServiceNow state models do not allow New → Resolved directly. |
| Does not re-add notes when close_code is already set | INC30341416 already has the notes from the first run. |
| Skips incidents already Resolved | A Resolved incident can stay `active=true` until Closed. |
| Result shows every attempt | `attempts` list and `worked_with` tell us which rule SILVA has. |
| Optional `ASSIGNED_TO` | Only if SILVA turns out to require Assigned to. Default empty. |

### New settings

| Setting | Default | What it means |
|---|---|---|
| `STATE_FIELDS` | `["state", "incident_state"]` | Fields that get the Resolved value. |
| `IN_PROGRESS_STATE` | In Progress | Middle state for the step-through. |
| `STEP_THROUGH_IN_PROGRESS` | true | Try In Progress then Resolved if the direct move is refused. |
| `ASSIGNED_TO` | "" | sys_id for Assigned to, only when needed. |

## How to retry INC30341416 now

P-261090 is already closed, so Dynatrace will not trigger again. Use the manual Run:

| Step | Action |
|---|---|
| 1 | Deactivate the v1 close workflow (seq 39). |
| 2 | Import `42-close-direct-v2-state-fix.workflow.yaml`. |
| 3 | In prepare-close, `SAMPLE_EVENT.display_id` is already `P-261090`. |
| 4 | In close-silva-incident set `ALLOW_SAMPLE_POST = true`. Leave close-pagerduty as is (already resolved). |
| 5 | Run. Open close-silva-incident result. |
| 6 | Read `worked_with` and `attempts`. |
| 7 | Set `ALLOW_SAMPLE_POST` back to false. Save / Deploy. |

### Reading the result

| Result | Meaning | Next step |
|---|---|---|
| `worked_with: direct to Resolved (state + incident_state)` | SILVA needed incident_state. | Done. Keep v2. |
| `worked_with: In Progress then Resolved` | SILVA blocks New → Resolved. | Done. Keep v2. |
| `action: failed`, state still New | Another rule (mandatory field or business rule). | Run `42.sh` lines 1-6 and send me the output. |

## Data flow map

```
P-261090 closed
   ▼
prepare-close
   ├─► close-silva-incident (v2)
   │     GET open, unresolved incidents (INC30341416, close_code already set → no new notes)
   │     PATCH state + incident_state = Resolved, close_code, close_notes
   │        state changed? ── yes ─► resolved
   │        no ─► PATCH In Progress ─► PATCH Resolved ─► resolved or failed (attempts listed)
   └─► close-pagerduty  resolve dt-problem-P-261090
```

## Related files

| File | Purpose |
|---|---|
| `42-close-direct-v2-state-fix.workflow.yaml` | Fixed close workflow. Secrets inside, never commit. |
| `39-close-direct-silva-pagerduty/` | v1 (unchanged). |
| `37-close-workflow-preview-then-resolve/` | Preview close (unchanged, has the same state limitation). |
| `42.sh` | Diagnostic queries. |

## Commands

See `42.sh`. Line 1 shows how resolved INC30340215 looks. Line 2 gets its sys_id. Line 3 reads its audit history (replace the sys_id). Line 4 shows INC30341416 now. Line 5 lists incident_state choices. Line 6 reads INC30341416 audit to see if SILVA set and reverted the state.
