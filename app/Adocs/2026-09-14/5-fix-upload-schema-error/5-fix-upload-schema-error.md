# Fix Upload Schema Error

```
Upload Error 400?
  │
  ├─ position.y < 1 → set y starting at 1
  ├─ categories/entityTags as [] → use dictionaries
  ├─ onProblemClose / entityTagsMatch / maintenance… → remove
  │     use filterQuery for OPEN vs CLOSED instead
  └─ Also allow https://silvastg.service-now.com in External Requests
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Cause | Tenant schema rejected old trigger fields and `y: 0` |
| Fixed files | Connection pack YAML + JSON in `../3-snow-pd-workflow-with-connection/` |
| Your Connection | `ServiceNowTest` → `https://silvastg.service-now.com` (OAuth) |
| Silva | Your SNOW staging host `silvastg` — not a separate product |

## Summary

The upload failed validation. Files are updated: task positions start at `y: 1`, Problem categories/entityTags are objects, forbidden trigger keys are removed, and open/close use `filterQuery`. Re-upload the fixed YAML. Also add `silvastg.service-now.com` to External Requests (banner on your Connection screen).

---

## What the Error 400 meant

| Error text | Fix applied |
| --- | --- |
| `position.y` must be ≥ 1 | First task `y: 1`, then 2, 3… |
| `entityTags` must be a dictionary | `entityTags: {}` (not `[]`) |
| `categories` must be a dictionary | `error/resource/slowdown/availability: true` |
| `onProblemClose` not permitted | Removed; open/close via `filterQuery` |
| `entityTagsMatch` not permitted | Removed |
| `maintenanceWindowTriggerBehavior` not permitted | Removed |

---

## Re-upload steps

1. Use fixed files from:
   `Daily Files/2026-09-14/3-snow-pd-workflow-with-connection/`
2. Prefer YAML:
   - `ago-problem-to-snow-pagerduty-connection.workflow-template.yaml`
   - `ago-problem-closed-resolve-snow-pd-connection.workflow-template.yaml`
3. On import, select Connection **`ServiceNowTest`**
4. Settings → External requests → allow `https://silvastg.service-now.com` (and `events.pagerduty.com` for PD)
5. Set both workflows Active

---

## Connection reminder (from your screenshot)

| Field | Your value |
| --- | --- |
| Connection name | `ServiceNowTest` |
| Instance | `https://silvastg.service-now.com` |
| Type | OAuth Client Credentials |

---

## Data flow map

```
Error 400 (bad schema)
  → fixed trigger + positions in Connection pack
  → re-upload YAML
  → map ServiceNowTest
  → allow silvastg in External Requests
```

## Related files

| Path | Why |
| --- | --- |
| `../3-snow-pd-workflow-with-connection/` | Fixed upload files |
| `../4-create-servicenow-connection-steps/` | How you built the Connection |
| `5.sh` | Reminders |

## Commands

See `5.sh` in this folder.
