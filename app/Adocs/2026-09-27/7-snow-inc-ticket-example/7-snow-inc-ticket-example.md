# Example SNOW Incident Ticket

```
Reading an INC — where to look first?
  Top bar        → number, state, priority        (how bad, where in lifecycle)
  Who            → assignment group, assigned to  (who owns it now)
  What / where   → short description, CI, service (what broke)
  Why / evidence → description, work notes        (facts and investigation)
  Timeline       → activity stream                (who did what, when)
  Close          → resolution code + notes        (how it was fixed)
```

## Short takeaway

| Question | Answer |
| --- | --- |
| Example ticket | `INC0098765` — Checkout API slow in prod |
| Created by | Dynatrace workflow via SILVA (`contact_type = monitoring`) |
| Priority | P3 (impact 2, urgency 2) |
| Lifecycle shown | New → In Progress → Resolved → Closed |
| Linked records | Problem `PRB0004321`, Change `CHG0031337` |

## Summary

Below is one realistic incident from start to finish: how the form looks in ServiceNow, how the timeline reads, and the same record as the API returns it. Use it as a reference for what a good auto-created ticket should contain.

## Investigation

Built from the enriched payload in `2026-09-27/6-enriched-inc-post-to-silva/` and standard SNOW incident fields.

## Result

Compare your real SILVA tickets to this example. Missing CI, team, or evidence usually means enrichment or CMDB gaps.

---

## 1) Form view (what you see in the browser)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Incident  INC0098765                                    [Update] [Resolve]   │
├──────────────────────────────────────────────────────────────────────────────┤
│ Number            INC0098765            Opened        2026-09-27 21:41:12    │
│ Caller            Tech_DynatraceJP_WS   Opened by     Tech_DynatraceJP_WS    │
│ Category          Software              Contact type  Monitoring             │
│ Subcategory       Performance           State         Resolved               │
│ Service           Online Payments       Impact        2 - Medium             │
│ Configuration item ip-10-20-3-41...     Urgency       2 - Medium             │
│                                         Priority      3 - Moderate           │
│ Assignment group  Payments SRE          Assigned to   Taro Yamada            │
├──────────────────────────────────────────────────────────────────────────────┤
│ Short description                                                            │
│   [Dynatrace][prod] Response time degradation on checkout-api                │
│ Description                                                                  │
│   Dynatrace problem: P-2609271234 (PERFORMANCE, impact level SERVICES)       │
│   Started: 2026-09-27T12:41:07Z                                              │
│   Link: https://abc12345.apps.dynatrace.com/.../problem/-4711..._V2          │
│   Root cause: checkout-api                                                   │
│   Host: ip-10-20-3-41.ap-northeast-1.compute.internal                        │
│   App: checkout   Env: prod   Owner: payments-sre                            │
│   Impacted: checkout-api, /api/v1/checkout, web-frontend                     │
│   Evidence: response time degradation, failure rate increase,                │
│             database connection pool exhausted                               │
│   Runbook: https://confluence.example.com/runbooks/checkout-latency          │
├──────────────────────────────────────────────────────────────────────────────┤
│ Related: Problem PRB0004321   Change CHG0031337   Correlation ID P-2609271234│
├──────────────────────────────────────────────────────────────────────────────┤
│ Resolution information                                                       │
│   Resolution code   Solved (Permanently)                                     │
│   Resolved by       Taro Yamada          Resolved   2026-09-27 22:18:40      │
│   Resolution notes  Rolled back checkout-api v2.3.1 to v2.3.0 (CHG0031337).  │
│                     DB pool max raised 20 → 40. Latency back to baseline.    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 2) Field by field

