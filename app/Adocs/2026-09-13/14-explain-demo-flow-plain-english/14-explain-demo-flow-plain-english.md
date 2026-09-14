# Explain Demo Flow Plain English

```
Confused by the diagram?
  │
  ├─ Think: one fire alarm (Dynatrace Problem)
  │     → opens a ticket (ServiceNow)
  │     → pages a person (PagerDuty)
  │     → later closes both when the fire is out
  │
  ├─ Dynatrace is the boss that starts and stops both
  ├─ correlation_id / dedup_key = shared badge number
  └─ Two workflows: one for OPEN, one for CLOSE
```

## Short takeaway

| Key point | Plain meaning |
| --- | --- |
| Problem OPEN | Dynatrace says “something is broken” |
| Create workflow | Automatic robot that makes a ticket + a page |
| ServiceNow INC | The written ticket for tracking / SLA |
| PagerDuty alert | The phone/pager that wakes on-call |
| correlation_id / dedup_key | Same Problem ID written two ways so close can find both |
| Problem close | Dynatrace says “it is fixed” |
| Close workflow | Robot finds that ticket + page and closes them |

## Summary

The diagram is one story in two halves. When a Problem opens, Dynatrace runs the **create** workflow: prepare data, create a ServiceNow incident, trigger PagerDuty, then write a note linking them. When you close that Problem, Dynatrace runs the **close** workflow: find the same incident and resolve it, and resolve the same PagerDuty alert. Nothing magic — Dynatrace calls both systems using one shared ID.

---

## Big picture (one analogy)

Imagine a building fire:

| Real life | In this design |
| --- | --- |
| Smoke detector goes off | Dynatrace **Problem OPEN** |
| Someone writes an incident report | **ServiceNow INC** |
| Someone pages the fire crew | **PagerDuty alert** |
| Report number = page number | **Shared Problem ID** (keys below) |
| Smoke clears / alarm reset | Dynatrace **Problem CLOSED** |
| Close the report + stop paging | **Close workflow** |

Dynatrace is the smoke detector **and** the person who later says “all clear.” ServiceNow and PagerDuty do not need to talk to each other for this design. Dynatrace talks to both.

---

## Half 1 — You trigger Problem OPEN

### What “You trigger Problem OPEN” means

Something bad is detected (or you cause a test alert). Davis creates a **Problem** — a single “this is wrong” object with:

| Item | What it is |
| --- | --- |
| Problem ID | Unique ID (example shape: `P-12345`) |
| Title | Short what-went-wrong text |
| URL | Link to open it in Dynatrace |
| Severity | How bad (Error, Availability, …) |
| Tags | Labels like `app:EIP` |

That open event **starts the create workflow** (if the workflow is Active and filters match).

### What “[Dynatrace Executions — create WF]” means

**Execution** = one run of the workflow. Open **Workflows → your create workflow → Executions** and you see that run with each step green or red.

Inside that run, four steps happen:

```
prepare → SNOW POST → PD trigger → cross-link
```

(In the real design, SNOW POST and PD trigger run **at the same time** after prepare. The diagram draws them in one line for simplicity.)

#### Step A — `prepare`

| Question | Answer |
| --- | --- |
| What does it do? | Reads the Problem and builds a packing list |
| Does it call SNOW or PD? | No |
| Why needed? | Later steps need the same IDs, app, group, runbook, priority |

It decides things like:

- App is EIP  
- Assignment group / business service for EIP  
- Priority feel P3 or P4  
- `dedup_key` = `dt-problem-P-12345`  

#### Step B — `SNOW POST` (create ServiceNow INC)

| Question | Answer |
| --- | --- |
| What does it do? | Creates a new Incident ticket in ServiceNow |
| How? | HTTP POST to ServiceNow (or ServiceNow connector) |
| Important field | `correlation_id` = Problem ID (`P-12345`) |

Think: “Write the incident report and stamp it with the alarm number.”

Result: something like `INC0012345`.

#### Step C — `PD trigger` (create PagerDuty alert)

| Question | Answer |
| --- | --- |
| What does it do? | Tells PagerDuty “page someone” |
| How? | POST to PagerDuty Events API |
| Important field | `dedup_key` = `dt-problem-P-12345` |

Think: “Call the fire crew and use the same alarm number so we can cancel later.”

#### Step D — `cross-link`

