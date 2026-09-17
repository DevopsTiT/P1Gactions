# Four Tools Detailed Example

```
Detailed night outage walkthrough (all four tools)
  02:14 checkout 5xx spike
  02:15 Dynatrace Problem + SNOW INC + PD page
  02:16–02:35 human: Ack → DT scope → Splunk proof → fix
  02:40 Problem close → SNOW resolve + PD resolve
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| This doc | Full minute-by-minute expansion of seq 26 |
| Story | EIP checkout failure `P-240917001` / `INC0017788` / PD dedup `dt-problem-P-240917001` |
| Automates | Dynatrace Workflows → ServiceNow + PagerDuty |
| Manual | Ack in PD; investigate in Dynatrace + Splunk; apply fix |

## Summary

Same four-tool pattern as `26-four-tools-common-example`, but with setup prerequisites, exact fake payloads, what each screen shows, Splunk queries, API calls, and close-out. Use this when you want to rehearse the whole incident path.

Parent short version: `../26-four-tools-common-example/26-four-tools-common-example.md`

---

## Investigation

User pointed at seq 26 and asked to explain in detail with a detailed example. Expanded into a full runbook-style walkthrough using the fake data set from seq 21/22.

## Result

Follow §1–§10 as one continuous incident story. All values are **fake** for learning.

---

## 1) Scenario setup (before the outage)

### Business context

| Item | Fake value |
| --- | --- |
| App | EIP Checkout (payment “Pay” button) |
| Environment | `stg` (same pattern as prod) |
| Entity tags on services | `app:EIP`, `env:stg`, `team:payments` |
| On-call | EIP primary via PagerDuty schedule |

### Dynatrace already configured

| Item | Fake / example |
| --- | --- |
| Environment UI | `https://abc12345.apps.dynatrace.com` |
| OPEN workflow | Active — Problem CREATED/UPDATED/REOPENED |
| CLOSE workflow | Active — Problem CLOSED/RESOLVED |
| ServiceNow Connection | `SNOW-Silva-STG-Connector` → `https://silvastg.service-now.com` |
| Allowlist | `silvastg.service-now.com`, `events.pagerduty.com` |
| Classic `servicenowstg` | ITSM **OFF**, ITOM optional ON |
| PD routing key | `R03AMPLEFAKEROUTINGKEY00000000000` |
| assignMap EIP group sys_id | `11111111111111111111111111111111` |

### Why tags matter

When the Problem includes tag `app:EIP`, `prepare-payload` picks EIP assignment group, business service, L1/L2/L3, and runbook — not the default Ops row.

---

## 2) Minute-by-minute timeline (detailed)

| Time (JST) | Actor | Tool | What happens in detail |
| --- | --- | --- | --- |
| 02:14:10 | Users | App | “Pay” clicks start failing; checkout API returns HTTP 500 |
| 02:14:40 | OneAgent | Dynatrace | Error rate / failure rate metrics rise; traces show failing service |
| 02:15:05 | Davis | Dynatrace | Opens Problem `P-240917001` — *Failure rate increase on checkout API* — severity `ERROR`, status ACTIVE |
| 02:15:08 | Workflow OPEN | Dynatrace | Trigger matches; execution starts |
| 02:15:09 | prepare-payload | Dynatrace | Reads tags → `app=EIP`; sets impact `2`, urgency `3`, `dedupKey=dt-problem-P-240917001` |
| 02:15:12 | snow-create-incident | ServiceNow | Creates `INC0017788` assigned to `EIP-Support` |
| 02:15:12 | create-pagerduty-incident | PagerDuty | Events API `trigger` with same dedup key — phone/app rings |
| 02:15:15 | cross-link-snow-pd | ServiceNow | Work note on INC with PD dedup + Problem URL |
| 02:16:00 | On-call | PagerDuty | Wakes; **Acknowledges** alert (stops escalation) |
| 02:17:00 | On-call | ServiceNow | Opens `INC0017788`; sees auto description + runbook link |
| 02:18:00 | On-call | Dynatrace | Opens Problem URL; checks affected services, severity, recent deploy events |
| 02:20:00 | On-call | Splunk | Runs 5xx search; finds DB timeout / bad build id |
| 02:22:00 | On-call | ServiceNow | Work note: “Acked PD; DT P-240917001; Splunk shows DB timeout after deploy 1.8.4” |
| 02:28:00 | On-call + app owner | Fix | Rollback checkout deploy `1.8.4` → `1.8.3` |
| 02:35:00 | System | App | Error rate returns to normal |
| 02:40:00 | Davis | Dynatrace | Problem `P-240917001` → CLOSED |
| 02:40:05 | Workflow CLOSE | Dynatrace | Starts |
| 02:40:08 | snow-search + resolve | ServiceNow | Finds INC by `correlation_id=P-240917001`; resolves with auto notes |
| 02:40:08 | resolve-pagerduty | PagerDuty | Events API `resolve` same dedup — page clears |
| Next day | IM / SRE | ServiceNow | Postmortem link + timeline on INC |

