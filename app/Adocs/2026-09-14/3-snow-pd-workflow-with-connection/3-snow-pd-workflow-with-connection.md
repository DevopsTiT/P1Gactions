# SNOW PD Workflow With Connection

```
Want SNOW without password in YAML/JSON?
  │
  ├─ Create Dynatrace ServiceNow Connection first
  ├─ Upload Connection-based create + close (YAML preferred)
  ├─ Map Connection on import / in each SNOW task
  └─ Still replace: PD key + group/biz/caller sys_ids (config)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What changed | SNOW create / comment / search / resolve use **Connection** actions |
| Removed from file | `__SNOW_INSTANCE_URL__`, `__SNOW_USER__`, `__SNOW_PASSWORD__` |
| Still replace | `__PD_ROUTING_KEY__`, group/biz/caller sys_ids, runbook URLs |
| Upload | Prefer the two `*-connection.workflow-template.yaml` files |

## Summary

These files replace Basic-auth JavaScript for ServiceNow with Dynatrace connector actions (`snow-create-incident`, `snow-comment-on-incident`, `snow-search-incidents`, `snow-resolve-incident`). Credentials live in Settings → Connections → ServiceNow. PagerDuty is still JS with a routing key (fill in UI or secret later).

**Upload schema (tenant):** `categories`/`entityTags` are dictionaries; task `position.y` starts at 1; open/close use `filterQuery` (no `onProblemClose` field). Fixed after Error 400 — see `../5-fix-upload-schema-error/`.

---

## Files in this folder

| File | Role |
| --- | --- |
| `ago-problem-to-snow-pagerduty-connection.workflow-template.yaml` | Create (OPEN) — YAML template |
| `ago-problem-closed-resolve-snow-pd-connection.workflow-template.yaml` | Close — YAML template |
| `problem-to-snow-pagerduty-connection.workflow.json` | Create — JSON twin |
| `problem-closed-resolve-snow-pd-connection.workflow.json` | Close — JSON twin |

Old Basic-auth pack (unchanged): `../../2026-09-13/4-snow-pd-workflow-yaml-and-json/`

---

## Before upload

| Step | Action |
| --- | --- |
| 1 | Install **ServiceNow** app for Workflows from Hub if needed |
| 2 | Settings → Connections → ServiceNow → create Connection (URL + user/password or OAuth) |
| 3 | Workflows → Authorization → enable `app-settings:objects:read` |
| 4 | Replace `__PD_ROUTING_KEY__` and `__SNOW_*_SYS_ID_*__` / runbooks in create prepare |
| 5 | Upload create YAML → map Connection to SNOW tasks |
| 6 | Upload close YAML → map same Connection |
| 7 | Set both Active; test open then close |

Docs: [ServiceNow Connector](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/default-workflow-actions/actions/service-now)

---

## Task graph — create

```
prepare-payload (JS)
    ├──► snow-create-incident (Connection)
    └──► create-pagerduty (JS, PD key)
              │
              ▼
     snow-comment-on-incident (Connection)
```

## Task graph — close

```
prepare-close-ids (JS)
    ├──► snow-search-incidents (Connection)
    │         └──► snow-resolve-incident (Connection, if found)
    └──► resolve-pagerduty (JS)
```

---

## Placeholders left

| Still in file | Why |
| --- | --- |
| `__PD_ROUTING_KEY__` | PD has no Connection in this pack |
| `__SNOW_GROUP_SYS_ID_*__` | Config for assignment group |
| `__SNOW_BIZ_SYS_ID_*__` | Written into description (Create Incident action has no biz field) |
| `__SNOW_CALLER_SYS_ID__` | Kept in prepare; connector `caller` uses display name string |

| Gone | Where credentials go now |
| --- | --- |
| `__SNOW_INSTANCE_URL__` | Connection |
| `__SNOW_USER__` | Connection |
| `__SNOW_PASSWORD__` | Connection |

---

## After import — verify in UI

| Check | What to do |
| --- | --- |
| Connection selected | Each SNOW task shows your Connection name |
| Category / subcategory | Must match your SNOW choices (Software / Application may need edit) |
| Create returns `number` | Cross-link comment needs INC number |
| Resolve code | `Solved (Permanently)` must exist in your SNOW close codes |

If `snow-resolve-incident` action ID differs in your tenant, pick **Resolve incident** from the action picker and re-save.

---

## Data flow map

```
Dynatrace Connection (SNOW URL + user/pass)
        │
        ▼
Create WF: prepare → SNOW Create Incident + PD → Comment
Close WF:  prepare ids → Search INC → Resolve INC + Resolve PD
```

## Related files

| Path | Why |
| --- | --- |
| `../../2026-09-13/22-better-than-hardcoded-placeholders/` | Why Connection is better |
| `../../2026-09-13/4-snow-pd-workflow-yaml-and-json/` | Old Basic-auth pack |
| `3.sh` | List / upload reminders |

## Commands

See `3.sh` in this folder.
