# Dynatrace ServiceNow Manage And Example

```
Need Dynatrace + ServiceNow?
  │
  ├─ Want tickets from Problems? → Incident integration (or Workflows)
  ├─ Want raw events for ITOM rules? → Event Management
  ├─ Want hosts/services in inventory? → CMDB / Service Graph Connector
  └─ Day-2 manage → alerting profile + test notify + CI match + close sync
```

| Question | Answer |
| --- | --- |
| What it is | Dynatrace detects problems; ServiceNow records tickets and CIs |
| Three lanes | **Incident**, **Events (ITOM)**, **CMDB** |
| How you manage | Who gets tickets, noise filters, CI matching, close/resolve sync |
| Example below | EIP checkout latency → Davis Problem → Incident INC00xxxx → fix → resolve |

## Summary

**Dynatrace** watches apps and opens a **Problem** with Davis root cause. **ServiceNow** is where the company logs **Incidents** and keeps a **CMDB** (list of servers and apps). You connect them so every important Problem becomes a ticket on the right CI, and when Dynatrace closes the Problem the ticket can resolve. Management means controlling **noise**, **assignment**, and **CI accuracy** — not just turning the integration on.

---

## 1. What this is (beginner)

| Piece | What it means | Why you care |
| --- | --- | --- |
| Dynatrace Problem | Grouped alert with impact + root cause | Truth of “what broke” |
| ServiceNow Incident | Work ticket for humans | Ownership, SLA, audit |
| CMDB CI | Config item (host, service, app) | Ticket must hang on the right object |
| Problem notification | Dynatrace push when Problem opens/updates/closes | The “wire” into ServiceNow |
| Alerting profile | Which Problems are allowed to notify | Stops ticket floods |

```
Dynatrace (eyes + brain)
        │
        ▼
Problem notification (filtered)
        │
        ├─► ServiceNow Incident  (ITSM)
        ├─► ServiceNow Events    (ITOM, optional)
        └─► CMDB sync            (inventory, often scheduled pull)
```

Official overview:  
https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/servicenow-integration

---

## 2. Three integration types (pick what your org licensed)

| Type | License flavor | What you get | Typical owner |
| --- | --- | --- | --- |
| **Incident** | ServiceNow ITSM + Dynatrace Incident Integration app (or Workflows) | Each Problem → Incident | SRE + ITSM admin |
| **Event Management** | ServiceNow ITOM | Events into `em_event`; rules decide tickets | ITOM / Event Mgmt |
| **CMDB / Service Graph** | Service Graph Connector for Observability – Dynatrace | Hosts, processes, services, apps → CIs + service map | CMDB admin + platform |

You can run **Incident only**, or Incident **plus** CMDB (best: ticket auto-links CI).

---

## 3. How to manage (day-2 checklist)

### A. Dynatrace side

| Manage what | What to do | Healthy look |
| --- | --- | --- |
| Problem notification | Settings → Integration → Problem notifications → ServiceNow | Test notification succeeds |
| Alerting profile | Only prod / only Critical+Error / correct MZ | STG noise does not create prod tickets |
| Payload / description | Include Problem URL, severity, impacted entities | Ticket is actionable without guessing |
| Multi-env | Separate notifications or env tags for STG vs PROD | Wrong env never pages prod group |
| Close behavior | Confirm close updates ServiceNow | No zombie open tickets |

**Create / check notification (UI path):**

1. Dynatrace → **Settings** → **Integration** → **Problem notifications**
2. **Add notification** → type **ServiceNow**
3. Fill instance id (`https://<id>.service-now.com`) or on-prem URL
4. Enable **Send incidents into ServiceNow ITSM** (and/or ITOM events if used)
5. Attach an **alerting profile** (prod only)
6. **Send test notification** → **Save**

### B. ServiceNow side