Sync string used everywhere: `dt-problem-P-240917001` (PD) and Problem id `P-240917001` (SNOW correlation).

---

## 3) What Dynatrace shows (detailed)

### Problem card (fake)

| Field | Value |
| --- | --- |
| Display id | `P-240917001` |
| Title | Failure rate increase on checkout API |
| Severity | ERROR |
| Status | ACTIVE (later CLOSED) |
| Tags | `app:EIP`, `env:stg`, `team:payments` |
| URL | `https://abc12345.apps.dynatrace.com/#problems/problemdetails;pid=P-240917001` |

### What the on-call clicks

| Step | Action |
| --- | --- |
| 1 | Open Problem from PD/SNOW link |
| 2 | Read impacted services / root cause hints |
| 3 | Open failing service → **Traces** for 500s |
| 4 | Note start time `02:14` for Splunk window |
| 5 | After fix, confirm Problem moves to CLOSED |

### OPEN workflow tasks (order)

| Task | Result in this example |
| --- | --- |
| prepare-payload | Builds fields below |
| create-servicenow-incident | `INC0017788` |
| create-pagerduty-incident | PD alert open |
| cross-link-snow-pd | Comment written |

### prepare-payload output (fake)

| Field | Value |
| --- | --- |
| problemId | `P-240917001` |
| dedupKey | `dt-problem-P-240917001` |
| app | `EIP` |
| assignmentGroupName | `EIP-Support` |
| impact / urgency | `2` / `3` |
| pLevel | `P3` |
| pdSeverity | `error` |
| shortDescription | `[Dynatrace] Failure rate increase on checkout API — EIP` |
| runbookUrl | `https://confluence.example/runbooks/eip` |
| l1 / l2 / l3 | `EIP-L1` / `EIP-L2` / `EIP-L3` |

---

## 4) What ServiceNow shows (detailed)

### INC record (fake)

| Field | Value |
| --- | --- |
| number | `INC0017788` |
| short_description | `[Dynatrace] Failure rate increase on checkout API — EIP` |
| assignment_group | `EIP-Support` |
| impact / urgency | `2` / `3` |
| category / subcategory | `Software` / `Application` |
| correlation_id | `P-240917001` |
| caller | `Dynatrace Workflow` |

### Description text (what automation wrote)

```
Caller: Dynatrace Workflow (auto)
Business service: EIP Checkout (sys_id=22222222222222222222222222222222)
App: EIP
Priority intent: P3 (impact=2, urgency=3)

Dynatrace Problem: https://abc12345.apps.dynatrace.com/#problems/problemdetails;pid=P-240917001
Problem ID: P-240917001

Who can help:
- L1: EIP-L1
- L2: EIP-L2
- L3: EIP-L3

Runbook / SOP: https://confluence.example/runbooks/eip
```

