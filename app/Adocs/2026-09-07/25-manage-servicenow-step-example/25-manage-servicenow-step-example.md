# Manage ServiceNow With Dynatrace

```
What do you need?
  │
  ├─ Tickets from Dynatrace Problems? → Incident integration (start here)
  ├─ Events for ITOM correlation? → Event Management (optional)
  ├─ Hosts/apps as inventory? → CMDB / Service Graph
  └─ Day-2 manage → filter noise + assign right group + link CI + close sync
```

| Key point | Detail |
| --- | --- |
| What ServiceNow is | Company ticket + CMDB system (Incidents, Changes, CIs) |
| What Dynatrace does | Detects Problems and explains root cause (Davis) |
| What “manage” means | Who gets tickets, which alerts fire, CI accuracy, open/close loop |
| Example below | EIP checkout slow → Problem → INC0012345 → fix → both close |

## Summary

**ServiceNow** stores work tickets and the list of servers/apps (**CMDB**). **Dynatrace** finds outages and opens a **Problem**. You manage the link so only important prod Problems become Incidents on the right CI, assigned to the right group, with a Problem URL for RCA — then both sides close when the issue is fixed.

---

## 1. Plain English — pieces you will manage

| Piece | What it means | Why you care |
| --- | --- | --- |
| Incident | Work ticket for humans | Ownership, SLA, audit trail |
| Problem (Dynatrace) | Grouped alert + root cause | Truth of “what broke” |
| CMDB / CI | Config item (host, service, app) | Ticket hangs on the right object |
| Assignment group | Team queue in ServiceNow | Who is paged / works it |
| Alerting profile | Dynatrace filter for notifications | Stops STG / noise ticket storms |
| Problem notification | Wire Dynatrace → ServiceNow | Creates/updates the Incident |
| Transform map | Field mapping in ServiceNow | Title, priority, CI, notes land correctly |

```
Dynatrace (detect + RCA)
        │
        ▼
Alerting profile (allow only what matters)
        │
        ▼
Problem notification → ServiceNow
        │
        ├─ Incident (ITSM)     ← most teams start here
        ├─ Events (ITOM)       ← optional
        └─ CMDB sync           ← better CI linking
```

Official doc:  
https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/servicenow-integration

---

## 2. Step-by-step — set up (first time)

Do ServiceNow install **before** Dynatrace notification, or you will get auth/import errors.

### Step 1 — ServiceNow: install the app

1. Log in to ServiceNow as admin  
2. Open **ServiceNow Store**  
3. Search **Dynatrace Incident Integration** (name may vary slightly by version)  
4. **Install** / Get / Activate for your instance  
5. Run **Guided Setup** for that app  

Pass check: app appears under System Applications / plugins list.

### Step 2 — ServiceNow: integration user

1. Create a dedicated user, e.g. `dynatrace.integration`  
2. Give only the roles the Guided Setup asks for (least privilege)  
3. Set a strong password / OAuth per your org standard  
4. Note instance URL: `https://<your-id>.service-now.com`  

Pass check: user can create Incidents via the integration path (test later).

### Step 3 — ServiceNow: transform map + assignment

1. Open the Dynatrace → Incident **transform map** (from Guided Setup)  
2. Confirm fields roughly map like this:

| From Dynatrace | To ServiceNow |
| --- | --- |
| Problem title | Short description |
| Severity | Urgency / Priority |
| Problem URL | Work notes or custom URL field |
| Impacted entity | Affected CI (lookup) |
| Open / Closed state | Incident state / Resolved |

3. Set **assignment rules** so `app:eip` / CI name routes to group **EIP-Support** (or your real groups)  
4. Save  

Pass check: sample import set row transforms without errors.

### Step 4 — Dynatrace: alerting profile (noise control)

1. Dynatrace → **Settings** → **Alerting** → **Alerting profiles**  
2. Create e.g. `prod-eip-to-servicenow`  
3. Limit to:

| Filter | Example |
| --- | --- |
| Environment / MZ | Production management zone |
| Severity | Error + Critical (not Info) |
| Entity tags | `env:prod`, optionally `app:eip` for a first pilot |

