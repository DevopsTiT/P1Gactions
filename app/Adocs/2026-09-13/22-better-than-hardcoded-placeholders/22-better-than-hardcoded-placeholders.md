# Better Than Hardcoded Placeholders

```
Want to avoid pasting secrets into YAML/JSON?
  │
  ├─ Best for ServiceNow
  │     → Dynatrace Connection + ServiceNow connector actions
  │
  ├─ Best for PagerDuty key
  │     → Store as secret/setting; JS reads it (or HTTP cred if available)
  │
  ├─ Fine to keep in script (not secrets)
  │     → assignMap names, runbook URLs, maybe sys_ids
  │
  └─ Worst
        → __SNOW_PASSWORD__ and __PD_ROUTING_KEY__ hardcoded in git
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Better way? | **Yes** — especially for SNOW password and PD routing key |
| Best SNOW path | Connection + **Create Incident** / Update / Comment actions (no password in script) |
| PD key | Keep out of git; use a secret/setting or secure store your team uses |
| sys_ids / maps | Can stay in prepare (not secrets) or move to a config table later |
| Template upload | Can map Connections in the Upload UI instead of baking credentials into the file |

## Summary

Hardcoding `__SNOW_PASSWORD__` and `__PD_ROUTING_KEY__` works for a quick lab, but it is a weak pattern. Prefer Dynatrace **Connections** for ServiceNow and keep the PagerDuty routing key outside the workflow file. Non-secret mapping (app → group names, runbooks) can remain in `prepare-payload`.

---

## Option ranking (what to do)

| Rank | Approach | Good for | Avoids putting in file |
| --- | --- | --- | --- |
| 1 (best) | ServiceNow **Connection** + connector tasks | URL, user, password | Yes |
| 2 | Secret / Settings object for PD `routing_key` | PD key | Yes |
| 3 | Upload template → bind Connection in UI | Import-time wiring | Yes for SNOW auth |
| 4 | Keep sys_ids + assignMap in JS | Non-secret config | N/A (OK in file) |
| 5 (lab only) | Direct replace of `__…__` in YAML/JSON | Fast demo | No — secrets in file |

---

## Option 1 — ServiceNow Connection (recommended)

### What this is

Dynatrace stores ServiceNow URL + credentials in **Settings → Connections → ServiceNow**. Workflow actions use that Connection. The password is not in your YAML/JSON script.

### How to do it (high level)

| Step | Action |
| --- | --- |
| 1 | Create Connection: instance URL + basic auth or OAuth |
| 2 | Share Connection so workflow runners can use it |
| 3 | After upload, replace JS `create-servicenow-incident` with connector **Create Incident** |
| 4 | Map fields from `prepare-payload` result (`correlation_id`, caller, group, biz, impact, urgency, descriptions) |
| 5 | Replace JS cross-link with **Add comment** / **Update Incident** using same Connection |
| 6 | Close workflow: use **Lookup** / search + **Resolve** (or Update state) via connector |

### What you still set in prepare (usually OK in file)

| Still in `assignMap` / prepare | Why OK |
| --- | --- |
| Group / biz **sys_ids** | Not passwords; config |
| L1/L2/L3 names, runbook URLs | Not secrets |
| Severity → P3/P4 rules | Logic |

You can stop replacing `__SNOW_INSTANCE_URL__`, `__SNOW_USER__`, `__SNOW_PASSWORD__` entirely if those tasks no longer use `fetch` + Basic auth.

Docs: [ServiceNow connector](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/default-workflow-actions/actions/service-now)

---

## Option 2 — Keep PD key out of the file

PagerDuty Events API often still needs an HTTP/`fetch` call with `routing_key`.

| Approach | What it means |
| --- | --- |
| A — Platform secret / credential | Store key in Dynatrace secret store / Settings; JS reads at runtime (pattern depends on your tenant apps) |
| B — Restricted workflow only | Put key only in the live workflow editor, never in git; upload a template with empty/placeholder and fill in UI after import |
| C — Lab only | `__PD_ROUTING_KEY__` in file (current pack) |

**Practical team rule:** Git has `REPLACE_IN_UI_AFTER_IMPORT` or empty string; operators paste the real key once in Dynatrace UI. Do not commit the real key.

---

## Option 3 — Template upload + map later

| Step | Action |
| --- | --- |
| 1 | Upload YAML **template** with placeholders still present **or** with dummy non-secret values |
| 2 | In Upload wizard, attach ServiceNow Connection where prompted |
| 3 | Open workflow in editor → fix PD key / swap SNOW JS to connector |
| 4 | Activate |

This way the **repo file** never holds production passwords.

---

## Option 4 — Config vs secrets split

| Put in workflow JS / Git | Put in Connection / secret / UI only |
| --- | --- |
| App → group name, L1–L3, runbook URL | SNOW password |
| Severity rules | PD routing key |
| Optional: group/biz sys_ids | SNOW username (if Connection holds it) |
| Category / subcategory | Instance URL (if Connection holds it) |

---

## What about the 11 tokens specifically?

| Token | Better than direct replace? |
| --- | --- |
| `__SNOW_INSTANCE_URL__` | Yes → Connection |
| `__SNOW_USER__` | Yes → Connection |
| `__SNOW_PASSWORD__` | Yes → Connection (**strongly**) |
| `__PD_ROUTING_KEY__` | Yes → secret / fill in UI after import (**strongly**) |
| `__SNOW_CALLER_SYS_ID__` | Optional — OK in prepare, or map in connector field picker |
| `__SNOW_GROUP_SYS_ID_*__` | Optional — OK in `assignMap` (config) |
| `__SNOW_BIZ_SYS_ID_*__` | Optional — OK in `assignMap` (config) |

---

## Suggested target design (v2)

```
prepare-payload          ← assignMap + severity (config in Git OK)
        │
        ├──► ServiceNow Create Incident   ← Connection (no password in script)
        └──► PagerDuty HTTP trigger       ← routing_key from secret/UI
                │
                ▼
         ServiceNow Comment/Update        ← same Connection

Close WF:
  ServiceNow find+resolve via Connection
  PagerDuty resolve via same secret/UI key
```

Current seq-4 pack = **lab/v1** (everything in JS placeholders). Move to Connection when you harden.

---

## Data flow map

```
Hardcoded __PASSWORD__ / __PD_KEY__ in file
        │
        ▼  better
Connection (SNOW) + Secret/UI (PD)
        │
        ▼
Workflow tasks read Connection/secret at runtime
        │
        ▼
Git only has config (maps, field logic) — not secrets
```

## Related files

| Path | Why |
| --- | --- |
| `../5-setup-snow-pd-workflow-steps-perms/` | Connection + permissions setup |
| `../20-how-to-replace-placeholders/` | Direct replace (lab path) |
| `../4-snow-pd-workflow-yaml-and-json/` | Current v1 pack |
| `22.sh` | Reminders |

## Commands

See `22.sh` in this folder.