| Field | Value | What it means |
| --- | --- | --- |
| Number | `INC0098765` | Human ticket ID |
| sys_id | `46d44a2bdb1a3010a1b2c3d4e5f60718` | Internal ID used by the API |
| Caller | `Tech_DynatraceJP_WS` | Who reported it (the integration user) |
| Contact type | Monitoring | Created automatically, not by a person |
| Category | Software | Broad type |
| Subcategory | Performance | Narrower type |
| Service | Online Payments | Business service affected |
| Configuration item | `ip-10-20-3-41...` | Server from the CMDB |
| Impact | 2 - Medium | Some users affected |
| Urgency | 2 - Medium | Fix soon; workaround exists |
| Priority | 3 - Moderate | Calculated from impact and urgency |
| State | Resolved | Fixed; waiting to auto-close |
| Assignment group | Payments SRE | Owning team |
| Assigned to | Taro Yamada | Person working it |
| Short description | `[Dynatrace][prod] Response time degradation on checkout-api` | Title |
| Description | Problem facts | Static context |
| Correlation ID | `P-2609271234` | Dynatrace problem ID (sync key) |
| Problem | `PRB0004321` | Root-cause record |
| Caused by change | `CHG0031337` | The deploy that triggered it (or the rollback change) |
| Resolution code | Solved (Permanently) | How it ended |
| Resolution notes | Rollback and pool size fix | What was done |

---

## 3) Activity stream (timeline)

| Time (JST) | Who | Type | Entry |
| --- | --- | --- | --- |
| 21:41:12 | Tech_DynatraceJP_WS | Created | Incident opened from Dynatrace problem P-2609271234 via SILVA |
| 21:41:12 | Tech_DynatraceJP_WS | Work note | Top error logs (30 min): [412x] HikariPool-1 connection not available; [97x] timeout calling payment-gateway. Deployments (2 h): checkout-api v2.3.1 at 21:30 |
| 21:41:15 | System | Field change | Assignment group set to Payments SRE (from CI support group) |
| 21:41:20 | PagerDuty | Work note | PagerDuty incident Q1ABC23 triggered, dedup_key dt-problem-P-2609271234 |
| 21:44:02 | Taro Yamada | Field change | Assigned to Taro Yamada; State New → In Progress |
| 21:47:30 | Taro Yamada | Work note | Latency p95 1.8 s (baseline 250 ms). Error spike began 21:31, 1 minute after v2.3.1 deploy. Suspect new query holding DB connections |
| 21:52:10 | Taro Yamada | Work note | Emergency change CHG0031337 raised for rollback to v2.3.0 |
| 22:03:45 | Taro Yamada | Work note | Rollback complete. p95 dropping: 600 ms |
| 22:10:00 | Taro Yamada | Work note | DB pool max 20 → 40 as safety margin. p95 260 ms |
| 22:12:30 | Taro Yamada | Comment (customer-visible) | Checkout performance has recovered. Monitoring continues |
| 22:15:00 | Taro Yamada | Related record | Problem PRB0004321 created: new query in v2.3.1 holds connections |
| 22:18:40 | Tech_DynatraceJP_WS | Field change | Dynatrace problem closed; State In Progress → Resolved (auto) |
| 22:18:42 | PagerDuty | Work note | PagerDuty incident resolved |
| 2026-09-30 22:18 | System | Field change | State Resolved → Closed (auto after 3 days) |

Note the difference:

| Journal field | Who can see it | Use for |
| --- | --- | --- |
| Work notes | Internal IT staff only | Investigation, commands, evidence |
| Additional comments | The caller and users too | Customer-facing updates |

---

## 4) Times and SLA

| Metric | Value | How it is computed |
| --- | --- | --- |
| Opened | 21:41:12 | Ticket created |
| Acknowledged | 21:44:02 | First assigned or In Progress |
| MTTA | 2 min 50 s | Acknowledged minus opened |
| Resolved | 22:18:40 | State set to Resolved |
| MTTR | 37 min 28 s | Resolved minus opened |
| P3 SLA resolve target | 8 business hours (example) | Met |

---

## 5) The same record from the API

```
GET /api/now/v2/table/incident?sysparm_query=number=INC0098765&sysparm_display_value=true
```

