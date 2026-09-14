# Solve Outside Link Allowlist Perms

```
Workflow cannot visit silvastg.service-now.com?
  │
  ├─ 1 Whitelist host on Dynatrace External requests
  │     (Abhay: “whitelist on dynatrace”)
  │     If you cannot edit → ask DT admin
  │
  ├─ 2 Fix entry format (no red squiggles)
  │     Prefer: silvastg.service-now.com
  │
  ├─ 3 Permissions (Davesh: access permission)
  │     Share Connection + add reviewer to workflow draft
  │
  └─ 4 One Account login ≠ Dynatrace allowlist
        OAuth Connection uses client id/secret
        Interactive SNOW login is separate
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Main issue | Dynatrace blocks outbound to `silvastg.service-now.com` |
| Teammate fix | Whitelist on Dynatrace + check access permission |
| Your Connection | `ServiceNowTest` (OAuth) — keep it |
| If you cannot add allowlist | Ask someone with Settings admin rights |

## Summary

The Create Incident task fails because Dynatrace will not call ServiceNow until the host is on the **External requests** allowlist. Add `silvastg.service-now.com`, save, then share Connection/workflow access with helpers (e.g. Davesh). “Log in - One Account” is ServiceNow’s login page — it is not how the workflow authenticates when you use OAuth Connection.

---

## Problem (from your Teams thread)

| What you said | Meaning |
| --- | --- |
| Workflow cannot visit outside link | Outbound to SNOW blocked |
| Cannot add / One Account | Either no rights to allowlist, or SNOW SSO login confusion |
| Abhay | Whitelist on Dynatrace |
| Davesh | Check access permission; add him to the draft |

---

## Solution — do in order

### Step 1 — Whitelist on Dynatrace (required)

1. Dynatrace → **Settings** → **External requests**  
   (Allow outbound connections / Manage External Requests)  
2. **Add** destination:

| Enter | Notes |
| --- | --- |
| `silvastg.service-now.com` | Hostname only — best first try |
| Also: `events.pagerduty.com` | For PagerDuty tasks |

3. **Save**

If the field shows **red underlines / validation error**:

| Try | Avoid |
| --- | --- |
| Hostname only: `silvastg.service-now.com` | Trailing slash, path, spaces |
| Or full URL if UI requires: `https://silvastg.service-now.com` | Mixing both wrong formats |
| One host per row | Pasting YAML/JSON into External requests |

External requests is **not** where you paste the workflow file. Only hosts/URLs.

**If you cannot save / no permission to edit External requests:**  
Ask a Dynatrace admin (or Abhay/Davesh if they have rights) to add `silvastg.service-now.com` for you. That matches “I cannot add…”.

---

### Step 2 — Confirm allowlist worked

1. Open workflow **Draft - AGO - Problem to ServiceNow (Connection) and PagerDuty**  
2. Open task **create-servicenow-incident**  
3. Connection = **ServiceNowTest**  
4. Category / Subcategory should load **without** “host not in allowlist”  
5. Set **Assignment group**  
6. Save  

---

### Step 3 — Access permission (Davesh’s ask)

| Who | What to share |
| --- | --- |
| Connection `ServiceNowTest` | Share so workflow runners / helpers can use it |
| Workflow draft | Add Davesh (and others) as editor/viewer so they can open the link you sent |
| Workflows Authorization | Your user needs `app-settings:objects:read` |

In Teams: paste the workflow link again after sharing, so Davesh can open it.

---

### Step 4 — Do not confuse One Account login with the workflow

| Thing | What it is |
| --- | --- |
| Browser “Log in - One Account” on silvastg | Human SSO to open ServiceNow UI |
| Workflow Connection OAuth | Client id + secret — no browser login |

The workflow does **not** need you to complete One Account login for Create Incident. It needs:

1. Host allowlisted  
2. Valid OAuth Connection  
3. SNOW OAuth user/app rights to create incidents  

If OAuth is wrong, you get 401/403 **after** allowlist is fixed — different error.

---

## Checklist to send back in Teams

- [ ] `silvastg.service-now.com` on Dynatrace External requests (saved, no red error)  
- [ ] `events.pagerduty.com` allowlisted too  
- [ ] Connection `ServiceNowTest` shared  
- [ ] Davesh added to workflow draft  
- [ ] Category/Subcategory load; Assignment group set  
- [ ] Test create INC on silvastg  

---

## Data flow map

```
Create Incident task
  → Dynatrace outbound to silvastg.service-now.com
  → must be on External requests allowlist
  → then Connection OAuth authenticates
  → Category/group APIs work → INC can be created
```

## Related files

| Path | Why |
| --- | --- |
| `../6-fix-snow-host-not-in-allowlist/` | Same allowlist error detail |
| `../4-create-servicenow-connection-steps/` | Connection setup |
| `../3-snow-pd-workflow-with-connection/` | Workflow pack |
| `7.sh` | Reminders |

## Commands

See `7.sh` in this folder.
