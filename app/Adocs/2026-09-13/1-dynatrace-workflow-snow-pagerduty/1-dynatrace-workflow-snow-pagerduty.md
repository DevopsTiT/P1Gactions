# Dynatrace Problem To ServiceNow And PagerDuty Workflow

```
Dynatrace Problem OPEN
  │
  ├─► (parallel) ServiceNow Create Incident  ──► INC######
  └─► (parallel) PagerDuty Events API trigger ──► PD incident
        │
        ▼
  Cross-link (sync): write PD id into SNOW + INC into PD notes
        │
  Problem CLOSED (optional 2nd path)
        ├─► Resolve SNOW incident
        └─► PagerDuty resolve (same dedup_key)
```

| Key point | Detail |
| --- | --- |
| What this is | Dynatrace **Workflow** on Problem open |
| Parallel | ServiceNow + PagerDuty at the same time |
| Sync | Cross-link ticket IDs + close both when Problem closes |
| Ticket fields | Caller, business service, assignment, P3/P4, DT link, app, L1–L3, runbook |

## Summary

When Davis opens a **Problem**, a Workflow creates a **ServiceNow Incident** and a **PagerDuty incident in parallel**, fills the fields from your whiteboard, then **cross-links** the two tickets. A close path resolves both when the Problem closes. PagerDuty↔ServiceNow native sync (if licensed) can be an extra layer; Dynatrace still owns open/close from the Problem.

---

## 1. Architecture (matches whiteboard)

```
Problem / Alert (Dynatrace)
        │
        ▼
   Dynatrace Workflow
        │
   ┌────┴────┐
   ▼         ▼
SNOW API   PagerDuty API
Create INC   trigger event
   │         │
   └────┬────┘
        ▼
  Cross-link + work notes
        │
        ▼
  On-call (L1/L2/L3) + runbook
        │
        ▼
  (optional) 3-week KPI from SNOW
```

Docs:
- Problem trigger: https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/trigger/event-trigger  
- ServiceNow connector: https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/default-workflow-actions/actions/service-now  

---

## 2. Prerequisites (do once)

| # | Where | Action |
| --- | --- | --- |
| 1 | Dynatrace → Workflows → Settings → Authorization | Grant Workflows + `app-settings:objects:read` for ServiceNow actions |
| 2 | Settings → Connections → Connectors → **ServiceNow** | Create connection (URL + basic/OAuth user that can create/update incidents) |
| 3 | PagerDuty | Events API v2 integration on the target service → copy **routing_key** (32 chars) |
| 4 | Settings → General → **External requests** | Allow `*.service-now.com` and `events.pagerduty.com` (or EdgeConnect if IP allow-list) |
| 5 | Ownership / tags | Ensure entities have `app`, `env`, and Ownership teams for L1/L2/L3 mapping |
| 6 | ServiceNow | Know sys_ids or names: caller user, assignment groups, business services, category/subcategory |

Store secrets in Dynatrace **Connections** / credential store — do not paste PD keys into chat or git.

---

## 3. Create the Workflow (UI steps)

### 3.1 New workflow

1. Dynatrace → **Workflows** → **Create workflow**  
2. Name: `Problem → ServiceNow + PagerDuty (parallel)`  
3. Description: Create INC + PD on Problem open; sync IDs; resolve on close  

### 3.2 Trigger — Problem

| Setting | Recommended |
| --- | --- |
| Trigger type | **Problem** |
| Problem state | **Active** (open / re-open) for create flow |
| Severity | At least **Error** (or Resource+ if you want P4 noise) |
| Affected entities | Optional: only `env:prod` / specific apps |
| Advanced DQL filter | Optional: exclude synthetic / lab |

Use a **second workflow** (or second trigger path) with Problem state **Closed** for resolve — cleaner than one graph with two entry points.

### 3.3 Task graph (create flow)

```
[Trigger: Problem OPEN]
        │
        ▼
[0. Prepare payload]  ← JavaScript task (map severity→P3/P4, app, group, runbook)
        │
   ┌────┴────┐
   ▼         ▼
[1a Create   [1b HTTP
 ServiceNow   PagerDuty
 Incident]    trigger]
   │         │
   └────┬────┘
        ▼
[2. Cross-link]
   - Comment on SNOW with PD dedup_key / URL
   - (optional) HTTP note to PD with INC number
        │
        ▼
[3. Done]
```

Mark **1a** and **1b** as **parallel** (both depend only on task 0).

---

## 4. Field mapping — ServiceNow Create Incident

Use action **ServiceNow → Create Incident** (connection from step 2).

| Your requirement | ServiceNow field | Dynatrace / workflow value (examples) |
| --- | --- | --- |
| 1. Who is calling | `caller_id` | Integration user **or** Ownership “OpsBot” / Dynatrace service account sys_id |
| 2. Business service impacting | `business_service` (or `cmdb_ci_service`) | Map from entity tag `app` / CMDB CI name (e.g. EIP, CCI) |
| 3. To whom assign | `assignment_group` | Map from `app` tag → group (e.g. EIP-Support, CCI-Support) |
| 4. Level P3 / P4 | `impact` + `urgency` (→ priority) | See severity table below |
| 5. Dynatrace link + app + L1/L2/L3 | `description` / work notes | Problem URL + app + escalation text |
| 6. Article / runbook | `description` or custom field / KB | Map from `app` → runbook URL table |
| Dedup / sync | `correlation_id` | Dynatrace Problem ID (PID) |

