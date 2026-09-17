# Pagerduty Explained Common Functions

```
Need to wake someone for an outage?
  → PagerDuty
       trigger alert → ack → investigate → resolve
       (your Dynatrace pack: trigger + resolve via Events API)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What it is | On-call paging system — rings the right person when something breaks |
| Not the same as ServiceNow | PD wakes humans; SNOW holds the ticket |
| Your automation | Dynatrace JS `POST /v2/enqueue` with `trigger` and `resolve` |
| Key glue | `routing_key` (which service) + `dedup_key` (same alert open/close) |

## Summary

PagerDuty is the phone that rings. Dynatrace detects the Problem, your workflow triggers a PD alert, on-call acknowledges and investigates (Dynatrace + Splunk), then resolve clears the page — automatically on Problem close or manually in PD.

---

## Investigation

User asked to explain PagerDuty and common functions to use, aligned with the Dynatrace→PD Events API path in the Connector+PD pack.

## Result

Learn Service / escalation / incident / Events API first, then the common functions: trigger, ack, resolve, snooze, reassign, suppress noise.

---

## 1) What PagerDuty is (plain English)

| Idea | What it means | Why you care |
| --- | --- | --- |
| PagerDuty | SaaS for on-call alerting and response | Gets a human online fast |
| Service | A PD “thing” you page (e.g. EIP checkout) | Has its own integration / routing key |
| Escalation policy | Who to page first, then next if no ack | Stops a single person being a single point of failure |
| Schedule / rotation | Who is on-call this week | Maps people to the policy |
| Incident / alert | The active page item | What you ack and resolve |
| Events API | Machine API to open/ack/resolve alerts | What Dynatrace Workflows call |

Analogy:

| Tool | Role |
| --- | --- |
| Dynatrace | Smoke detector |
| PagerDuty | Phone alarm |
| ServiceNow | Case file at the fire desk |
| Splunk | Camera footage (logs) |

---

## 2) Events API vs REST API (important)

| API | Host | What it is for | In your pack? |
| --- | --- | --- | --- |
| Events API v2 | `https://events.pagerduty.com/v2/enqueue` | Trigger / ack / resolve alerts with a **routing key** | Yes (trigger + resolve) |
| REST API | `https://api.pagerduty.com/...` | Manage services, users, schedules, list incidents | No (admin / other automation) |

Your workflow does **not** need a PD REST token for the current design — only the **routing key** (integration key).

---

## 3) Common functions (what they mean)

| Function | What it means | When you use it |
| --- | --- | --- |
| Trigger | Open / update an alert (page starts or intensifies) | Problem opens; automation or manual test |
| Acknowledge (ack) | “I see it; I’m working it” — stops escalation | First thing on-call does |
| Resolve | Clear the alert; stop paging | Issue fixed or Problem closed |
| Reassign | Hand the incident to someone else | Wrong person / need specialist |
| Escalate | Push to next level in policy | No progress / need broader help |
| Snooze | Temporarily pause notifications | Known short wait (use carefully) |
| Add note | Write what you did on the PD incident | Timeline for responders |
| Merge / related | Tie related incidents together | Multiple alerts, one outage |
| Suppress / maintenance | Reduce noise during planned work | Change windows |
| Override schedule | Temporarily change who is on-call | Sick day / swap |

---

## 4) How humans use them (PagerDuty UI / mobile)

### A) When you get paged

| Step | Function | What to do |
| --- | --- | --- |
| 1 | Open alert/incident | Mobile app or PD web |
| 2 | **Acknowledge** | Stops next escalation rung |
| 3 | Investigate | Dynatrace Problem + Splunk logs |
| 4 | Add note (optional) | “Checking deploy / rollback” |
| 5 | **Resolve** | When fixed (or wait for Dynatrace CLOSE automation) |

### B) If you cannot fix it alone

| Function | How to use |
| --- | --- |
| Reassign | Give to another responder / team service |
| Escalate | Force next escalation level per policy |

### C) If you are drowning in noise

| Function | How to use |
| --- | --- |
| Snooze | Short pause only — do not hide real outages |
| Maintenance / suppress | Planned change window on the service |
| Fix routing | Wrong service / too-sensitive Dynatrace severity → tune at source |

---

## 5) How YOUR Dynatrace pack uses PagerDuty

