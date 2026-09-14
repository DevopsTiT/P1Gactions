# How To Get Placeholder Values

```
Need real values for each __…__ token?
  │
  ├─ URL / user / password → ServiceNow admin + browser
  ├─ Caller / group / biz sys_id → open each SNOW record, copy sys_id
  ├─ PD routing key → PagerDuty service → Events API v2 integration
  └─ Save in a private note — not in git
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Who helps | SNOW admin (user + rights + sys_ids) and PD admin (routing key) |
| Instance URL | From the browser address bar — host only |
| sys_id | 32-char id on the record URL or form |
| PD key | Events API v2 **Integration Key** on the target service |
| Password / key | Treat as secrets |

## Summary

Each placeholder comes from either ServiceNow or PagerDuty. Below is how to find every one, in order. You need permission to view users, groups, and business services in ServiceNow, and to manage integrations in PagerDuty.

---

## 1. `__SNOW_INSTANCE_URL__`

**What it is:** Base web address of your ServiceNow instance.

### Steps

| Step | Action |
| --- | --- |
| 1 | Log in to ServiceNow in a browser |
| 2 | Look at the address bar |
| 3 | Copy only the scheme + host |

| You see in the bar | What to save |
| --- | --- |
| `https://acme.service-now.com/now/nav/ui/classic/...` | `https://acme.service-now.com` |
| `https://acme.service-now.com/$desk.do` | `https://acme.service-now.com` |

| Do | Do not |
| --- | --- |
| Use `https://` | Use `http://` |
| Stop at `.service-now.com` (or your custom host) | Include `/nav_to.do`, `/incident.do`, query strings |
| Optional: no trailing `/` | Leave path after the host |

Ask your SNOW admin if you use a custom domain (not `*.service-now.com`).

---

## 2. `__SNOW_USER__` and `__SNOW_PASSWORD__`

**What they are:** Login for a dedicated integration account the workflow uses to create/update Incidents.

### Preferred: ask SNOW admin to create one

| Ask admin for | Why |
| --- | --- |
| Username | Becomes `__SNOW_USER__` |
| Password (or reset once) | Becomes `__SNOW_PASSWORD__` |
| Rights to create/update/search **Incident** | Workflow API calls |
| Read assignment groups + business services | Field validation / lookups |

Suggested name pattern: `dynatrace.workflow` (example only).

### If you already have a user

| Step | Action |
| --- | --- |
| 1 | Confirm you can log in to SNOW with that user |
| 2 | Confirm that user can open **Incident → Create New** and save |
| 3 | Put the same username/password in your private note |

| Better long-term | Note |
| --- | --- |
| Dynatrace **Connection** | Store URL/user/password in Dynatrace instead of the YAML file |

---

## 3. `__PD_ROUTING_KEY__`

**What it is:** PagerDuty **Events API v2** integration key (often ~32 characters). Used to trigger and resolve alerts.

### Steps

