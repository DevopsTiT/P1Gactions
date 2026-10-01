# Close Workflow Input

## Decision tree

```
How is the close workflow started?
 Real problem closes (deployed, trigger on) → input comes automatically from the event
     display_id (P-261090)  → correlation_id + dedup_key
     event.id (internal id) → Problems API for duration and cause
     you type nothing
 Manual Run button (testing / closing one by hand)
     no input box → edit SAMPLE_EVENT in prepare-close
         "display_id": "P-xxxxxx"   ← required, this finds the ticket
         "event.id"                 ← not used for sample runs (duration shows "unknown")
     set ALLOW_SAMPLE_POST = true in both send tasks to really resolve
```

## Short takeaway

| Question | Answer |
|---|---|
| Is there an input field? | No. The workflow has `inputs: []`. |
| What key matters? | The problem display id, for example `P-261090`. |
| Where do I put it for a manual Run? | `SAMPLE_EVENT.display_id` in task prepare-close. |
| Do I need the internal problem id? | No. Only used for duration and cause on real events. |
| Do I need the INC number? | No. The workflow finds the INC by correlation_id = display id. |

## Summary

On a real close, Dynatrace hands the event to the workflow and everything is automatic. For a manual Run, the only value that matters is the display id. It becomes `correlation_id` (to find the SILVA incident) and `dedup_key` `dt-problem-<display id>` (to find the PagerDuty alert).

## Where each value comes from

| Value used | Real close event | Manual Run |
|---|---|---|
| correlation_id | `display_id` from the event | `SAMPLE_EVENT.display_id` |
| dedup_key | `dt-problem-` + `display_id` | `dt-problem-` + `SAMPLE_EVENT.display_id` |
| Problem title | Problems API (using `event.id`) | `SAMPLE_EVENT["event.name"]` |
| Duration | Problems API start and end time | "unknown" |
| Where (entity) | Problems API root cause | `SAMPLE_EVENT.root_cause_entity_name` |

## Manual Run for another problem

Edit only this block in prepare-close:

```js
const SAMPLE_EVENT = {
  "event.kind": "DAVIS_PROBLEM",
  "event.status": "CLOSED",
  "display_id": "P-261090",
  "event.name": "Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa",
  "root_cause_entity_name": "ts12.hk.intraxa",
  "affected_entity_names": ["[INFRA ACC] Windows System"]
};
```

| Field | Required | What to put |
|---|---|---|
| `display_id` | Yes | The P- number shown in Dynatrace and in the SILVA External Ticket / correlation_id. |
| `event.name` | No | Problem title, only used in close notes. |
| `root_cause_entity_name` | No | Host or entity name, only used in close notes. |

Then:

| Step | Action |
|---|---|
| 1 | Run once with ALLOW_SAMPLE_POST false. Check preview-silva-close finds the right INC. |
| 2 | Set ALLOW_SAMPLE_POST = true in resolve-silva-incident and resolve-pagerduty. |
| 3 | Run again. |
| 4 | Set ALLOW_SAMPLE_POST back to false. |

## Common mistakes

| Mistake | What happens |
|---|---|
| Putting the INC number in display_id | No incident found, SILVA skips. |
| Putting the internal id (`1803053789540459386_...V2`) in display_id | No incident found, SILVA skips. |
| Leaving ALLOW_SAMPLE_POST true after testing | Every manual Run resolves that problem again (harmless if already resolved, but confusing). |

## Data flow map

```
display_id P-261090
   ├─► correlation_id=P-261090 ─► SILVA GET incident ─► PATCH Resolved
   └─► dedup_key dt-problem-P-261090 ─► PagerDuty resolve
```

## Related files

| File | Purpose |
|---|---|
| `37-close-workflow-preview-then-resolve/` | The close workflow (unchanged). |
| `38.sh` | Check which INC a display id maps to before closing. |

## Commands

See `38.sh`. Line 1 shows the incident for a display id (replace P-261090).
