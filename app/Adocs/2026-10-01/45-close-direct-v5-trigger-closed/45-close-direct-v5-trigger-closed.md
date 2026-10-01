# Close Workflow Trigger Set To Closed

## Decision tree

```
Close workflow trigger panel → Event state?
 "active"            → wrong: runs only on open → change to "closed"
 "active or closed"  → runs on open AND close → change to "closed" (v4 guard skips the open run, but it is noise)
 "closed"            → correct → Save → Deploy (not Draft)
Imported v5 but panel still shows "active or closed"?
 → YAML key not honored by this tenant → pick "closed" in the dropdown → Save
Problem closed but nothing happened?
 → Workflow still Draft? → Deploy
 → Executions list empty? → check filterQuery and categories
 → Task error "not allowed"? → add host to External requests allowlist
```

## Short takeaway

| Question | Answer |
|---|---|
| Is "active or closed" right for the close workflow? | No. It also starts the workflow when a problem opens. |
| What should it be? | Event state "closed". |
| Was my earlier "no closed-only option" claim right? | No. The dropdown has three options: active, active or closed, closed. |
| What changed in v5? | Trigger adds `triggerOn: close`, and the title and header say v5. |
| Is the v4 safety guard still there? | Yes. If the problem is not closed, both close tasks skip. |
| Fastest fix today | In the imported workflow, set Event state to "closed", Save, Deploy. |

## Summary

I was wrong earlier: the Dynatrace problem trigger does have a "closed" option. The close workflow should use it, so it only runs when a Davis problem closes. v5 sets this in the YAML (`triggerOn: close`) and keeps the v4 closed check as a second safety net.

## Investigation

| What I checked | What I found |
|---|---|
| Your trigger dropdown screenshot | Three options: active, active or closed, closed. |
| Old YAML (v1 to v4) | Only `onProblemClose: true`, which the UI shows as "active or closed". |
| Terraform provider docs for the same trigger | `trigger_on` accepts `open`, `open-and-close`, `close`. `on_problem_close` is deprecated. |
| Conclusion | The workflow JSON/YAML field is `triggerOn` with value `close`. `onProblemClose` is the old switch. |

Not confirmed live: whether your tenant reads `triggerOn` on import. That is why the result step says to check the panel after import.

## Result

1. Easiest: open your imported close workflow, click the trigger, set **Event state = closed**, Save, Deploy.
2. Or import `45-close-direct-v5-trigger-closed.workflow.yaml`, then open the trigger and confirm it shows **closed**. If it shows "active or closed", choose "closed" by hand and Save.
3. Use v5 instead of v1. v1 lacks the `incident_state` fix (that is why INC30341416 said "state did not change").
4. Keep the External requests allowlist: `silvastg.service-now.com` and `events.pagerduty.com`.
5. Test: close a test problem (or Run with SAMPLE_EVENT + ALLOW_SAMPLE_POST) and check both tasks say resolved, not skipped.

## What the trigger looks like now

```yaml
trigger:
  eventTrigger:
    isActive: true
    filterQuery: >-
      event.kind == "DAVIS_PROBLEM" AND event.status == "CLOSED"
    triggerConfiguration:
      type: davis-problem
      value:
        categories: {error: true, resource: true, slowdown: true, availability: true, custom: true}
        entityTags: {}
        triggerOn: close
        onProblemClose: true
```

| Field | What it means | Why you care |
|---|---|---|
| `triggerOn: close` | Start only when the problem closes. | This is the "closed" option in the dropdown. |
| `onProblemClose: true` | Old switch meaning "also on close". | Kept so older tenants do not ignore close events. If the panel shows "closed", it is harmless. |
| `filterQuery` | Extra filter on the event. | Belt and braces: only CLOSED Davis problems. |
| `is_closed` guard in prepare-close | Code check using the event and Problems API. | If the trigger is ever changed back, open events still do nothing. |

## Data flow map

```
Davis problem P-xxxxx closes
  → Problem trigger (Event state = closed)
  → prepare-close: read display_id, check is_closed
      ├─ close-silva-incident: find by correlation_id = display_id
      │     → PATCH state + incident_state = Resolved, close_code, close_notes
      │     → verify state OR incident_state is Resolved
      └─ close-pagerduty: POST /v2/enqueue action=resolve
            dedup_key = dt-problem-<display_id>
```

## Related files

| File | What it is |
|---|---|
| `45-close-direct-v5-trigger-closed.workflow.yaml` | v5 close workflow (import this) |
| `44-close-direct-v4-closed-only-guard/` | v4, same code but trigger "active or closed" |
| `36-standard-flow-preview-then-post/` | Standard OPEN workflow |
| `45.sh` | Validation and git one-liners |

## Commands

See [`45.sh`](45.sh). Do not commit the workflow YAML: it contains SILVA and PagerDuty secrets.

```bash
ruby -ryaml -e 'p YAML.load_file("45-close-direct-v5-trigger-closed.workflow.yaml")["workflow"]["trigger"]'
```
