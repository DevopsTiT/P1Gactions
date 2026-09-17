# Dynatrace Sre Jobs Day To Day

```
SRE day-to-day Dynatrace jobs (from §5)
  │
  ├─ A) Deploy monitoring
  ├─ B) Detect and triage
  ├─ C) Automate ticket + page (SNOW + PD)
  └─ D) Investigate with other tools
```

## Short takeaway

| Job | Goal | Done when |
| --- | --- | --- |
| Deploy monitoring | New app/host visible and tagged | Services show in UI with `app` tag |
| Detect and triage | Understand a live Problem | You know impact, likely cause, next action |
| Automate ticket + page | Problem opens INC + PD; close syncs | Test Problem creates/resolves both |
| Investigate with other tools | Use DT + SNOW + PD + Splunk correctly | Evidence in Splunk; ticket updated; page acked |

## Summary

This is a detailed expansion of **§5 Day-to-day how to use (SRE jobs)** from `30-dynatrace-components-how-to-use.md`. Each job has why it matters, step-by-step clicks, fake examples, and common failures.

Parent: `../30-dynatrace-components-how-to-use/30-dynatrace-components-how-to-use.md`

---

## Investigation

User asked to explain §5 of the Dynatrace components guide in detail. Expanded all four SRE jobs into runbook-style steps aligned with the Connector + PagerDuty pack.

## Result

Use Jobs A–D below as the day-to-day operating guide.

---

## Job A — Deploy monitoring

### What this is

Get Dynatrace to **see** a host, Kubernetes workload, or service so Davis can open Problems later.

### Why it matters

No OneAgent / no data → no Problem → no ticket, no page.

### Steps (host / VM)

| Step | What to do | What good looks like |
| --- | --- | --- |
| 1 | Pick the host that runs the app | Known hostname / IP |
| 2 | Install OneAgent (Linux/Windows installer from Dynatrace) | Installer finishes without error |
| 3 | Wait a few minutes | Host appears under **Infrastructure → Hosts** |
| 4 | Confirm processes/services | App process listed; service may auto-appear |
| 5 | Add tags | e.g. `app:EIP`, `env:stg`, `team:payments` |

### Steps (Kubernetes)

| Step | What to do | What good looks like |
| --- | --- | --- |
| 1 | Install Dynatrace Operator / OneAgent on the cluster | Operator pods Running |
| 2 | Ensure namespace/workloads are monitored | Pods/services visible |
| 3 | Map K8s labels to Dynatrace tags (rules) | `app:EIP` shows on service entities |
| 4 | Check ActiveGate if cluster cannot talk outbound directly | Metrics still arrive |

### Tagging (critical for YOUR workflows)

| Tag | Fake example | Why |
| --- | --- | --- |
| `app` | `EIP` | assignMap picks EIP-Support group |
| `env` | `stg` | Filter noise; know environment |
| `team` | `payments` | Ownership |

Without `app:EIP`, prepare-payload falls through to **default** Ops mapping.

### Verify checklist

| Check | Pass |
| --- | --- |
| Host/service in UI | Yes |
| Metrics updating | Yes |
| Tag `app` present on entity | Yes |
| Optional: generate traffic and see traces | Yes |

### Common failures

| Symptom | Likely cause |
| --- | --- |
| Host never appears | Install failed, wrong env ID, firewall |
| Host appears, no deep service | Process not injected / unsupported runtime |
| Tags missing | Never set; K8s label rules not configured |

---

## Job B — Detect and triage

### What this is

When something breaks (or you are on-call), use **Problems** to understand scope fast.

### Why it matters

This is how you decide: page already fired — is it real, how big, where to dig next?

### Steps — every Problem

| Step | Where | What to do |
| --- | --- | --- |
| 1 | **Problems** | Open list; filter Open / your management zone |
| 2 | Problem card | Read title, severity, start time, status |
| 3 | Impacted entities | Which services/hosts are affected? |
| 4 | Root cause / evidence | Davis hints — treat as lead, not gospel |
| 5 | Analyze → metrics | Error rate, latency, saturation |
| 6 | Analyze → traces | Open a failing trace; note request path |
| 7 | Logs (if in Dynatrace) | Quick log peek; else jump to Splunk with start time |
| 8 | Decide | Fix now, escalate, or watch |

### Fake example triage (EIP checkout)

| Field | What you see |
| --- | --- |
| Problem | `P-240917001` Failure rate increase on checkout API |
| Severity | ERROR |
| Tag | `app:EIP` |
| Start | 02:14 JST |
| Next | Traces show 500s → copy start time → Splunk |

### Optional DQL / Notebooks

| When | How |
| --- | --- |
| Need custom query across logs/events | Open **Notebooks** / Query; write DQL |
| Need a reusable dig | Save notebook for the team |

### Common failures

| Symptom | Likely cause |
| --- | --- |
| No Problem but users complain | Synthetic gap, wrong MZ filter, Davis suppressed |
| Too many Problems | Noise; tune alerting / management zones |
| Cannot see Problem | Permission / management zone |

---

## Job C — Automate ticket + page (your pack)

### What this is

Wire Dynatrace so a Problem **automatically** creates a ServiceNow INC and a PagerDuty alert, and closes both when the Problem closes.

### Why it matters

Removes “forgot to open a ticket” and “nobody got paged” toil — with one sync key.

### Prerequisites

| Item | Example |
| --- | --- |
| ServiceNow Connector app installed | Hub → ServiceNow |
| SNOW integration user ready | Can create/update `incident` |
| PD Service + Events API key | Routing key |
| Workflow permissions | Can create/activate Workflows |

### Step-by-step setup