| Manage what | What to do | Healthy look |
| --- | --- | --- |
| Dynatrace Incident Integration app | Store app + Guided Setup | Problems appear in import set then Incident |
| Transform map | Problem → Incident field mapping | Priority, short description, work notes correct |
| Assignment | Route by CI / assignment group / business service | EIP apps → EIP support group |
| CMDB sync job | Service Graph / scheduled pull from Dynatrace API | Hosts/services exist as CIs |
| Identity rules | Deduplicate CIs (e.g. by hostname) | No duplicate servers |
| Roles | Integration user rights only | Least privilege |

### C. Operating rules (SRE practice)

| Rule | Why |
| --- | --- |
| Never send **All problems, all envs** to ServiceNow | Ticket storm |
| Tag Dynatrace entities (`env:prod`, `app:eip`) | Filter + CMDB matching |
| One Problem ↔ one Incident (update on change) | Avoid duplicates |
| On-call opens **Problem URL** from ticket | Davis RCA stays source of truth |
| After fix, wait for Problem auto-close then confirm Incident Resolved | Closed-loop |

### D. Weekly hygiene

| Check | Pass means |
| --- | --- |
| Test notification | Still 200 / incident created |
| Open Incidents from Dynatrace | Count matches open Problems (roughly) |
| Orphan tickets | No Incident without Problem URL for DT-sourced items |
| CI link rate | Most prod Incidents have Affected CI |
| Noise | No STG/low severity flooding prod queue |

---

## 4. Detailed example (EIP checkout latency)

**Story:** Payment/EIP checkout gets slow. You want one ServiceNow Incident with the right CI and Davis root cause link — not five emails.

### Actors

| Role | Tool |
| --- | --- |
| Shopper | Slow checkout page |
| Dynatrace | Detects Problem, Davis says DB query slow on `eip-checkout` |
| ServiceNow | Creates INC0012345 for group **EIP-Support** |
| On-call SRE | Works Incident, uses Dynatrace for RCA |
| DBA / app owner | Fixes index / rolls back bad deploy |

### Timeline

| Time | What happens |
| --- | --- |
| T+0 | Checkout P95 latency jumps; error rate rises |
| T+2m | Dynatrace Davis opens **Problem P-240906** — root cause: database service behind `eip-checkout` |
| T+2m | Alerting profile (prod + app:eip + severity Error/Critical) allows notify |
| T+2m | Problem notification → ServiceNow Incident Integration |
| T+3m | Import set `x_dynat_ruxit_problems` → Transform Map → **Incident INC0012345** |
| T+3m | Affected CI = `eip-checkout` app service + host `eip-app-01` (from CMDB sync) |
| T+3m | Assignment group = **EIP-Support**; Priority from severity mapping |
| T+5m | On-call opens Incident → clicks **Problem URL** → sees Davis RCA + PurePath |
| T+20m | Team rolls back deploy / fixes slow query |
| T+25m | Metrics recover; Dynatrace **closes** Problem |
| T+26m | Integration marks Incident **Resolved** (or on-call resolves with notes) |

### What the Incident should contain

| Field | Example value |
| --- | --- |
| Short description | `[Dynatrace] Checkout latency high — eip-checkout` |
| Description / work notes | Problem title, impact, Davis root cause summary |
| Dynatrace Problem URL | `https://abc.live.dynatrace.com/#problems/problemdetails;pid=…` |
| Severity / Priority | Critical → P1 or P2 (per your transform map) |
| Affected CI | `eip-checkout` / `eip-app-01` |
| Assignment group | EIP-Support |
| Caller / opened by | Integration user |

### What on-call does (manage the ticket)

| Step | Action |
| --- | --- |
| 1 | Ack Incident in ServiceNow |
| 2 | Open Problem URL — confirm Davis root cause |
| 3 | Check your **Main multi-app dashboard** with `app=EIP` (servers, errors, logs) |
| 4 | Fix or escalate (DBA / change) |
| 5 | Add work notes: cause, fix, change number |
| 6 | Confirm Problem closed → Incident Resolved |
| 7 | If recurring → open Problem Management record (optional ITIL) |