```
Problem OPEN
  prepare-payload → dedupKey = dt-problem-<id>
  → POST /v2/enqueue
       event_action: trigger
       routing_key: <integration key>
       dedup_key: dt-problem-<id>
       payload.summary / severity / custom_details

Problem CLOSE
  → POST /v2/enqueue
       event_action: resolve
       same routing_key + same dedup_key
```

| Function | Dynatrace task | Body field |
| --- | --- | --- |
| Trigger | `create-pagerduty-incident` | `event_action: trigger` |
| Resolve | `resolve-pagerduty` | `event_action: resolve` |
| Ack | Not automated in your pack | Human in PD app/UI |

### Setup once

| Step | What to do |
| --- | --- |
| 1 | In PagerDuty: create/use a **Service** with Events API v2 integration |
| 2 | Copy **Integration key** → paste as routing key in workflow (`__PD_ROUTING_KEY__` or example key) |
| 3 | Dynatrace **External requests** allowlist: `events.pagerduty.com` |
| 4 | Use stable `dedup_key` = `dt-problem-<problemId>` on open and close |
| 5 | Attach escalation policy + schedule to that Service |

### Fake example body (trigger)

| Field | Fake value |
| --- | --- |
| routing_key | `R03AMPLEFAKEROUTINGKEY00000000000` |
| event_action | `trigger` |
| dedup_key | `dt-problem-P-240917001` |
| payload.summary | `[Dynatrace] Failure rate increase on checkout API — EIP` |
| payload.severity | `error` |
| payload.source | `EIP` |

### Fake example body (resolve)

| Field | Fake value |
| --- | --- |
| routing_key | same as trigger |
| event_action | `resolve` |
| dedup_key | `dt-problem-P-240917001` |

If `dedup_key` differs between open and close, resolve will **not** clear the original page.

---

## 6) On-call cheat sheet

```
Phone ringing
  → Ack in PagerDuty
  → Open Dynatrace Problem from payload/link
  → Search Splunk for proof
  → Update ServiceNow INC notes
  → Fix
  → Resolve PD (or wait for Dynatrace CLOSE workflow)

Wrong team paged
  → Reassign / fix Service routing_key mapping

Page will not stop
  → Check dedup_key match, or Resolve manually in PD
  → Check Dynatrace Problem still OPEN

Never got a page but INC exists
  → Allowlist events.pagerduty.com
  → Check routing_key and workflow PD task logs
```

---

## 7) Common mistakes

| Mistake | What goes wrong |
| --- | --- |
| Wrong / test routing key in prod | Pages wrong service or nowhere |
| Different dedup_key on close | Resolve creates confusion; old alert stays |
| Forgot allowlist | Workflow PD task fails; SNOW still works |
| Never ack | Escalation keeps paging next people |
| Resolve while still broken | Silence without fix (dangerous) |
| Too many services / keys | Hard to know which key Dynatrace should use |

---

## 8) PD vs ServiceNow functions (side by side)

| Need | Use PagerDuty | Use ServiceNow |
| --- | --- | --- |
| Wake someone now | Trigger / page | — |
| Stop escalation | Ack | — |
| Official ticket / audit | — | Create / update INC |
| Clear the phone alert | Resolve | — |
| Clear the ticket | — | Resolve INC |
| Log root-cause evidence | Note (light) | Work notes + Splunk links |

Your pack does both: PD trigger‖SNOW create on open; both resolve on close.

---

## Data flow map

```
Dynatrace Problem OPEN
  → PD Events API trigger (routing_key + dedup_key)
  → Human: Ack → investigate → (optional) notes
Dynatrace Problem CLOSE
  → PD Events API resolve (same keys)

Parallel: ServiceNow INC create/resolve for the ticket trail
```

## Related files

| Path | Why |
| --- | --- |
| `../20-dynatrace-snow-pd-architecture/` | Full architecture |
| `../26-four-tools-common-example/` | Night outage story |
| `../24-dynatrace-external-links-allowlist/` | Grant `events.pagerduty.com` |
| `../19-snow-connector-workflow-again/` | YAML with PD tasks |
| `../28-snow-common-functions-how-to/` | SNOW twin guide |
| `29.sh` | Paths |

## Commands

See `29.sh` in this folder.