Pass check: STG / low-severity Problems do **not** match this profile.

### Step 5 — Dynatrace: Problem notification

1. Dynatrace → **Settings** → **Integration** → **Problem notifications**  
2. **Add notification** → type **ServiceNow**  
3. Fill ServiceNow instance URL / credentials (integration user)  
4. Turn **ON**: Send incidents into ServiceNow ITSM  
5. Attach the alerting profile from Step 4  
6. Include placeholders: Problem title, severity, URL, impacted entities  
7. **Send test notification**  
8. **Save**  

Pass check: test creates an Incident in ServiceNow within a few minutes.

### Step 6 — Optional: CMDB / Service Graph

1. Install **Service Graph Connector for Observability – Dynatrace** (if licensed)  
2. Connect Dynatrace URL + API token (read entities)  
3. Schedule sync of hosts / services / apps  
4. Check identity rules (merge by hostname)  
5. Retest: new Incident should show **Affected CI**  

Pass check: prod Incidents usually have a CI, not blank.

### Step 7 — Closed-loop check

1. Open a **fake** or test Problem (or use Send test)  
2. Confirm Incident **New/In Progress**  
3. Close / resolve the Dynatrace Problem (or wait for auto-close on real recovery)  
4. Confirm Incident moves to **Resolved** (or your mapped state)  

Pass check: no zombie open tickets after Problem is closed.

---

## 3. Step-by-step — day-2 manage (ongoing)

### A. Dynatrace weekly

| # | Action | Healthy look |
| --- | --- | --- |
| 1 | Re-send test notification | Still succeeds |
| 2 | Review alerting profile | No STG flood into prod queue |
| 3 | Compare open Problems vs open DT Incidents | Counts roughly match |
| 4 | Confirm Problem URL still in ticket notes | On-call can open Davis |

### B. ServiceNow weekly

| # | Action | Healthy look |
| --- | --- | --- |
| 1 | Check import set errors | No failed Dynatrace rows |
| 2 | Spot-check assignment | EIP apps → EIP group (not wrong queue) |
| 3 | CI link rate | Most prod Incidents have Affected CI |
| 4 | Duplicate Incidents | One Problem → one Incident (updates, not clones) |

### C. On-call when a real Incident arrives

| # | Action |
| --- | --- |
| 1 | **Ack** the Incident in ServiceNow |
| 2 | Open the **Dynatrace Problem URL** from work notes |
| 3 | Read Davis root cause (service / host / DB) |
| 4 | Use your multi-app dashboard (filter tag `app`) for hosts, errors, logs |
| 5 | Fix or escalate; add **work notes** (cause, fix, change number) |
| 6 | Wait for Problem close → confirm Incident **Resolved** |
| 7 | If it keeps recurring → open Problem Management (ITIL) if your process uses it |

### D. Hard rules (do not break these)

| Rule | Why |
| --- | --- |
| Do not send all Problems from all envs | Ticket storm; SLA nonsense |
| Prefer one notification per env | Avoid duplicates |
| Tag entities (`env`, `app`) | Filtering + assignment + CMDB match |
| Keep Problem URL as source of truth | Ticket text alone is not enough for RCA |
| Never use real customer PII in test tickets | Same privacy bar as log masking |

---

## 4. Detailed example — EIP checkout latency

### Story

Shoppers see slow checkout on the **EIP** payment path. You want **one** ServiceNow Incident, correct CI, Davis root cause link — not five Slack threads and no ticket.

### Actors

| Who | Tool | Job |
| --- | --- | --- |
| Shopper | Web / app | Hits slow checkout |
| Dynatrace | Davis | Opens Problem + root cause |
| ServiceNow | Incident | Creates INC0012345 for EIP-Support |
| On-call SRE | Both | Works ticket using Problem URL + dashboard |
| App / DBA | Change | Fixes query or rolls back deploy |

### Minute-by-minute timeline

