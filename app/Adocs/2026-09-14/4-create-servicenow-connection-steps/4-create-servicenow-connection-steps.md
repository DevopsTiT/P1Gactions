# Create ServiceNow Connection Steps

```
Need a Dynatrace ServiceNow Connection?
  │
  ├─ 1 Get SNOW integration user + rights (admin)
  ├─ 2 Grant Workflows app-settings:objects:read
  ├─ 3 Settings → Connections → ServiceNow → Create
  ├─ 4 Fill name, URL, Basic or OAuth
  ├─ 5 Share Connection (Can view / use)
  └─ 6 Use it in workflow SNOW tasks / Upload map
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What a Connection is | Dynatrace stores ServiceNow URL + credentials safely |
| Where | Settings → Connections → Connectors → **ServiceNow** |
| What you need ready | Instance URL + user/password **or** OAuth client id/secret |
| Why | Workflow SNOW actions use it — no password in YAML |

## Summary

Create one ServiceNow Connection in Dynatrace with your instance URL and login (or OAuth). Share it so workflows can use it. Then map that Connection on Create Incident / Comment / Search / Resolve tasks (or during YAML template upload).

Official docs: [ServiceNow Connector](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/default-workflow-actions/actions/service-now)

---

## Before you start (checklist)

| Ready? | Item |
| --- | --- |
| [ ] | ServiceNow instance URL (e.g. `https://acme.service-now.com`) |
| [ ] | Integration user + password **or** OAuth client id + secret |
| [ ] | That user can create/update/search **incident** |
| [ ] | User can read categories, subcategories, assignment groups, close codes |
| [ ] | You can open Dynatrace **Settings** and **Workflows** |
| [ ] | ServiceNow app for Workflows installed from Hub (if missing) |

### ServiceNow user rights (ask SNOW admin)

| Need | Table / area |
| --- | --- |
| Search, create, update incidents | `incident` |
| Read categories / subcategories | `sys_choice` |
| Read assignment groups | `sys_user_group` |
| Read resolution / close codes | `sys_choice` (`close_code`) |

---

## Step-by-step

### Step 1 — Confirm the ServiceNow app is available

1. Open Dynatrace  
2. Go to **Hub** (or Apps)  
3. Search **ServiceNow**  
4. If **ServiceNow for Workflows** / connector is not installed → **Install**  
5. Wait until it shows as installed  

If you already see ServiceNow actions in Workflows, you can skip install.

---

### Step 2 — Grant Workflows permission to read Connections

1. Open **Workflows**  
2. Open **Settings** (gear)  
3. Open **Authorization settings**  
4. Besides general Workflows permissions, enable:

| Permission | Why |
| --- | --- |
| `app-settings:objects:read` | Required so ServiceNow actions can use Connections |

5. Save / consent  

Without this, SNOW tasks often fail with “Insufficient permissions.”

---

### Step 3 — Open Connections

1. In Dynatrace go to **Settings**  
2. Open **Connections** (sometimes under Preferences / Integrations — look for **Connections**)  
3. Open **Connectors**  
4. Select **ServiceNow**  

Path (typical): **Settings → Connections → Connectors → ServiceNow**

---

### Step 4 — Create the Connection

1. Select **Connection** / **Add connection** / **Create** (button label may vary)  
2. Fill the form:

| Field | What to enter | Example |
| --- | --- | --- |
| Connection name | Clear name you will recognize later | `SNOW-Prod` or `AGO-ServiceNow` |
| ServiceNow Instance URL | Base URL only | `https://acme.service-now.com` |
| Type | **Basic Authentication** or **OAuth client credentials** | Basic for most labs |

#### If Type = Basic Authentication

| Field | Enter |
| --- | --- |
| Username | Integration user (e.g. `dynatrace.workflow`) |
| Password | That user’s password |

#### If Type = OAuth Client Credentials

| Field | Enter |
| --- | --- |
| Client ID | From ServiceNow OAuth app |
| Client secret | From ServiceNow OAuth app |

Ask your SNOW admin to create the OAuth application if you use OAuth.

3. Select **Create** / **Save**

---

### Step 5 — Share the Connection

1. Open the Connection you just created  
2. Find **Share** / access / permissions  
3. Grant workflow editors/runners at least **Can view** (or the option that allows workflows to **use** the Connection)  
4. Save  

If only you can see it, other people (or some runners) may fail when the workflow runs.

---

### Step 6 — (Optional) Quick test from a workflow

1. Open **Workflows** → create a tiny test workflow (or open your imported create workflow)  
2. Add action **ServiceNow → Create Incident** (or open an existing SNOW task)  
3. In **Connection**, pick `SNOW-Prod` (your name)  
4. Fill required fields (category, subcategory, impact, urgency, assignment group) with test values  
5. Run once if the UI allows, **or** rely on a non-prod Problem test later  

If the Connection dropdown is empty → fix Step 2 permissions or Step 5 sharing.

---

### Step 7 — Use it with your Connection YAML pack

Folder: `../3-snow-pd-workflow-with-connection/`

1. Upload `ago-problem-to-snow-pagerduty-connection.workflow-template.yaml`  
2. When the template asks for Connection → select the one you created  
3. Upload the close YAML the same way  
4. Open each SNOW task and confirm **Connection** is set  
5. Set workflows **Active**  

---

## What success looks like

| Check | Pass |
| --- | --- |
| Connection listed under ServiceNow | Yes |
| Name is clear | e.g. `AGO-ServiceNow` |
| Workflow SNOW task shows that Connection | Selected, not blank |
| Create INC test | New INC appears in ServiceNow |
| No password in YAML | Only Connection reference |

---

## Common problems

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Cannot open Connections | Missing Dynatrace settings rights | Ask DT admin |
| Connection dropdown empty | No `app-settings:objects:read` or not shared | Step 2 + Step 5 |
| 401 / auth failed | Bad user/password or OAuth | Reset creds; test login to SNOW |
| 403 / forbidden | User lacks incident rights or IP block | SNOW roles; allow list / EdgeConnect |
| Create fails on category | Choice value not in your instance | Pick valid category/subcategory in UI |
| “Failed to load” groups | User cannot read `sys_user_group` | Grant group read |

---

## Data flow map

```
SNOW admin gives URL + user/pass (or OAuth)
        │
        ▼
Dynatrace Settings → Connections → ServiceNow → Create
        │
        ▼
Share Connection + Workflows app-settings:objects:read
        │
        ▼
Workflow SNOW tasks select connectionId
        │
        ▼
Create / Comment / Search / Resolve INC (no password in YAML)
```

## Related files

| Path | Why |
| --- | --- |
| `../3-snow-pd-workflow-with-connection/` | YAML/JSON that use this Connection |
| `../../2026-09-13/5-setup-snow-pd-workflow-steps-perms/` | Full setup + IAM |
| `../../2026-09-13/22-better-than-hardcoded-placeholders/` | Why Connection is better |
| `4.sh` | Reminders |

## Commands

See `4.sh` in this folder.
