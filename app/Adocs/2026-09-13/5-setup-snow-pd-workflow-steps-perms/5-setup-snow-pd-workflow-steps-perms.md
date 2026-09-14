# Setup SNOW PD Workflow Step By Step

```
Ready to run Problem → ServiceNow + PagerDuty?
  │
  ├─ 1 Permissions (Dynatrace user + Workflows auth)
  ├─ 2 Connections + external hosts
  ├─ 3 ServiceNow + PagerDuty side accounts
  ├─ 4 Upload YAML or JSON
  ├─ 5 Replace placeholders / map connections
  └─ 6 Test open + close
```

| Key point | Detail |
| --- | --- |
| What you upload | YAML **template** or JSON **workflow** from seq 4 |
| Who needs access | Dynatrace workflow editor + SNOW integration user + PD routing key |
| Docs | [Workflow permissions](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/security) · [ServiceNow connector](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/default-workflow-actions/actions/service-now) |

## Summary

Grant Dynatrace Workflow permissions, create ServiceNow (and optional PD) connections, allow outbound hosts, upload the workflow file, fill placeholders or switch to the ServiceNow connector action, then test with a Problem open and close.

---

## Part A — Permissions you need

### A1. Dynatrace IAM (your user / group) — Account Management

Ask your Dynatrace **account admin** to grant these on the environment.

| Permission | Why |
| --- | --- |
| `app-engine:apps:run` | Open Workflows / apps |
| `automation:workflows:read` | View workflows |
| `automation:workflows:write` | Create / edit / upload workflows + triggers |
| `automation:workflows:run` | Run workflows (manual test + event runs as allowed) |
| `app-engine:functions:run` | Run JS / function actions |
| `app-settings:objects:read` | Use shared connector connections (ServiceNow) |
| `app-settings:objects:write` | Create/edit ServiceNow (or other) connections |
| `storage:buckets:read` + system events read (optional) | View workflow execution history |

| If you administer everyone’s workflows | Also need |
| --- | --- |
| `automation:workflows:admin` | Admin mode in Workflows Settings |
| `app-settings:objects:admin` | Manage all environment connections |
| `iam:bindings:*` (or equivalent IAM admin) | If Authorization Settings UI is missing |

Optional history (from Dynatrace docs):

| Permission | Condition / note |
| --- | --- |
| `storage:system:read` | Often with `storage:event.provider = "AUTOMATION_ENGINE"` |
| `storage:buckets:read` | Often with table `dt.system.events` |

### A2. Workflows app — Authorization settings (consent on your behalf)

1. Open **Workflows**
2. **Settings** (gear) → **Authorization settings**
3. Enable at least:

| Scope | Required for |
| --- | --- |
| General Workflows primary permissions | Run/edit |
| `app-settings:objects:read` | **ServiceNow connector** actions |

Without `app-settings:objects:read` you often see “Insufficient permissions” on ServiceNow tasks.

### A3. ServiceNow integration user (on ServiceNow)

Create a dedicated user (e.g. `dynatrace.workflow`) with rights to:

| Capability | Typical need |
| --- | --- |
| Create / update / search **incident** | Table `incident` |
| Read categories / subcategories | `sys_choice` |
| Read assignment groups | `sys_user_group` |
| Read resolution / close codes | `sys_choice` (`close_code`) |
| Read business service / CI if used | CMDB tables your fields reference |

Roles vary by instance; many teams use something like incident write + itil-style access. Confirm with your SNOW admin. If dropdowns “Failed to load”, the user lacks dictionary/choice/group read.

### A4. PagerDuty

| Item | Need |
| --- | --- |
| Service | Target on-call service |
| Integration | **Events API v2** → **routing_key** (32 characters) |
| Dynatrace | No special PD IAM — only outbound HTTP to `events.pagerduty.com` |

### A5. Network / External requests (Dynatrace)

| Host | Why |
| --- | --- |
| `*.service-now.com` (your instance) | Create/update INC |
| `events.pagerduty.com` | Trigger/resolve PD |

Path: **Settings → Preferences / General → External requests** (label can vary) — allow those hosts. If SNOW returns **403 IP not authorized**, use **EdgeConnect** or ask SNOW to allow Dynatrace egress IPs.

---

## Part B — Step by step setup

### Step 1 — Confirm you can open Workflows

1. Dynatrace → **Workflows**
2. If the app is missing or read-only → fix **A1** permissions with admin

### Step 2 — Consent Workflows authorization

1. Workflows → **Settings** → **Authorization settings**
2. Enable required primary/secondary permissions including **`app-settings:objects:read`**
3. Save / consent

### Step 3 — Create ServiceNow connection (recommended)

1. **Settings → Connections → Connectors → ServiceNow**  
   (or create connection from a ServiceNow action card)
2. Fill:
   - Connection name
   - Instance URL `https://<id>.service-now.com`
   - Basic auth or OAuth (user from **A3**)
3. **Share access** so workflow runners can **Can view** the connection
4. Test if UI offers a test

> Our YAML/JSON JS tasks use placeholders `__SNOW_*__`. Prefer replacing the SNOW JS task with connector **Create Incident** after import so the password is not in the script.

### Step 4 — Get PagerDuty routing key