| Step | Action |
| --- | --- |
| 1 | Log in to [PagerDuty](https://www.pagerduty.com) |
| 2 | Open **Services** → pick the service that should receive Dynatrace pages (prefer a demo service first) |
| 3 | Open **Integrations** on that service |
| 4 | Add or open an integration of type **Events API V2** (wording may be “Events API v2”) |
| 5 | Copy the **Integration Key** (sometimes labeled routing key) |

That string is `__PD_ROUTING_KEY__`.

| Check | Pass |
| --- | --- |
| Key length | Long alphanumeric string (often 32 chars) |
| Same key | Use the **same** key in create and close workflows |
| Service | Points at the on-call schedule you intend to page |

If you cannot add integrations, ask a PagerDuty admin.

---

## 4. How to get any ServiceNow `sys_id` (shared method)

Almost all `*_SYS_ID_*` values use the same trick.

### Method A — From the record URL (easiest)

| Step | Action |
| --- | --- |
| 1 | Open the user / group / business service form in SNOW |
| 2 | Look at the browser URL |
| 3 | Find `sys_id=` followed by 32 characters |
| 4 | Copy only those 32 characters |

Example URL shape:

```text
https://acme.service-now.com/nav_to.do?uri=sys_user.do?sys_id=a1b2c3d4e5f6789012345678abcdef01
```

Copy: `a1b2c3d4e5f6789012345678abcdef01`

### Method B — Show sys_id on the form

| Step | Action |
| --- | --- |
| 1 | Open the record |
| 2 | If you have admin rights: configure form / personalize to show **Sys ID** |
| 3 | Copy the Sys ID field |

### Method C — List view

| Step | Action |
| --- | --- |
| 1 | Open the list (Users, Groups, or Business Services) |
| 2 | Add column **Sys ID** (gear / Personalize List) if allowed |
| 3 | Copy from the row |

### Method D — Ask admin

If menus are locked down, send admin a list:

- Caller user name  
- EIP / CCI / Default assignment group names  
- EIP / CCI / Default business service names  

Ask them to return each **sys_id**.

---

## 5. `__SNOW_CALLER_SYS_ID__`

**What it is:** sys_id of the user who appears as **Caller** on the Incident.

### Steps

| Step | Action |
| --- | --- |
| 1 | In SNOW filter navigator type `sys_user.list` or go to **User Administration → Users** |
| 2 | Search for the integration user (or a dedicated “Dynatrace Bot” user) |
| 3 | Open that user record |
| 4 | Copy `sys_id` (Method A above) |

| Tip | Detail |
| --- | --- |
| Same as API user? | Often yes — caller = the integration user |
| Different bot user? | Also fine — use that user’s sys_id |

---

## 6. `__SNOW_GROUP_SYS_ID_EIP__` / `_CCI__` / `_DEFAULT__`

**What they are:** sys_ids of **Assignment groups** that own Incidents for each app.

### Steps

| Step | Action |
| --- | --- |
| 1 | Navigator: `sys_user_group.list` or **User Administration → Groups** |
| 2 | Search group name (examples: `EIP-Support`, `CCI-Support`, `Ops-Default`) |
| 3 | Open the group |
| 4 | Copy `sys_id` |
| 5 | Repeat for EIP, CCI, and Default |

| Map key in workflow | Meaning |
| --- | --- |
| `EIP` | Used when Dynatrace tag `app:EIP` |
| `CCI` | Used when `app:CCI` |
| `default` | Used when app tag missing or unknown |

If your real group names differ, still copy **those** groups’ sys_ids into the matching placeholders (and align `assignMap` names/tags).

---

## 7. `__SNOW_BIZ_SYS_ID_EIP__` / `_CCI__` / `_DEFAULT__`

**What they are:** sys_ids of **Business Service** (or service CI) records used on the Incident `business_service` field.

### Steps

| Step | Action |
| --- | --- |
| 1 | Ask SNOW admin which table your “Business service” field uses (often something like Business Service / `cmdb_ci_service`) |
| 2 | Open that module/list in SNOW |
| 3 | Search the service name (examples: “EIP Checkout”, “CCI FA Comm Calc”) |
| 4 | Open the record → copy `sys_id` |
| 5 | Repeat for EIP, CCI, Default |

| If you cannot find it | Do this |
| --- | --- |
| No CMDB access | Ask SNOW admin for the three sys_ids |
| Field not used in your instance | Confirm with admin whether `business_service` is required; may need a different field |

---

## 8. Fill sheet (copy for your private note)

| Placeholder | How you got it | Your value |
| --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | Browser host | |
| `__SNOW_USER__` | Admin / login | |
| `__SNOW_PASSWORD__` | Admin / vault | |
| `__PD_ROUTING_KEY__` | PD Events API v2 key | |
| `__SNOW_CALLER_SYS_ID__` | User form sys_id | |
| `__SNOW_GROUP_SYS_ID_EIP__` | Group form sys_id | |
| `__SNOW_GROUP_SYS_ID_CCI__` | Group form sys_id | |
| `__SNOW_GROUP_SYS_ID_DEFAULT__` | Group form sys_id | |
| `__SNOW_BIZ_SYS_ID_EIP__` | Business service sys_id | |
| `__SNOW_BIZ_SYS_ID_CCI__` | Business service sys_id | |
| `__SNOW_BIZ_SYS_ID_DEFAULT__` | Business service sys_id | |

---

## 9. Common problems

| Problem | Likely cause | Fix |
| --- | --- | --- |
| No `sys_id` in URL | UI page without it | Use list column, Show XML, or ask admin |
| Create INC fails on group/biz | Wrong sys_id or inactive record | Re-open record; confirm Active; re-copy |
| 401 from SNOW | Bad user/password | Reset password; test login |
| 403 from SNOW | User lacks rights or IP blocked | Roles + allow list / EdgeConnect |
| PD 400/401 | Wrong routing key or wrong service | Re-copy Events API v2 key |
| Wrong team gets tickets | Wrong group sys_id for that app tag | Fix map + confirm `app:` tag |

---

## Data flow map

```
ServiceNow browser
  → instance URL
  → user + password (admin)
  → open User / Group / Business Service
  → copy sys_id from URL

PagerDuty
  → Service → Integrations → Events API v2
  → copy Integration Key

Private note (all 11)
  → Find/Replace into YAML  OR  Connection + UI for secrets
```

## Related files

| Path | Why |
| --- | --- |
| `../21-placeholder-value-examples/` | Fake format examples |
| `../20-how-to-replace-placeholders/` | How to paste into files |
| `../22-better-than-hardcoded-placeholders/` | Connection instead of password in file |
| `23.sh` | Reminders |

## Commands

See `23.sh` in this folder.