```json
{
  "result": [
    {
      "sys_id": "46d44a2bdb1a3010a1b2c3d4e5f60718",
      "number": "INC0098765",
      "state": "Resolved",
      "impact": "2 - Medium",
      "urgency": "2 - Medium",
      "priority": "3 - Moderate",
      "category": "Software",
      "subcategory": "Performance",
      "contact_type": "Monitoring",
      "caller_id": { "display_value": "Tech_DynatraceJP_WS" },
      "opened_by": { "display_value": "Tech_DynatraceJP_WS" },
      "opened_at": "2026-09-27 21:41:12",
      "business_service": { "display_value": "Online Payments" },
      "cmdb_ci": { "display_value": "ip-10-20-3-41.ap-northeast-1.compute.internal" },
      "assignment_group": { "display_value": "Payments SRE" },
      "assigned_to": { "display_value": "Taro Yamada" },
      "short_description": "[Dynatrace][prod] Response time degradation on checkout-api",
      "description": "Dynatrace problem: P-2609271234 (PERFORMANCE, impact level SERVICES)\n...",
      "correlation_id": "P-2609271234",
      "correlation_display": "Dynatrace",
      "problem_id": { "display_value": "PRB0004321" },
      "caused_by": { "display_value": "CHG0031337" },
      "close_code": "Solved (Permanently)",
      "close_notes": "Rolled back checkout-api v2.3.1 to v2.3.0 (CHG0031337). DB pool max raised 20 to 40. Latency back to baseline.",
      "resolved_by": { "display_value": "Taro Yamada" },
      "resolved_at": "2026-09-27 22:18:40",
      "u_host": "ip-10-20-3-41.ap-northeast-1.compute.internal",
      "u_environment": "prod",
      "u_application": "checkout",
      "u_dynatrace_problem_url": "https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/-4711223344556677_1759000000000V2"
    }
  ]
}
```

Without `sysparm_display_value=true` you get raw values instead: `"state": "6"`, `"priority": "3"`, and sys_ids for reference fields.

| Field | Raw value | Display value |
| --- | --- | --- |
| state | `6` | Resolved |
| impact | `2` | 2 - Medium |
| priority | `3` | 3 - Moderate |
| assignment_group | `5e4d3c2b...` | Payments SRE |

---

## 6) What makes this a good ticket

| Quality | Where you see it |
| --- | --- |
| Title tells env, symptom, and component | Short description |
| Linked to real inventory | Configuration item and service |
| Right team without manual routing | Assignment group from CI |
| Evidence at creation | First work note with logs and deploy |
| Clear timeline | Work notes with numbers (p95, times) |
| Customer update separate from internal notes | Additional comment |
| Root cause tracked | Problem PRB0004321 |
| Fix traceable | Change CHG0031337 |
| Closed with what was done | Resolution notes |

## 7) Bad ticket for contrast

| Field | Bad value | Problem |
| --- | --- | --- |
| Short description | `Alert` | Says nothing |
| CI | empty | No owner or impact |
| Assignment group | Service Desk | Wrong team; delays |
| Work notes | none | Next shift starts from zero |
| Resolution notes | `fixed` | No learning, fails audit |

---

## Data flow map

```
Dynatrace problem P-2609271234
  → SILVA → INC0098765 (New, P3, Payments SRE, CI linked)
  → PagerDuty page → Taro acknowledges → In Progress
  → work notes (evidence) → Emergency CHG0031337 (rollback)
  → recovery → PRB0004321 opened for root cause
  → Dynatrace problem closes → INC Resolved (auto) → PD resolved
  → 3 days later → INC Closed
```

## Related files

| File | Role |
| --- | --- |
| `2026-09-27/6-enriched-inc-post-to-silva/` | Workflow that creates this kind of ticket |
| `2026-09-27/2-snow-priority-impact-urgency/` | Why impact 2 and urgency 2 give P3 |
| `2026-09-27/3-snow-apis-in-detail/` | API used to read it |
| `7.sh` | Read a real ticket (you run) |

## Commands

See `7.sh`.