| Step | Where | What to do | Fake example |
| --- | --- | --- | --- |
| 1 | Settings → Connections → ServiceNow | Create Connection | Name `SNOW-Silva-STG-Connector`, URL `https://silvastg.service-now.com`, user/password |
| 2 | Settings → External requests | Allowlist hosts | `silvastg.service-now.com`, `events.pagerduty.com` |
| 3 | Problem notifications | Classic `servicenowstg` | **ITSM OFF** (ITOM optional ON) |
| 4 | Workflows | Upload OPEN YAML | Seq 19 or 22 example-filled |
| 5 | Workflows | Upload CLOSE YAML | Same pack |
| 6 | Each snow task | Map Connection | Same Connection on create/comment/search/resolve |
| 7 | JS PD tasks | Set routing key | Replace placeholder with real key |
| 8 | assignMap | Set real group/biz sys_ids | EIP/CCI/default |
| 9 | Activate both workflows | isActive true | — |
| 10 | Test | Open a test Problem or wait for one | Check Executions |

### What “good” test looks like

| Check | Pass |
| --- | --- |
| OPEN execution all tasks OK | Yes |
| New INC in SNOW with correlation_id = Problem id | Yes |
| PD alert with dedup `dt-problem-<id>` | Yes |
| INC work note has PD key + Problem URL | Yes |
| On Problem close: INC resolved + PD resolved | Yes |
| Only **one** INC (not two) | Yes |

### Day-to-day operate (after setup)

| Task | How |
| --- | --- |
| Watch failed runs | Workflows → **Executions** |
| Fix allowlist/Connection | Re-test one Problem |
| Change routing (new app) | Add assignMap row + tags on entities |
| Rotate PD key | Update OPEN + CLOSE JS; keep same dedup scheme |

### Common failures

| Symptom | Fix |
| --- | --- |
| Host not allowed | External requests |
| Auth failed to SNOW | Connection credentials / SNOW roles |
| PD task fails, SNOW OK | PD key or `events.pagerduty.com` allowlist |
| Two INCs | Turn classic ITSM OFF |
| Close cannot find INC | correlation_id mismatch on create vs search |

---

## Job D — Investigate with other tools

### What this is

Use the **right tool for each question** during an incident — Dynatrace alone is not the whole response.

### Why it matters

Wrong tool = slow MTTR (searching Splunk for topology, or using PD as the ticket system).

### Decision table

| Question | Use this | How |
| --- | --- | --- |
| What is broken right now? | Dynatrace Problem + Smartscape | Problem card → impacted entities |
| Who was woken? | PagerDuty | Ack status / responders |
| Where is the official record? | ServiceNow INC | Number, assignment, work notes |
| Exact error line / request id? | Splunk (or DT logs if that is your log home) | SPL around Problem start time |
| Is it still broken? | Dynatrace | Problem still OPEN? error rate down? |

### On-call sequence (detailed)

| Order | Tool | Action |
| --- | --- | --- |
| 1 | PagerDuty | **Acknowledge** |
| 2 | ServiceNow | Open INC from number or `correlation_id` |
| 3 | Dynatrace | Open Problem URL from INC/PD |
| 4 | Dynatrace | Note start time, service name, severity |
| 5 | Splunk | Search 5xx / errors for that service and window |
| 6 | ServiceNow | Work note: evidence + hypothesis + action |
| 7 | Fix | Rollback/config/scale (outside these UIs) |
| 8 | Dynatrace | Confirm recovery → Problem closes |
| 9 | SNOW + PD | Confirm auto-resolve (or resolve manually) |

### Fake Splunk pivot from a Problem

Problem start `02:14`, service checkout / tag EIP:

```
index=app_eip sourcetype=checkout_api status>=500 earliest=-30m
| table _time, request_id, status, message, build_version
| sort _time
```

### What not to do

| Anti-pattern | Why |
| --- | --- |
| Only ack PD and never open DT | No scope |
| Only look at SNOW | No live telemetry |
| Skip Splunk when logs live there | No proof |
| Create a second INC by hand | Duplicate with Connector |

---

## How the four jobs connect (week in the life)

```
Monday: Job A — onboard new checkout service + tags
Tuesday: Job C — verify Workflows still green after key rotation
Wednesday 02:15: Job B + D — real Problem, triage + Splunk
Thursday: Job C — read failed Execution, fix allowlist typo
Friday: Job A — tag env:prod on missed entities
```

---

## Mini decision tree (which job am I doing?)

```
New host/app not in Dynatrace?
  → Job A Deploy monitoring

Phone ringing / Problem open?
  → Job B Detect and triage
  → Job D Investigate with other tools

No ticket or no page when Problem opens?
  → Job C Automate ticket + page (broken or not set up)

Need evidence for RCA?
  → Job D (Splunk + SNOW notes)
```

---

## Data flow map

```
Job A: Install + tag
        → data flows into Dynatrace

Job B: Problem appears
        → human reads Problem card

Job C: Problem event
        → Workflow → SNOW INC ‖ PD page
        → on close → resolve both

Job D: Human path
        PD ack → DT scope → Splunk proof → SNOW notes → fix
```

## Related files

| Path | Why |
| --- | --- |
| `../30-dynatrace-components-how-to-use/` | Parent components guide (§5 source) |
| `../31-four-tools-detailed-example/` | Full incident story for Jobs B+D |
| `../19-snow-connector-workflow-again/` | YAML for Job C |
| `../24-dynatrace-external-links-allowlist/` | Allowlist for Job C |
| `../28-snow-common-functions-how-to/` | SNOW side of Job D |
| `../29-pagerduty-explained-common-functions/` | PD side of Job D |
| `32.sh` | Paths |

## Commands

See `32.sh` in this folder.