### Work note after cross-link (fake)

```
PagerDuty sync: dedup_key=dt-problem-P-240917001
| Dynatrace Problem=https://abc12345.apps.dynatrace.com/#problems/problemdetails;pid=P-240917001
| Runbook=https://confluence.example/runbooks/eip
| Problem ID=P-240917001
```

### Human work note at 02:22 (example)

```
Acked PD. Confirmed DT Problem P-240917001 on checkout service.
Splunk: DB connection timeout after deploy checkout-api:1.8.4.
Action: rolling back to 1.8.3 with app owner.
```

### On resolve (02:40, automation)

| Field | Value |
| --- | --- |
| Resolution code | `Solved (Permanently)` |
| Resolution notes | `Resolved automatically: Dynatrace Problem closed (P-240917001)` |
| State | Resolved |

### APIs

| Step | Call |
| --- | --- |
| Create | `POST https://silvastg.service-now.com/api/now/v2/table/incident` |
| Comment | `PUT https://silvastg.service-now.com/api/now/v2/table/incident/{sys_id}` |
| Search | `GET .../incident?sysparm_query=correlation_id=P-240917001&sysparm_limit=1` |
| Resolve | `PUT .../incident/{sys_id}` |

---

## 5) What PagerDuty shows (detailed)

### Trigger body (fake)

```json
{
  "routing_key": "R03AMPLEFAKEROUTINGKEY00000000000",
  "event_action": "trigger",
  "dedup_key": "dt-problem-P-240917001",
  "client": "Dynatrace",
  "client_url": "https://abc12345.apps.dynatrace.com/#problems/problemdetails;pid=P-240917001",
  "payload": {
    "summary": "[Dynatrace] Failure rate increase on checkout API — EIP",
    "source": "EIP",
    "severity": "error",
    "component": "EIP",
    "group": "EIP-Support",
    "class": "dynatrace-problem",
    "custom_details": {
      "problem_id": "P-240917001",
      "business_service": "EIP Checkout",
      "priority_intent": "P3",
      "runbook": "https://confluence.example/runbooks/eip"
    }
  }
}
```

### Resolve body (fake)

```json
{
  "routing_key": "R03AMPLEFAKEROUTINGKEY00000000000",
  "event_action": "resolve",
  "dedup_key": "dt-problem-P-240917001"
}
```

### Human actions

| Time | Action |
| --- | --- |
| 02:16 | Acknowledge (stops escalation to next rung) |
| 02:16–02:40 | Optional notes in PD |
| 02:40 | Auto-resolve from Dynatrace (or manual if automation missed) |

API both times: `POST https://events.pagerduty.com/v2/enqueue`

---

## 6) What Splunk shows (detailed)

Splunk is **not** called by the Dynatrace Workflow in this pattern. The human uses it after ack.

### Why Splunk here

| Dynatrace gave you | Splunk gives you |
| --- | --- |
| “Checkout failure rate is up” | Exact log line: DB timeout, stack, request id, deploy version |

### Example searches (fake)

**Broad 5xx window matching Problem start:**

```
index=app_eip sourcetype=checkout_api status>=500 earliest=02/14/2026:02:10:00 latest=02/14/2026:02:40:00
| stats count by status, error_message
| sort -count
```

**Find deploy correlation:**

```
index=app_eip sourcetype=checkout_api earliest=02/14/2026:02:10:00 latest=02/14/2026:02:40:00
| search "timeout" OR "SQLException" OR "deploy"
| table _time, request_id, status, message, build_version
| sort _time
```

**Fake smoking-gun line:**

```
2026-09-17 02:14:22 ERROR request_id=req-9f3a checkout-api build=1.8.4
SQLException: Connection timed out acquiring pool connection to payments-db
```

### What to paste back into ServiceNow

Request id `req-9f3a`, build `1.8.4`, error type, and link to Splunk job — so the INC has evidence, not only “we rolled back.”

---

