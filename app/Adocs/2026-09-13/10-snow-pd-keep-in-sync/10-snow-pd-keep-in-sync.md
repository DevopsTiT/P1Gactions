# Keep ServiceNow and PagerDuty in Sync

```
Need SNOW + PD stay aligned?
  │
  ├─ Same Problem open/close?
  │     → Use Dynatrace as the boss (orchestrator)
  │     → Shared keys: Problem ID → SNOW correlation_id
  │                      Problem ID → PD dedup_key
  │
  ├─ Open event?
  │     → Create INC + PD page in parallel
  │     → Then cross-link (write PD key into SNOW work notes)
  │
  ├─ Close event?
  │     → Find INC by correlation_id
  │     → Resolve INC + PD resolve with same dedup_key
  │
  └─ Want live assignee/status between SNOW↔PD only?
        → That is optional product sync (PD ServiceNow integration)
        → Not required for this Dynatrace workflow design
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Who keeps them in sync? | Dynatrace Workflows, not SNOW talking to PD by itself |
| Shared identity | Dynatrace Problem ID |
| ServiceNow key | `correlation_id` = Problem ID |
| PagerDuty key | `dedup_key` = `dt-problem-<ProblemID>` |
| Open sync | Parallel create, then `cross-link-snow-pd` comments the PD key on the INC |
| Close sync | Close workflow resolves both using those same keys |

## Summary

ServiceNow and PagerDuty do not need to sync each other directly for this design. Dynatrace owns the Problem lifecycle. On open, the workflow creates both tickets with the same Problem ID family of keys, then writes a human-readable link into the INC. On close, one workflow finds and resolves both. That is “sync” for open/close and correlation. Bidirectional assignee updates are a separate optional product feature.

## What “sync” means here

| Kind of sync | Covered by your workflows? | What it means |
| --- | --- | --- |
| Create together | Yes | One Problem open creates INC and PD page |
| Same story / links | Yes | Same Problem URL, app, runbook, severity mapping |
| Find each other later | Yes | Keys + work notes with `dedup_key` |
| Close together | Yes | Problem closed resolves INC and PD |
| On-call ack mirrors INC assignee | No (optional) | Needs PD↔ServiceNow native integration or extra automation |

## How the workflow keeps them aligned

### 1. One source of truth: Problem ID

```
Dynatrace Problem ID
        │
        ├──────────────► ServiceNow.correlation_id  = <ProblemID>
        │
        └──────────────► PagerDuty.dedup_key       = dt-problem-<ProblemID>
```

**Rule:** Never invent a new random key each run. If keys differ, close/sync breaks.

### 2. On Problem open (create workflow)

| Step | What happens | Sync role |
| --- | --- | --- |
| prepare-payload | Build Problem ID, URLs, `dedupKey` | Creates shared identity |
| create-servicenow-incident | POST INC with `correlation_id` | Ticket side |
| create-pagerduty-incident | POST Events API trigger with `dedup_key` | Page side (parallel) |
| cross-link-snow-pd | PATCH INC work notes with PD `dedup_key` + Problem URL | Human + audit link |

```
prepare-payload
    │
    ├──► create-servicenow-incident ──┐
    │                                 ├──► cross-link-snow-pd
    └──► create-pagerduty-incident ───┘
```

### 3. On Problem close (resolve workflow)

| Step | What happens |
| --- | --- |
| Read Problem ID from closed event | Same ID as open |
| Search SNOW | `correlation_id=<ProblemID>` |
| Resolve INC | State/close notes: Problem closed |
| Resolve PD | `event_action=resolve` + same `dedup_key` |

```
Problem CLOSED
  → resolve-snow-and-pd
       → find INC by correlation_id
       → resolve INC
       → PD resolve(dedup_key)
```

## Practical checklist

| Check | Pass when |
| --- | --- |
| Open test | One INC + one PD for one Problem |
| Keys | SNOW `correlation_id` matches Problem ID |
| Keys | PD `dedup_key` is `dt-problem-<same id>` |
| Cross-link | INC work notes show the PD key and Problem URL |
| Close test | Same Problem close resolves that INC and that PD page |
| Duplicate open | Second open does not create a second “random” key |

## Common mistakes

| Mistake | Result | Fix |
| --- | --- | --- |
| Random UUID as `dedup_key` each run | Cannot resolve the original PD page | Always `dt-problem-` + Problem ID |
| Empty / wrong `correlation_id` | Close cannot find INC | Set on create; search on close |
| Only create workflow, no close workflow | Tickets stay open after Problem ends | Upload both workflows |
| Expect SNOW to auto-close PD | Will not happen in this design | Dynatrace close workflow does both |

## Data flow map

```
[Davis Problem OPEN]
        │
        ▼
[Dynatrace WF create]
        │
        ├─► [ServiceNow INC]  correlation_id=ProblemID
        │         ▲
        │         │ work_notes: PD dedup_key + Problem URL
        │         │
        └─► [PagerDuty]       dedup_key=dt-problem-ProblemID

[Davis Problem CLOSED]
        │
        ▼
[Dynatrace WF close]
        ├─► find + resolve SNOW by correlation_id
        └─► resolve PD by same dedup_key
```

## Related files

| Path | Why |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | Upload YAML/JSON with cross-link + resolve tasks |
| `../8-dynatrace-snow-pd-detailed-design/` | Full architecture and correlation section |
| `../9-one-or-two-workflow-files/` | Keep create and close as two workflows |
| `10.sh` | Optional inspect one-liners |

## Commands

See `10.sh` in this folder.
