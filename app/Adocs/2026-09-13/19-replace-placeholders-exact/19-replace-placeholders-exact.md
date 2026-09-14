# Replace Placeholders Exact

```
What to replace before upload?
  │
  ├─ Same tokens in YAML and JSON (create + close)
  ├─ Must replace every __…__ string
  ├─ Also edit runbook URLs + assignMap labels if needed
  └─ Prefer YAML edit (easier); JSON has identical tokens
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Same in YAML and JSON? | Yes — identical `__PLACEHOLDER__` strings |
| Create file needs | SNOW URL/user/pass + caller + group/biz sys_ids + PD key + runbooks |
| Close file needs | SNOW URL/user/pass + PD key only |
| If you upload YAML only | Edit the two YAML files; ignore JSON |
| If you upload JSON only | Edit the two JSON files; ignore YAML |

## Summary

Replace every `__…__` token with your real values. Create workflows have more placeholders (maps + caller). Close workflows only need ServiceNow login/URL and the PagerDuty routing key. YAML and JSON use the **same** placeholder names.

---

## Exact list — must replace (`__…__`)

### A. Shared (create + close)

| Placeholder | Replace with | Example shape |
| --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | Your ServiceNow base URL | `https://mycompany.service-now.com` |
| `__SNOW_USER__` | Integration username | `dynatrace.workflow` |
| `__SNOW_PASSWORD__` | That user’s password | (secret — do not commit) |
| `__PD_ROUTING_KEY__` | PagerDuty Events API v2 integration key | 32-character key |

No trailing slash needed on the SNOW URL (script strips `/`).

### B. Create workflow only (`assignMap` + caller)

| Placeholder | Replace with | Where to get it |
| --- | --- | --- |
| `__SNOW_CALLER_SYS_ID__` | sys_id of caller user | ServiceNow `sys_user` |
| `__SNOW_GROUP_SYS_ID_EIP__` | Assignment group sys_id for EIP | `sys_user_group` |
| `__SNOW_GROUP_SYS_ID_CCI__` | Assignment group sys_id for CCI | `sys_user_group` |
| `__SNOW_GROUP_SYS_ID_DEFAULT__` | Default assignment group sys_id | `sys_user_group` |
| `__SNOW_BIZ_SYS_ID_EIP__` | Business service sys_id for EIP | CMDB business service |
| `__SNOW_BIZ_SYS_ID_CCI__` | Business service sys_id for CCI | CMDB business service |
| `__SNOW_BIZ_SYS_ID_DEFAULT__` | Default business service sys_id | CMDB business service |

### Full must-replace checklist (copy)

```
__SNOW_INSTANCE_URL__
__SNOW_USER__
__SNOW_PASSWORD__
__PD_ROUTING_KEY__
__SNOW_CALLER_SYS_ID__
__SNOW_GROUP_SYS_ID_EIP__
__SNOW_GROUP_SYS_ID_CCI__
__SNOW_GROUP_SYS_ID_DEFAULT__
__SNOW_BIZ_SYS_ID_EIP__
__SNOW_BIZ_SYS_ID_CCI__
__SNOW_BIZ_SYS_ID_DEFAULT__
```

Close files only contain the first **four**. Create files contain **all eleven**.

---

## Also edit (not `__…__` but still fake demo values)

In **create** `assignMap` (YAML easy; JSON same strings inside the script):

| Current demo value | Change to |
| --- | --- |
| `https://confluence.example/runbooks/eip` | Real EIP runbook URL |
| `https://confluence.example/runbooks/cci` | Real CCI runbook URL |
| `https://confluence.example/runbooks/default` | Real default runbook URL |
| `groupName`: EIP-Support / CCI-Support / Ops-Default | Real group **display names** (optional but recommended) |
| `bizName`: EIP Checkout / … | Real business service names |
| `l1` / `l2` / `l3` | Real team names |
| App keys `EIP` / `CCI` | Match your Dynatrace `app:` tag values |

If your apps are not EIP/CCI, rename the map keys to match tags (or add more rows).

---

## Which file contains which

| Placeholder | Create YAML | Create JSON | Close YAML | Close JSON |
| --- | --- | --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | yes (2 places) | yes (2 places) | yes | yes |
| `__SNOW_USER__` | yes (2) | yes (2) | yes | yes |
| `__SNOW_PASSWORD__` | yes (2) | yes (2) | yes | yes |
| `__PD_ROUTING_KEY__` | yes | yes | yes | yes |
| `__SNOW_CALLER_SYS_ID__` | yes | yes | no | no |
| `__SNOW_GROUP_SYS_ID_*__` | yes (3) | yes (3) | no | no |
| `__SNOW_BIZ_SYS_ID_*__` | yes (3) | yes (3) | no | no |
| confluence.example runbooks | yes (3) | yes (3) | no | no |

Create files:

- `ago-problem-to-snow-pagerduty.workflow-template.yaml`
- `problem-to-snow-pagerduty.workflow.json`

Close files:

- `ago-problem-closed-resolve-snow-pd.workflow-template.yaml`
- `problem-closed-resolve-snow-pd.workflow.json`

**If you upload YAML only:** edit both YAML files.  
**If you upload JSON only:** edit both JSON files.  
Do not need to edit all four unless you use both formats.

---

## Where each appears in create YAML (for find/replace)

| Task | Placeholders |
| --- | --- |
| `prepare-payload` | caller + all GROUP/BIZ sys_ids + runbook URLs |
| `create-servicenow-incident` | INSTANCE_URL, USER, PASSWORD |
| `create-pagerduty-incident` | PD_ROUTING_KEY |
| `cross-link-snow-pd` | INSTANCE_URL, USER, PASSWORD (again) |

Close YAML single task: INSTANCE_URL, USER, PASSWORD, PD_ROUTING_KEY.

Use the **same** SNOW URL/user/pass and **same** PD key in create and close.

---

## After replace — quick verify

| Check | Pass |
| --- | --- |
| Search files for `__` | No matches left (except comments saying “replace”) |
| Search for `confluence.example` | Gone (or intentional) |
| Create and close | Same SNOW URL and PD key |
| Secrets | Not committed to git |

Optional later: switch SNOW tasks to a Dynatrace **Connection** so password is not in the script.

---

## Data flow map

```
Your secrets/IDs
  → replace __…__ in CREATE file
  → replace __…__ in CLOSE file (subset)
  → upload chosen format
```

## Related files

| Path | Why |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | Files to edit |
| `../18-upload-json-or-yaml/` | Upload YAML pair |
| `19.sh` | Grep reminders |

## Commands

See `19.sh` in this folder.
