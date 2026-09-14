# Set Workflow Ui Step By Step

```
Goal: Problem → ServiceNow (classic silvastg) + PagerDuty (workflow)
  │
  ├─ A Confirm classic SNOW notification (already in Settings)
  ├─ B Allowlist hosts (External requests)
  ├─ C Upload or build OPEN workflow (PD only)
  ├─ D Upload or build CLOSE workflow (PD only)
  ├─ E Replace PD routing key → Save → Activate
  └─ F Test with a sample Problem
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| ServiceNow | Keep UI: Settings → Problem notifications → `silvastg` |
| Workflow | Automations → Workflows — PagerDuty only (open + close) |
| Secret to edit | `__PD_ROUTING_KEY__` → your real PagerDuty routing key |
| Do not | Add ServiceNow Connection tasks if classic notification owns SNOW |

## Summary

ServiceNow stays on the classic `silvastg` Problem notification. In Workflows you only set up open and close automations for PagerDuty. Below is click-by-click in the Dynatrace UI.

---

## Investigation

You chose classic Problem notification `silvastg` (ITOM events ON). Workflows should not use Connection `ServiceNowTest` for the same problems.

## Result

Follow Parts A–F in order. Prefer upload YAML from pack `8-snow-classic-notification-yaml-json`, or build the same flow by hand in the UI.

---

## Part A — Confirm ServiceNow (classic) in UI

1. Open Dynatrace.
2. Go to **Settings** → **Integration** → **Problem notifications**.
3. Open **`silvastg`** (or create it if missing).
4. Check:

| Field | Expected |
| --- | --- |
| Notification type | ServiceNow |
| Instance identifier | `silvastg` |
| Username | `Tech_DynatraceINC_WS` (exact match your UI) |
| Password | Set (use Change if needed) |
| Send incidents (ITSM) | OFF (unless you want INC tickets) |
| Send events (ITOM) | ON |
| Alerting profile | Default (or the profile you want) |

5. Click **Save** if you changed anything.

This part is **not** under Workflows. Dynatrace pushes Problems to ServiceNow from here.

---

## Part B — Allowlist (so outbound works)

1. **Settings** → **External requests** (Allow outbound / Manage External Requests).
2. Add (if missing):

| Host | Why |
| --- | --- |
| `silvastg.service-now.com` | Classic SNOW notification |
| `events.pagerduty.com` | Workflow PagerDuty tasks |

3. **Save**.

If you cannot edit this page, ask a Dynatrace admin.

---

## Part C — OPEN workflow (Problem → PagerDuty)

### Option 1 — Upload YAML (fastest)

1. Go to **Workflows** (Automations / Workflows in the left menu).
2. Find **Upload** / **Import** / **Create from template** (wording varies by tenant).
3. Upload:

`ago-problem-to-pagerduty-only.workflow-template.yaml`

Path on disk:

`Daily Files/2026-09-14/8-snow-classic-notification-yaml-json/ago-problem-to-pagerduty-only.workflow-template.yaml`

4. Open the new draft workflow.
5. Confirm title looks like: **AGO - Problem to PagerDuty (SNOW via classic notification)**.
6. Click task **prepare-payload** — leave as-is unless you need app/runbook maps.
7. Click task **create-pagerduty-incident**.
8. In the JavaScript, find:

```text
const routingKey = "__PD_ROUTING_KEY__";
```

9. Replace `__PD_ROUTING_KEY__` with your real PagerDuty Events API v2 **routing key**.
10. **Save**.

### Option 2 — Build in UI by hand

1. **Workflows** → **Create workflow**.
2. **Title**: e.g. `AGO - Problem to PagerDuty`.
3. **Trigger**:
   - Type: **Davis problem** / Problem event.
   - Active problems (CREATED / UPDATED / REOPENED) — same idea as open filter.
   - Categories: error, resource, slowdown, availability (as needed).
4. **Add task** → **Run JavaScript** named `prepare-payload`.
   - Paste the prepare script from the YAML (maps problem id, title, dedup key).
5. **Add task** → **Run JavaScript** named `create-pagerduty-incident`.
   - Predecessor: `prepare-payload` must be OK.
   - Paste the PagerDuty trigger script.
   - Set real routing key (not the placeholder).
6. Layout: prepare on top, PagerDuty below (y positions ≥ 1 if upload later).
7. **Save**.

Do **not** add “Create ServiceNow Incident” if classic `silvastg` owns ServiceNow.

---

## Part D — CLOSE workflow (Problem closed → resolve PagerDuty)

### Option 1 — Upload YAML

1. **Workflows** → Upload/Import.
2. File:

`ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml`

3. Open draft.
4. Task **resolve-pagerduty-incident**: replace `__PD_ROUTING_KEY__` with the **same** routing key as the open workflow.
5. **Save**.

### Option 2 — Build in UI

1. **Create workflow**.
2. Trigger: Davis problem **CLOSED / RESOLVED**.
3. Task `prepare-close-ids` (JS): build `dedupKey = "dt-problem-" + problemId`.
4. Task `resolve-pagerduty-incident` (JS): PagerDuty `event_action: "resolve"` with that dedup key.
5. Same routing key as open workflow.
6. **Save**.

---

## Part E — Activate and permissions

For **each** workflow (open and close):

1. Open the workflow.
2. Review trigger is **Active** / enabled.
3. Click **Activate** (or Publish) so it leaves Draft.
4. If activation asks for permissions / actor:
   - Allow the workflow identity to run.
   - Your user may need Workflows rights (e.g. settings objects read) — ask admin if blocked.

Optional: share the workflow with teammates (like Davesh) via workflow permissions / share.

---

## Part F — Test (happy path)

1. Create or wait for a **test Problem** that matches your trigger filter (or use a low-risk app/tag filter first).
2. Check **Workflows** → **Executions** (or Run history):
   - Open workflow ran OK.
   - PagerDuty task OK.
3. Check **PagerDuty**: new alert with dedup key like `dt-problem-<ProblemID>`.
4. Check **ServiceNow** (silvastg): ITOM **event** arrived from classic notification (not from the workflow).
5. Close / resolve the Dynatrace Problem.
6. Confirm close workflow ran and PagerDuty resolved; SNOW event updated via classic notification.

| Check | Where |
| --- | --- |
| Workflow run OK | Workflows → Executions |
| PD alert | PagerDuty console |
| SNOW event | ServiceNow silvastg ITOM / Event Management |
| Allowlist error | Fix Part B |

---

## If you still want ServiceNow **inside** the workflow (Connection)

Only if you abandon classic notification for ITSM (or turn ITSM on and stop duplicating):

1. **Settings** → **Connections** → ServiceNow → create/select Connection.
2. Workflow → add **Create ServiceNow Incident** task → pick Connection.
3. That is the old pack (`3-snow-pd-workflow-with-connection`), **not** this classic path.

Do not run classic ITSM + Workflow Create Incident for the same problems.

---

## Checklist

- [ ] Classic `silvastg` notification saved (Part A)
- [ ] Allowlist hosts saved (Part B)
- [ ] Open workflow uploaded/built; PD key set (Part C)
- [ ] Close workflow uploaded/built; same PD key (Part D)
- [ ] Both activated (Part E)
- [ ] Test open + close (Part F)

---

## Data flow map

```
You (UI)
  → Settings → Problem notifications silvastg → ServiceNow ITOM
  → Settings → External requests → allow hosts
  → Workflows → upload/edit open + close → set PD key → Activate
  → Test Problem → Executions + PD + SNOW
```

## Related files

| Path | Why |
| --- | --- |
| `../8-snow-classic-notification-yaml-json/` | YAML/JSON to upload |
| `../7-solve-outside-link-allowlist-perms/` | Allowlist + permissions |
| `9.sh` | Path reminders |

## Commands

See `9.sh` in this folder (paths only — run yourself).