| Question | Answer |
| --- | --- |
| What does it do? | Adds a work note on the ServiceNow ticket |
| What is in the note? | The PagerDuty `dedup_key` + Dynatrace Problem URL + runbook |
| Why? | A human opening the INC can see which PD alert matches |

Think: “Write on the report: paging key is dt-problem-P-12345.”

### What the two boxes under create mean

```
[ServiceNow INC]          [PagerDuty alert]
  correlation_id            dedup_key
```

| Box | What you see in the real tool |
| --- | --- |
| ServiceNow INC | A ticket `INC…` with story, assignment, runbook text |
| `correlation_id` | Field on that ticket = `P-12345` |
| PagerDuty alert | A page/alert for on-call |
| `dedup_key` | Key = `dt-problem-P-12345` |

Same Problem, two systems, **related by ID family**:

```
Problem ID  P-12345
    │
    ├─► ServiceNow.correlation_id = P-12345
    └─► PagerDuty.dedup_key       = dt-problem-P-12345
```

---

## Half 2 — You close Problem

### What “You close Problem” means

The issue is fixed (or you close the test Problem). Dynatrace marks that Problem **Closed**. That event starts the **second** workflow (the close workflow).

You do **not** manually close SNOW and PD in the happy path. Dynatrace does it.

### What “[Dynatrace Executions — close WF]” means

Open **Workflows → your close workflow → Executions**. One new run appears.

That run does:

```
├─► resolve INC
└─► resolve PD
```

#### Resolve INC

1. Read Problem ID again (`P-12345`)  
2. Search ServiceNow: “find incident where `correlation_id` = P-12345”  
3. Set that INC to **Resolved**  

#### Resolve PD

1. Build the same key: `dt-problem-P-12345`  
2. Send PagerDuty `event_action: resolve` with that key  
3. The page stops / alert resolves  

Why the keys matter: without the same ID, close cannot find the right ticket or the right page.

---

## Full story as a timeline

| Time | What happens | Where to look |
| --- | --- | --- |
| T0 | Problem opens | Dynatrace Problems |
| T1 | Create workflow starts | Dynatrace Executions (create) |
| T2 | prepare finishes | Same execution, first task green |
| T3 | INC created + PD triggered | ServiceNow + PagerDuty |
| T4 | Work note added | ServiceNow work notes |
| T5 | You (or system) close Problem | Dynatrace Problems |
| T6 | Close workflow starts | Dynatrace Executions (close) |
| T7 | INC resolved + PD resolved | ServiceNow + PagerDuty |

---

## Why the diagram shows two Dynatrace Executions boxes

| Box | Workflow | When |
| --- | --- | --- |
| create WF | Workflow A | Problem **opens** |
| close WF | Workflow B | Problem **closes** |

They are **two separate robots**. One only creates. One only cleans up. That is intentional and easier to operate.

---

## Tiny glossary for this diagram only

| Word in diagram | Beginner meaning |
| --- | --- |
| Problem | Dynatrace “something broken” object |
| Executions | History of workflow runs |
| prepare | Build the packing list |
| SNOW POST | Create ServiceNow ticket |
| PD trigger | Start PagerDuty page |
| cross-link | Write PD key onto the ticket |
| correlation_id | “Alarm number” stored on the ticket |
| dedup_key | “Alarm number” used by PagerDuty |
| resolve INC | Close the ticket |
| resolve PD | Stop the page |

---

## Data flow map (same diagram, labeled)

```
YOU / Davis
  open Problem P-12345
        │
        ▼
CREATE WORKFLOW EXECUTION
  1 prepare (packing list)
  2a POST ServiceNow  → INC (correlation_id=P-12345)
  2b trigger PagerDuty → alert (dedup_key=dt-problem-P-12345)
  3 cross-link note on INC
        │
YOU / Davis
  close Problem P-12345
        │
        ▼
CLOSE WORKFLOW EXECUTION
  find INC by correlation_id=P-12345 → resolve
  resolve PD with dedup_key=dt-problem-P-12345
```

---

## Related files

| Path | Why |
| --- | --- |
| `../12-monitor-snow-pd-demo-steps/` | Where to click while demoing |
| `../13-how-to-open-close-workflow-flow/` | How to build it |
| `../10-snow-pd-keep-in-sync/` | Why the keys keep them aligned |
| `14.sh` | Reminders |

## Commands

See `14.sh` in this folder.