### Example field mapping (conceptual)

| Dynatrace placeholder | ServiceNow field |
| --- | --- |
| `{ProblemTitle}` | `short_description` |
| `{ProblemSeverity}` | `urgency` / `priority` (via map) |
| `{ProblemURL}` | work notes or custom URL field |
| `{ImpactedEntity}` | Affected CI lookup |
| `{State}` open/closed | Incident state / Resolved |

Exact placeholders are listed in the Dynatrace notification UI under **Available placeholders**.

### Fake “before / after” for learning

| Before integration | After integration |
| --- | --- |
| Slack flood, no ticket | One Incident with SLA |
| “Which server?” guessing | CI already on ticket |
| Fix done, nobody closes ticket | Problem close → Resolved |
| STG alerts wake prod | Alerting profile blocks STG |

---

## 5. Setup sketch (both sides)

### Minimal Incident path

| # | Where | Action |
| --- | --- | --- |
| 1 | ServiceNow Store | Install **Dynatrace Incident Integration** |
| 2 | ServiceNow | Guided Setup; integration user + transform map |
| 3 | Dynatrace | Problem notification type ServiceNow + ITSM on |
| 4 | Dynatrace | Alerting profile: prod MZ, severity filter |
| 5 | Both | Send test notification; open resulting Incident |
| 6 | Optional | Install Service Graph Connector; wait for CI sync; retest CI link |

### Optional CMDB path

| # | Action |
| --- | --- |
| 1 | Install Service Graph Connector for Observability – Dynatrace |
| 2 | Connection: Dynatrace URL + API token (Read entities) |
| 3 | Schedule job pulls hosts/services/apps |
| 4 | Identification rules merge by hostname |
| 5 | New Incidents auto-associate CIs when names match |

---

## 6. Troubleshooting (manage when broken)

| Symptom | Likely cause | What to check |
| --- | --- | --- |
| Test notify 403 | Auth / IP allow list | Integration user password; Dynatrace egress IPs to ServiceNow |
| No Incident created | Transform map / ITSM flag off | Import set rows; “Send incidents into ITSM” |
| Duplicate Incidents | Multiple notifications or reopen logic | One notification per env; update-on-change |
| No CI on ticket | CMDB not synced / name mismatch | Host/service names vs CI identity rules |
| STG tickets in prod queue | Alerting profile too wide | Filter `env:prod` / MZ |
| Incident stays open | Close not mapped | Transform on Problem State=CLOSED |

---

## Investigation

Based on Dynatrace official ServiceNow integration doc (Incident, Event, CMDB lanes) plus SRE operating practice (alerting profiles, CI link, closed-loop). Example uses EIP-style app to match your multi-app dashboard filter story.

---

## Result

**Manage** = notification + alerting profile + ServiceNow transform/assignment + CMDB match + weekly hygiene. **Example** = EIP checkout Problem → INC0012345 on correct CI → RCA via Problem URL → fix → both close.

---

## Data flow map

```
Checkout slow (EIP)
  → Dynatrace Davis Problem P-…
  → Alerting profile (prod + eip) OK?
        │ yes
        ▼
  Problem notification (ServiceNow)
        │
        ▼
  Import set → Transform → Incident INC…
        │
        ├─ Affected CI (CMDB)
        ├─ Assignment group EIP-Support
        └─ Problem URL (Davis RCA)
        │
        ▼
  Human fixes → Problem CLOSED → Incident Resolved
```

---

## Related files

| File | Purpose |
| --- | --- |
| `5-dynatrace-servicenow-manage-example.md` | This guide |
| Prior CWall note | `../4-dynatrace-servicenow-cwall/` |
| Multi-app dashboard | `../3-dynatrace-main-multiapp-need/` |
| Official doc | Dynatrace → ServiceNow notifications |

## Commands

UI-first. Optional IP check one-liner in [`5.sh`](./5.sh) — review before run.