| Time | What happens |
| --- | --- |
| T+0 | Checkout P95 latency jumps; error rate rises |
| T+2m | Dynatrace opens **Problem P-240906**. Davis: slow DB behind service `eip-checkout` |
| T+2m | Alerting profile `prod-eip-to-servicenow` matches (prod + Error/Critical + app:eip) |
| T+2m | Problem notification fires to ServiceNow |
| T+3m | Import set receives the Problem → Transform map runs |
| T+3m | **Incident INC0012345** created |
| T+3m | Affected CI = `eip-checkout` (+ host `eip-app-01` if CMDB synced) |
| T+3m | Assignment group = **EIP-Support**; Priority from severity map |
| T+5m | On-call acks INC0012345, opens Problem URL, sees Davis + PurePath |
| T+5m | Opens Main multi-app dashboard, filter `app=EIP` — CPU OK, ERROR logs spike on checkout host |
| T+20m | Team rolls back bad deploy / adds DB index |
| T+25m | Metrics recover; Dynatrace **closes** Problem P-240906 |
| T+26m | Integration updates Incident → **Resolved** (or on-call resolves with notes) |

### What INC0012345 should look like

| Field | Example value |
| --- | --- |
| Number | INC0012345 |
| Short description | `[Dynatrace] Checkout latency high — eip-checkout` |
| Work notes | Impact summary + Davis root cause text + Problem URL |
| Priority | P1 or P2 (from Critical/Error map) |
| Affected CI | `eip-checkout` / `eip-app-01` |
| Assignment group | EIP-Support |
| Opened by | `dynatrace.integration` |
| State over time | New → In Progress → Resolved |

### What good management looked like in this example

| Managed item | What you did | Result |
| --- | --- | --- |
| Noise | Prod-only alerting profile | No STG tickets in EIP queue |
| Assignment | Transform / rule → EIP-Support | Right team got the page |
| CI | CMDB sync + name match | Ticket not “orphan” |
| RCA | Problem URL in notes | On-call used Davis, not guesswork |
| Close | Problem CLOSED → Incident Resolved | No zombie INC |

### Before vs after

| Before | After |
| --- | --- |
| Slack flood, no owner | One Incident with SLA |
| “Which server?” | CI already filled |
| Fix done, ticket forgotten | Problem close resolves Incident |
| STG wakes prod | Alerting profile blocks STG |

---

## 5. Troubleshooting

| Symptom | Likely cause | What to check |
| --- | --- | --- |
| Test notify 403 | Auth or IP block | Integration user; allow Dynatrace egress to ServiceNow |
| No Incident | ITSM flag off / transform fail | “Send incidents into ITSM”; import set errors |
| Duplicate Incidents | Multiple notifications | One notify per env; update-on-change |
| Blank Affected CI | CMDB not synced / name mismatch | Service Graph job; hostname identity rules |
| Wrong group | Assignment rule | Tag/CI → group mapping |
| Incident stays open | Close not mapped | Transform when Problem state = CLOSED |
| Ticket storm | Profile too wide | Add MZ + severity + env tag |

---

## Investigation

Refreshed from prior Daily File `2026-09-06/5-dynatrace-servicenow-manage-example` plus Dynatrace ServiceNow notification docs and SRE closed-loop practice. Example aligns with your EIP / multi-app Dynatrace dashboard work.

## Result

Manage ServiceNow with Dynatrace in seven setup steps, then weekly hygiene. The EIP checkout story shows one Problem → one Incident → fix → both close.

## Data flow map

```
Checkout slow (EIP)
  → Dynatrace Problem P-…
  → Alerting profile OK? ──no──► no ticket
        │ yes
        ▼
  Problem notification
        ▼
  ServiceNow import → transform → INC0012345
        │
        ├─ CI: eip-checkout
        ├─ Group: EIP-Support
        └─ Notes: Problem URL (Davis)
        ▼
  Human fix → Problem CLOSED → Incident Resolved
```

## Related files

| File | Purpose |
| --- | --- |
| `25.sh` | UI path reminders |
| `../23-jp-pii-prevent-ppt/` | unrelated PII PPT (same day seq) |
| Prior deep dive | `Daily Files/2026-09-06/5-dynatrace-servicenow-manage-example/` |

## Commands

See `25.sh` (UI reminders only — review before any network checks).
