# Four Tools Common Example

```
App breaks at night
  │
  ├─ Dynatrace detects → opens Problem
  ├─ Workflow → ServiceNow INC (ticket)
  ├─ Workflow → PagerDuty (page on-call)
  └─ On-call uses Splunk (search logs) to find root cause
       then fix → Problem closes → INC + PD resolve
```

## Short takeaway

| Tool | Role in the example | When you use it |
| --- | --- | --- |
| Dynatrace | Sees the outage and opens/closes the Problem | Always first (detect) |
| ServiceNow | Holds the Incident ticket for tracking/handoff | Auto-created on Problem open |
| PagerDuty | Rings the on-call phone | Auto-paged in parallel with INC |
| Splunk | Where you search logs to prove root cause | After you wake up / during investigate |

## Summary

A common SRE pattern: Dynatrace detects, ServiceNow tracks, PagerDuty wakes someone, Splunk explains why. Your Connector workflows automate the middle two; Splunk stays a human (or separate automation) investigation step.

---

## Investigation

User asked for a common example using all four items (Dynatrace, ServiceNow, PagerDuty, Splunk) together, matching the architecture and API packs from today.

## Result

Use the checkout/EIP story below as the teaching example. It maps cleanly to your OPEN/CLOSE workflows plus a Splunk search during triage.

---

## 1) What each tool is for (one sentence)

| Tool | Plain English |
| --- | --- |
| Dynatrace | “Something is wrong with the app right now.” |
| ServiceNow | “Here is the official ticket so we can track work.” |
| PagerDuty | “Wake the right person now.” |
| Splunk | “Show me the logs that explain why.” |

They are not duplicates. Mixing them up causes either no page, no ticket, or no evidence.

---

## 2) Common story (fake but realistic)

**Scene:** Payment checkout (app tag `EIP`) starts failing at 02:14 JST.

| Time | What happens | Which tool |
| --- | --- | --- |
| 02:14 | Error rate spikes on checkout API | Dynatrace sees metrics/traces |
| 02:15 | Davis opens Problem `P-240917001` | Dynatrace |
| 02:15 | OPEN workflow runs | Dynatrace Workflows |
| 02:15 | INC `INC0017788` created, group `EIP-Support` | ServiceNow |
| 02:15 | Alert fires with dedup `dt-problem-P-240917001` | PagerDuty |
| 02:16 | On-call acks the page | PagerDuty |
| 02:18 | On-call opens Problem URL from ticket/page | Dynatrace |
| 02:20 | On-call searches logs for request ids / 5xx | Splunk |
| 02:35 | Finds bad deploy / DB timeout in logs; rolls back | Fix outside these tools |
| 02:40 | Error rate recovers; Problem closes | Dynatrace |
| 02:40 | CLOSE workflow resolves INC + resolves PD | ServiceNow + PagerDuty |
| Later | Postmortem notes attach to INC | ServiceNow |

Fake sync key everywhere: `dt-problem-P-240917001`.

---

## 3) Happy-path flow (pic)

```
[User clicks Pay] → checkout API errors
        │
        ▼
[Dynatrace] Problem OPEN P-240917001
        │
        ├──────────────────┐
        ▼                  ▼
[ServiceNow]            [PagerDuty]
 INC0017788              page on-call
 ticket + assign group   phone / app alert
        │                  │
        └────────┬─────────┘
                 ▼
        [Human investigates]
                 │
                 ├─ Dynatrace UI (who/what is broken)
                 └─ Splunk (logs / proof)
                 │
                 ▼
              [Fix applied]
                 │
                 ▼
[Dynatrace] Problem CLOSED
        │
        ├──────────────────┐
        ▼                  ▼
[ServiceNow] resolve INC  [PagerDuty] resolve alert
```

---

## 4) What each person does

| Role | Uses | Example action |
| --- | --- | --- |
| Platform / SRE (setup) | Dynatrace Workflows + Connection + allowlist | Upload OPEN/CLOSE YAML; grant hosts |
| On-call engineer | PagerDuty → Dynatrace → Splunk → ServiceNow | Ack page, confirm scope, search logs, update ticket |
| Incident manager | ServiceNow | Track timeline, severity, handoff |
| App owner | Dynatrace + Splunk | Confirm deploy, fix code/config |

---

## 5) Fake data for this example

| Field | Fake value |
| --- | --- |
| App tag | `app:EIP` |
| Problem | `P-240917001` — Failure rate increase on checkout API |
| SNOW INC | `INC0017788` |
| Assignment group | `EIP-Support` |
| PD dedup_key | `dt-problem-P-240917001` |
| Splunk search (idea) | `index=app_eip sourcetype=checkout_api status>=500 earliest=-30m` |

You do **not** need Splunk in the Dynatrace allowlist for this pattern unless a Workflow itself calls Splunk.

---

## 6) Which APIs fire in this example

| Step | API |
| --- | --- |
| Create ticket | `POST https://silvastg.service-now.com/api/now/v2/table/incident` |
| Page | `POST https://events.pagerduty.com/v2/enqueue` (`trigger`) |
| Cross-link comment | `PUT .../api/now/v2/table/incident/{sys_id}` |
| Log dig | Splunk `POST/GET /services/search/jobs...` (human or script) |
| Close ticket | `GET` then `PUT` SNOW incident |
| Clear page | `POST .../v2/enqueue` (`resolve`) |

---

## 7) Common mistakes (same story)

| Mistake | What goes wrong |
| --- | --- |
| No Dynatrace Problem | Nothing auto-creates INC/PD |
| Classic ITSM ON + Connector create | Two ServiceNow tickets |
| PD allowlist missing | Ticket exists, nobody is paged |
| SNOW allowlist missing | Page exists, no ticket |
| Skip Splunk | You guess root cause with no log proof |
| Different dedup/correlation keys | Close does not clear PD or find INC |

---

## 8) Mini decision tree — which tool now?

```
Just woke up from a page?
  → PagerDuty (ack) → Dynatrace (scope) → Splunk (logs) → ServiceNow (update)

Need official handoff / audit?
  → ServiceNow

Need to know if still broken?
  → Dynatrace Problem status

Need exact error line / request id?
  → Splunk
```

---

## Data flow map

```
Detect:     Dynatrace Problem
Notify:     PagerDuty page  ‖  ServiceNow INC
Investigate:Dynatrace UI + Splunk SPL
Recover:    Fix → Dynatrace close → SNOW resolve + PD resolve
Evidence:   stays in Splunk + INC work notes
```

## Related files

| Path | Why |
| --- | --- |
| `../31-four-tools-detailed-example/` | **Detailed** minute-by-minute expansion (payloads, Splunk, APIs) |
| `../20-dynatrace-snow-pd-architecture/` | Full architecture |
| `../25-four-tools-api-catalog/` | APIs for all four |
| `../19-snow-connector-workflow-again/` | Automates SNOW+PD |
| `../8-splunk-query-top10-examples/` | Splunk query patterns |
| `26.sh` | Paths |

## Commands

See `26.sh` in this folder.
