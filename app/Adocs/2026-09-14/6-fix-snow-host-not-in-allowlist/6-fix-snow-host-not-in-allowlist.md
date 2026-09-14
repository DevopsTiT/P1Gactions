# Fix SNOW Host Not In Allowlist

```
Category/Subcategory error: host not in allowlist?
  │
  └─ Dynatrace blocked outbound HTTPS to silvastg.service-now.com
        → Settings → External requests / Allow outbound connections
        → Add silvastg.service-now.com (or *.service-now.com if policy allows)
        → Save → reopen workflow → reselect Connection
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Issue | Dynatrace **blocks** calls to `silvastg.service-now.com` (not on allowlist) |
| Not | Wrong Connection name or bad field mapping |
| Fix | Add that host under **External requests** / outbound allow list |
| After | Category/Subcategory dropdowns can load from ServiceNow |

## Summary

Your Connection `ServiceNowTest` is fine. Dynatrace refuses outbound traffic to hosts that are not allowlisted. Add `silvastg.service-now.com`, save, then reopen the Create Incident task so Category/Subcategory can load.

Docs hint from UI: https://dt-url.net/allow-outbound-connections

---

## What the red error means

Exact message:

> Blocked request to `silvastg.service-now.com` (host not in allowlist)

| What it is | Plain meaning |
| --- | --- |
| Allowlist | List of domains Dynatrace is allowed to call |
| Why Category fails | UI must query SNOW for category choices → blocked |
| Why Subcategory fails | Same — depends on SNOW |

Secondary (after allowlist works): **Assignment group** is still empty — pick a group or map `prepare-payload` group id.

---

## Step-by-step fix

### Step 1 — Open External Requests

1. In Dynatrace open **Settings**  
2. Find **Preferences** / **General** / **External requests**  
   (wording varies: **Allow outbound connections**, **External requests**)  
3. Or click **Manage External Requests** from the Connection banner / error link  

### Step 2 — Add your ServiceNow host

Add one of these (prefer the exact host first):

| Add | Example |
| --- | --- |
| Exact host | `silvastg.service-now.com` |
| Or with scheme if UI asks | `https://silvastg.service-now.com` |

Some tenants allow a pattern like `*.service-now.com` — use only if your security policy permits.

### Step 3 — Also allow PagerDuty (for your PD tasks)

| Host | Why |
| --- | --- |
| `events.pagerduty.com` | PD trigger/resolve from JS |

### Step 4 — Save

Save the allowlist. Wait a minute if the UI says changes take time.

### Step 5 — Refresh the workflow task

1. Close and reopen the **create-servicenow-incident** task  
2. Confirm Connection = **ServiceNowTest**  
3. Check **Category** / **Subcategory** — errors should clear and choices load  
4. Fill **Assignment group** (map from prepare or pick in UI)  
5. Save workflow  

---

## After allowlist — quick checks

| Check | Pass |
| --- | --- |
| Category loads | Dropdown shows SNOW categories |
| Subcategory loads | Shows values for that category |
| No red allowlist text | Gone |
| Assignment group set | Not empty |
| Test run | INC created in silvastg |

---

## If still blocked

| Symptom | Try |
| --- | --- |
| Still “host not in allowlist” | Confirm exact host spelling `silvastg.service-now.com`; no typo |
| Need admin | Your user may lack rights to edit External requests — ask Dynatrace admin |
| 401 after allowlist | OAuth Connection client id/secret wrong |
| Categories empty but no block | SNOW user lacks `sys_choice` read |

---

## Data flow map

```
Workflow Create Incident UI
  → needs SNOW categories
  → Dynatrace outbound to silvastg.service-now.com
  → BLOCKED if not on allowlist
  → ADD host → Save → UI can load Category/Subcategory
```

## Related files

| Path | Why |
| --- | --- |
| `../4-create-servicenow-connection-steps/` | How Connection was created |
| `../3-snow-pd-workflow-with-connection/` | Workflow pack |
| `../5-fix-upload-schema-error/` | Earlier upload schema fix |
| `6.sh` | Reminders |

## Commands

See `6.sh` in this folder.