1. PagerDuty → Service → **Integrations** → Events API v2  
2. Copy **Integration Key** → will replace `__PD_ROUTING_KEY__`

### Step 5 — Allow external hosts

1. Dynatrace settings for **External requests**
2. Allow ServiceNow instance + `events.pagerduty.com`

### Step 6 — Prepare the file

Folder: `Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/`

| Goal | File |
| --- | --- |
| Create on Problem open | `ago-problem-to-snow-pagerduty.workflow-template.yaml` **or** `problem-to-snow-pagerduty.workflow.json` |
| Resolve on Problem close | `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` **or** `problem-closed-resolve-snow-pd.workflow.json` |

Edit placeholders:

| Placeholder | Set to |
| --- | --- |
| `__SNOW_INSTANCE_URL__` | `https://xxx.service-now.com` |
| `__SNOW_USER__` / `__SNOW_PASSWORD__` | Integration user (if keeping JS HTTP) |
| `__SNOW_CALLER_SYS_ID__` | Caller user sys_id |
| `__SNOW_GROUP_SYS_ID_*__` | Assignment group sys_ids |
| `__SNOW_BIZ_SYS_ID_*__` | Business service sys_ids |
| `__PD_ROUTING_KEY__` | PD Events API v2 key |

Also edit `assignMap` in `prepare-payload` for your `app` tags (EIP, CCI, …).

### Step 7 — Upload

1. Workflows → **Upload**
2. Choose:
   - **YAML** → treated as **template** → Next → pick Required apps → pick/create **Connections** → **Import**
   - **JSON** → treated as **workflow** → Replace / Keep both if asked
3. Open the imported workflow in the editor

### Step 8 — Wire trigger and tasks in UI

1. Confirm trigger = **Problem** / Active (create workflow) or Closed (resolve workflow)
2. Optional: filter `env:prod`, severity ≥ Error
3. For each JS task: confirm script saved
4. If using connector: add **ServiceNow → Create Incident** / **Comment** / **Resolve** and map fields from `prepare-payload` result
5. Ensure `create-servicenow-incident` and `create-pagerduty-incident` both depend only on `prepare-payload` (**parallel**)
6. `cross-link-snow-pd` depends on **both** create tasks
7. **Save** and set workflow **Active**

### Step 9 — Test create

1. Manual run (if UI allows with sample event) **or** open a test Problem in non-prod
2. Check Workflow **Executions** — all tasks OK
3. ServiceNow: INC exists with DT link, app, L1–L3, runbook, P3/P4
4. PagerDuty: incident/alert with same story
5. SNOW work notes contain PD `dedup_key`

### Step 10 — Test close

1. Close / resolve the Dynatrace Problem
2. Close workflow runs
3. SNOW INC resolved; PD resolve with same `dedup_key`

### Step 11 — Go live

1. Restrict trigger to prod tags / severity
2. Remove test tags from scripts if any
3. Prefer Connections over passwords in scripts
4. Document assignment map owners

---

## Part C — Permission checklist (print / ticket)

### Dynatrace person running setup

- [ ] `app-engine:apps:run`
- [ ] `automation:workflows:read`
- [ ] `automation:workflows:write`
- [ ] `automation:workflows:run`
- [ ] `app-engine:functions:run`
- [ ] `app-settings:objects:read`
- [ ] `app-settings:objects:write` (to create SNOW connection)
- [ ] Workflows Authorization settings consented (`app-settings:objects:read` on)

### ServiceNow admin

- [ ] Integration user can create/update/search incidents
- [ ] Can read groups + category choices
- [ ] IP allow list / EdgeConnect if needed

### PagerDuty admin

- [ ] Events API v2 integration on correct service
- [ ] Routing key shared securely to Dynatrace owner

### Platform

- [ ] External requests allow SNOW + `events.pagerduty.com`

---

## Troubleshooting

| Symptom | Likely permission / config gap |
| --- | --- |
| Cannot open Workflows | Missing `app-engine:apps:run` / `automation:workflows:read` |
| Cannot upload / save | Missing `automation:workflows:write` |
| Insufficient permissions on SNOW action | Workflows Authorization → `app-settings:objects:read` |
| Connection create denied | Missing `app-settings:objects:write` |
| SNOW 401 | Bad user/password or roles |
| SNOW 403 IP | External IP allow / EdgeConnect |
| PD 400 | Bad routing_key or JSON body |
| Dropdowns failed to load | SNOW user cannot read `sys_choice` / groups |

---

## Investigation

Based on Dynatrace docs: Manage workflow permissions, ServiceNow connector for Workflows, Access control for Connectors, plus upload JSON/YAML behavior from Workflows upload/download docs.

## Result

Follow Parts A–B in order. Minimum Dynatrace set is workflows read/write/run + app-engine run/functions + app-settings read (and write to create connections). SNOW and PD need their own integration credentials.

## Data flow

```
Admin grants IAM
  → You consent Workflows Authorization
  → Create SNOW connection + PD key + external hosts
  → Upload YAML/JSON
  → Fill maps / connections
  → Test Problem open/close
```

## Related files

| Path | Purpose |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | YAML + JSON to upload |
| `../1-dynatrace-workflow-snow-pagerduty/` | Design / field mapping |
| `5.sh` | UI reminders |

## Commands

See `5.sh`.
