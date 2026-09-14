# How To Replace Placeholders

```
How do I replace the __…__ tokens?
  │
  ├─ 1 Collect real values (SNOW + PD) into a private note
  ├─ 2 Open the YAML you will upload (recommended)
  ├─ 3 Find & Replace each token exactly (whole string)
  ├─ 4 Repeat shared tokens in the CLOSE YAML
  └─ 5 Search for "__" — should find none left in scripts
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Method | Editor **Find and Replace** (or sed) — replace the whole `__TOKEN__` string |
| Which files | Create YAML + close YAML (if that is what you upload) |
| Quotes | Keep the quotes; only change what is inside (or replace including quotes carefully) |
| Secrets | Do not commit passwords/routing keys to git |

## Summary

First gather each real value from ServiceNow and PagerDuty. Then open the workflow file and replace every `__TOKEN__` with that value using Find and Replace. Use the same SNOW URL/user/pass and PD key in both create and close files.

---

## Step 1 — Collect values (private notepad)

Make a private list (Notes / 1Password / local file **not** in git):

| Token | Your value (fill in) | Where to get it |
| --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | `https://_____.service-now.com` | Browser address bar of ServiceNow (no path after host) |
| `__SNOW_USER__` | | Integration user from SNOW admin |
| `__SNOW_PASSWORD__` | | That user’s password |
| `__PD_ROUTING_KEY__` | | PagerDuty → Service → Integrations → Events API v2 → Integration Key |
| `__SNOW_CALLER_SYS_ID__` | | SNOW user record → sys_id (see below) |
| `__SNOW_GROUP_SYS_ID_EIP__` | | Assignment group for EIP → sys_id |
| `__SNOW_GROUP_SYS_ID_CCI__` | | Assignment group for CCI → sys_id |
| `__SNOW_GROUP_SYS_ID_DEFAULT__` | | Default/fallback group → sys_id |
| `__SNOW_BIZ_SYS_ID_EIP__` | | Business service for EIP → sys_id |
| `__SNOW_BIZ_SYS_ID_CCI__` | | Business service for CCI → sys_id |
| `__SNOW_BIZ_SYS_ID_DEFAULT__` | | Default business service → sys_id |

### How to copy a ServiceNow `sys_id`

| Method | Steps |
| --- | --- |
| A — From form URL | Open the user/group/service record → look at URL for `sys_id=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| B — From list | Right‑click row header → **Show XML** / configure list to show `sys_id` column (admin) |
| C — From script | Ask SNOW admin for the sys_ids if you cannot see them |

`sys_id` is usually a 32-character hex string.

### Instance URL format

| Good | Bad |
| --- | --- |
| `https://mycompany.service-now.com` | `https://mycompany.service-now.com/nav_to.do?...` |
| No trailing slash required | Do not leave `__SNOW_INSTANCE_URL__` |

---

## Step 2 — Open the file(s) you will upload

Recommended folder:

`Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/`

| File | Replace which tokens |
| --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | **All 11** |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | Only first **4** (URL, USER, PASSWORD, PD key) |

If you upload JSON instead, do the same inside the two `.workflow.json` files (same token names).

---

## Step 3 — Replace with Find and Replace

### In Cursor / VS Code

1. Open the create YAML  
2. `Cmd+F` (Find)  
3. Turn on **Replace** (`Cmd+Option+F` / `Cmd+H` depending on OS)  
4. Find: `__SNOW_INSTANCE_URL__`  
5. Replace: `https://mycompany.service-now.com`  
6. Click **Replace All**  
7. Repeat for every token in the table  

| Tip | Why |
| --- | --- |
| Match whole token including both `__` | Avoid partial mistakes |
| Replace All per token | Create YAML has some tokens in **two** places (SNOW URL appears in create + cross-link) |
| Keep surrounding quotes | Line looks like `const snowBase = "https://...";` |

### Example before → after

**Before:**
```javascript
const snowBase = "__SNOW_INSTANCE_URL__";
const snowUser = "__SNOW_USER__";
const snowPass = "__SNOW_PASSWORD__";
const routingKey = "__PD_ROUTING_KEY__";
callerSysId: "__SNOW_CALLER_SYS_ID__",
groupSysId: "__SNOW_GROUP_SYS_ID_EIP__",
```

**After:**
```javascript
const snowBase = "https://mycompany.service-now.com";
const snowUser = "dynatrace.workflow";
const snowPass = "your-real-password";
const routingKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
callerSysId: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
groupSysId: "f6e5d4c3b2a1f6e5d4c3b2a1f6e5d4c3",
```

(Use your real values — examples above are fake.)

---

## Step 4 — Close file (shared four only)

Open `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` and replace:

1. `__SNOW_INSTANCE_URL__`  
2. `__SNOW_USER__`  
3. `__SNOW_PASSWORD__`  
4. `__PD_ROUTING_KEY__`  

Use the **exact same** four values as in the create file.

---

## Step 5 — Verify

| Check | How |
| --- | --- |
| No tokens left | Search the file for `__SNOW_` and `__PD_` — should find **0** |
| Same secrets | Create and close have identical URL/user/pass/PD key |
| Quotes intact | Still valid JS strings inside `"..."` |
| Optional | Also replace `https://confluence.example/runbooks/...` with real runbook URLs |

---

## Optional: command-line replace (you run yourself)

One token example (run from the folder; put your real value):

```bash
# Example only — put YOUR url; do not commit secrets
# sed -i '' 's|__SNOW_INSTANCE_URL__|https://mycompany.service-now.com|g' ago-problem-to-snow-pagerduty.workflow-template.yaml
```

Repeat per token for create YAML, then for close YAML. Prefer the editor if you are not comfortable with `sed`.

---

## Security notes

| Do | Do not |
| --- | --- |
| Keep password/PD key in a password manager | Paste secrets into git / chat / Slack |
| Prefer Dynatrace ServiceNow **Connection** after import | Leave `__SNOW_PASSWORD__` unreplaced |
| Restrict who can read the workflow script | Commit filled YAML with real password |

---

## Data flow map

```
[Get values from SNOW + PD]
        │
        ▼
[Private note with 11 values]
        │
        ├─► Find/Replace in CREATE YAML (all 11)
        └─► Find/Replace in CLOSE YAML (4 shared)
                │
                ▼
        Search "__" → none left → Upload
```

## Related files

| Path | Why |
| --- | --- |
| `../19-replace-placeholders-exact/` | Exact token list |
| `../4-snow-pd-workflow-yaml-and-json/` | Files to edit |
| `../18-upload-json-or-yaml/` | Upload after replace |
| `20.sh` | Verify search reminders |

## Commands

See `20.sh` in this folder.