## 7) Fix and recovery (outside the four tools’ APIs)

| Step | Detail |
| --- | --- |
| Decision | Rollback `checkout-api` `1.8.4` → `1.8.3` |
| Who | On-call + app owner |
| Verify | Dynatrace error rate down; Splunk 5xx stop; synthetic Pay OK |
| Expect | Davis closes Problem within minutes → CLOSE workflow runs |

---

## 8) CLOSE workflow detail

| Task | What it does with fake data |
| --- | --- |
| prepare-close-ids | `problemId=P-240917001`, `dedupKey=dt-problem-P-240917001` |
| search-snow-incident | Query `correlation_id=P-240917001` → finds `INC0017788` |
| resolve-snow-incident | Resolves that INC |
| resolve-pagerduty | `event_action=resolve` same dedup |

If search returns empty (bad correlation), SNOW resolve is skipped; PD resolve can still run from prepare-close-ids — then fix correlation for next time and resolve INC manually.

---

## 9) Full API sequence for this example

```
OPEN
  (internal) Davis Problem event
  (internal) prepare-payload JS
  POST https://silvastg.service-now.com/api/now/v2/table/incident
  POST https://events.pagerduty.com/v2/enqueue          # trigger
  PUT  https://silvastg.service-now.com/api/now/v2/table/incident/{sys_id}

HUMAN
  PagerDuty UI: acknowledge
  Dynatrace UI: problem analysis
  Splunk: /services/search/jobs (or UI search)
  ServiceNow UI: work notes

CLOSE
  (internal) Problem closed event
  (internal) prepare-close-ids JS
  GET  https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=correlation_id=P-240917001
  PUT  https://silvastg.service-now.com/api/now/v2/table/incident/{sys_id}
  POST https://events.pagerduty.com/v2/enqueue          # resolve
```

---

## 10) Same story — what good looks like vs broken

| Checkpoint | Good | Broken |
| --- | --- | --- |
| 02:15 | One INC + one PD alert | Two INCs (classic ITSM still ON) |
| 02:15 | PD rings | INC only (PD allowlist/key missing) |
| 02:15 | INC exists | PD only (SNOW Connection/allowlist missing) |
| 02:18 | Problem link works | No link in ticket/page |
| 02:20 | Splunk shows error lines | Guessing without logs |
| 02:40 | INC + PD both clear | PD stuck (dedup mismatch) or INC stuck (correlation mismatch) |

---

## 11) On-call script (copy-ready)

```
1. Ack PagerDuty
2. Open INC0017788 (or search correlation_id = Problem id)
3. Open Dynatrace Problem from link — note start time + impacted service
4. Splunk: index=app_eip status>=500 around Problem start
5. Write SNOW work note with request_id + build + hypothesis
6. Fix/rollback with owner; verify DT metrics + Splunk
7. Confirm Problem CLOSED → INC Resolved + PD cleared
8. If CLOSE missed something: resolve leftover INC/PD manually; fix keys
```

---

## Data flow map

```
Users Pay fail
  → Dynatrace metrics/traces
  → Problem P-240917001 OPEN
        ├─► ServiceNow INC0017788 (create + comment)
        └─► PagerDuty alert (trigger)
              → Human Ack
              → Dynatrace scope
              → Splunk proof
              → Rollback
  → Problem CLOSED
        ├─► ServiceNow resolve
        └─► PagerDuty resolve

Evidence trail: Splunk logs + SNOW work notes + DT Problem history
```

## Related files

| Path | Why |
| --- | --- |
| `../26-four-tools-common-example/` | Short parent version |
| `../20-dynatrace-snow-pd-architecture/` | Architecture |
| `../22-yaml-with-all-example-data/` | YAML with same fake keys |
| `../21-workflow-parameter-fake-data/` | Parameter tables |
| `../23-architecture-all-apis-involved/` | API list |
| `31.sh` | Paths |

## Commands

See `31.sh` in this folder.