### Severity → P3 / P4 (adjust to your ITIL matrix)

| Dynatrace Problem severity | Suggested SNOW | Priority feel |
| --- | --- | --- |
| Availability / Critical-like | impact=2, urgency=2 | **P3** (or P2 if your matrix says so) |
| Error | impact=2, urgency=3 | **P3** |
| Resource / Slowdown | impact=3, urgency=3 | **P4** |
| Info / Custom info | skip workflow | — |

Whiteboard also allows P1/P2 for true outages — extend the JS map when needed.

### Category / subcategory

Required by the connector. Example defaults (change to your SNOW choices):

| Field | Example |
| --- | --- |
| Category | `Software` or `Monitoring` |
| Subcategory | `Application` |

### Short description / description templates

**Short description:**
```text
[Dynatrace] {{ problem title }} — app={{ app }}
```

**Description (include items 5–6):**
```text
Caller: Dynatrace Workflow (auto)
Business service / app: {{ app }}
Assignment: {{ assignment_group_name }}
Priority intent: {{ p_level }} (impact={{ impact }}, urgency={{ urgency }})

Dynatrace Problem: {{ problem_url }}
Problem ID: {{ problem_id }}
Impacted entities: {{ impacted }}

Who can help:
- L1: {{ l1_team }}
- L2: {{ l2_team }}
- L3: {{ l3_team }}

Runbook / SOP: {{ runbook_url }}

PagerDuty: will be linked in work notes after parallel create.
```

---

## 5. PagerDuty parallel task (HTTP)

Action: **HTTP request**

| Setting | Value |
| --- | --- |
| Method | `POST` |
| URL | `https://events.pagerduty.com/v2/enqueue` |
| Headers | `Content-Type: application/json` |
| Body | JSON below |

```json
{
  "routing_key": "<PAGERDUTY_EVENTS_V2_ROUTING_KEY>",
  "event_action": "trigger",
  "dedup_key": "dt-problem-{{ problem_id }}",
  "client": "Dynatrace",
  "client_url": "{{ problem_url }}",
  "links": [
    { "href": "{{ problem_url }}", "text": "Open Dynatrace Problem" },
    { "href": "{{ runbook_url }}", "text": "Runbook" }
  ],
  "payload": {
    "summary": "[Dynatrace] {{ problem_title }} ({{ app }})",
    "source": "{{ app }}",
    "severity": "{{ pd_severity }}",
    "component": "{{ app }}",
    "group": "{{ assignment_group_name }}",
    "class": "dynatrace-problem",
    "custom_details": {
      "problem_id": "{{ problem_id }}",
      "problem_url": "{{ problem_url }}",
      "business_service": "{{ business_service }}",
      "assignment_group": "{{ assignment_group_name }}",
      "priority_intent": "{{ p_level }}",
      "l1": "{{ l1_team }}",
      "l2": "{{ l2_team }}",
      "l3": "{{ l3_team }}",
      "runbook": "{{ runbook_url }}",
      "caller": "Dynatrace Workflow"
    }
  }
}
```

| Dynatrace severity | `pd_severity` |
| --- | --- |
| Availability / Error (high) | `critical` or `error` |
| Resource | `warning` |
| Info | `info` |

Use the **same** `dedup_key` (`dt-problem-<PID>`) on resolve so PD closes the same incident.

---

## 6. Sync ServiceNow ↔ PagerDuty

### A. Dynatrace-owned sync (recommended in this Workflow)

| Step | Action |
| --- | --- |
| After parallel create | Read SNOW `number` / `sys_id` from Create Incident result |
| | Read PD `dedup_key` from HTTP response |
| Comment on incident | “PagerDuty dedup_key=… / open PD UI” |
| Optional HTTP | Add INC number into PD note / custom detail via Events API follow-up or PD REST |
| On Problem close | **Resolve incident** (SNOW) + PD `event_action: resolve` with same `dedup_key` |

### B. Platform sync (optional extra)

| Option | When |
| --- | --- |
| PagerDuty ServiceNow extension | PD and SNOW keep status in sync natively |
| ServiceNow Incident Integration from Dynatrace notification | Simpler SNOW-only path (not parallel PD) |

Whiteboard “Close Incident / Open / Move to User” = status sync. Dynatrace Workflow covers **open + close**; PD↔SNOW product sync covers assignee moves if enabled.

---

## 7. JavaScript prepare task (example logic)

Use a **JavaScript** task after the trigger to build one payload object. Pseudocode:

```javascript
// Inputs from Problem trigger — field names can vary; use Workflow expression picker
const severity = event["severity"] || event["event.severity"] || "ERROR";
const title = event["title"] || event["event.name"] || "Dynatrace Problem";
const problemId = event["display_id"] || event["event.id"];
const problemUrl = event["url"] || event["event.url"];
const tags = event["tags"] || [];

// app from tags like app:EIP
function tagValue(tags, key) {
  const t = (tags || []).find(x => String(x).startsWith(key + ":"));
  return t ? String(t).split(":").slice(1).join(":") : "unknown-app";
}
const app = tagValue(tags, "app");

// Assignment + runbook maps — EDIT for your org
const assignMap = {
  "EIP": { group: "EIP-Support", biz: "EIP Checkout", l1: "EIP-L1", l2: "EIP-L2", l3: "EIP-L3", runbook: "https://confluence.example/runbooks/eip" },
  "CCI": { group: "CCI-Support", biz: "CCI FA Comm Calc", l1: "CCI-L1", l2: "CCI-L2", l3: "CCI-L3", runbook: "https://confluence.example/runbooks/cci" },
  "default": { group: "Ops-Default", biz: "Unknown Business Service", l1: "Ops-L1", l2: "Ops-L2", l3: "Ops-L3", runbook: "https://confluence.example/runbooks/default" }
};
const meta = assignMap[app] || assignMap["default"];

// P3 / P4 mapping
let impact = "3", urgency = "3", p_level = "P4", pd_severity = "warning";
const sev = String(severity).toUpperCase();
if (sev.includes("AVAILABILITY") || sev.includes("CRITICAL")) {
  impact = "2"; urgency = "2"; p_level = "P3"; pd_severity = "critical";
} else if (sev.includes("ERROR")) {
  impact = "2"; urgency = "3"; p_level = "P3"; pd_severity = "error";
} else {
  impact = "3"; urgency = "3"; p_level = "P4"; pd_severity = "warning";
}

return {
  caller: "Dynatrace Workflow",
  app,
  business_service: meta.biz,
  assignment_group_name: meta.group,
  // Put real SNOW sys_ids in production maps:
  // assignment_group_sys_id: "...",
  // caller_sys_id: "...",
  // business_service_sys_id: "...",
  impact,
  urgency,
  p_level,
  l1_team: meta.l1,
  l2_team: meta.l2,
  l3_team: meta.l3,
  runbook_url: meta.runbook,
  problem_id: problemId,
  problem_url: problemUrl,
  problem_title: title,
  pd_severity,
  dedup_key: "dt-problem-" + problemId
};
```

Wire later tasks to `{{ result("prepare").app }}` style references (exact syntax: use the Workflow UI expression helper).

---

## 8. Close workflow (Problem CLOSED)

| Task | Action |
| --- | --- |
| Search incidents | `correlation_id=<problem_id>` (or short_description contains Problem ID) |
| Resolve incident | Resolution notes: “Dynatrace Problem closed”; close code per process |
| HTTP PagerDuty | `event_action: "resolve"`, same `dedup_key` |

```json
{
  "routing_key": "<PAGERDUTY_EVENTS_V2_ROUTING_KEY>",
  "event_action": "resolve",
  "dedup_key": "dt-problem-{{ problem_id }}"
}
```

---

## 9. End-to-end checklist

| Step | Pass |
| --- | --- |
| Manual run with sample Problem event | INC created + PD page |
| Description has DT link, app, L1–L3, runbook | Yes |
| Priority P3/P4 matches severity map | Yes |
| Work notes have PD dedup_key | Yes |
| Close Problem | SNOW Resolved + PD resolved |
| Prod-only filter | STG does not create prod tickets |

---

## 10. Troubleshooting

| Symptom | Check |
| --- | --- |
| SNOW 403 IP | Allow Dynatrace egress or EdgeConnect |
| Create Incident validation | Category/subcategory/assignment required fields |
| PD 400 | routing_key length; severity enum; JSON body |
| Duplicate INC | correlation_id / only trigger on open not every update |
| Wrong group | app tag missing → fix Ownership/tags |
| No runbook | Extend assignMap for that app |

---

## Investigation

Built from your note (parallel SNOW+PD, sync, fields 1–6) and whiteboard (Create Incident via API, P1–P4, DT link, L1–L3, SOP, close/open sync, KPI). Uses Dynatrace Workflows Problem trigger + ServiceNow connector + PagerDuty Events API v2.

## Result

One create workflow (parallel INC + PD + cross-link) and one close workflow (resolve both). Fill org-specific sys_ids, groups, and runbook URLs in the prepare map.

## Data flow map

```
Problem OPEN
  → prepare (app, P3/P4, L1-3, runbook)
  → parallel: SNOW Create Incident | PD trigger
  → cross-link IDs
Problem CLOSED
  → SNOW Resolve | PD resolve (same dedup_key)
```

## Related files

| File | Purpose |
| --- | --- |
| `workflow-blueprint.md` | Compact task list for builders |
| `payload-examples.json` | SNOW + PD example bodies |
| `1.sh` | UI path reminders |
| Prior SNOW manage | `2026-09-07/25-manage-servicenow-step-example/` |

## Commands

See `1.sh`.
