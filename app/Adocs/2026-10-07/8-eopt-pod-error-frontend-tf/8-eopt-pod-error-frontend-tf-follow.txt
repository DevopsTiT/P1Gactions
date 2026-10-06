# eopt Pod Error Frontend Alert

## Decision Tree

```
Splunk Frontend: index eopt-prod-axa-li-jp | spath | upper(level) = "ERROR" → email
 → Dynatrace: parse content as JSON → upper(level) == "ERROR" → one medium problem
 plain-text backend lines → JSON parse gives nothing → skipped (Backend alert covers them)
 check.dql query 1 → no JSON lines from eopt pods?
   → frontend logs not ingested or not JSON → fix ingest, else the alert never fires
 check.dql query 4 → loglevel filled for frontend pods? → use loglevel == "ERROR"
```

## Short Takeaway

| Question | Answer |
|---|---|
| Difference from Backend | Backend reads the level from plain text; Frontend reads a JSON `level` field |
| Splunk `spath` | Parses the event as JSON |
| Dynatrace equivalent | `parse content, "JSON:j"` then `j[level]` |
| Case | `upper()` on both sides, so error, Error and ERROR all match |
| Your 11 "ERROR" events | All backend plain-text lines, so the Frontend alert would not fire on them |
| Notification | Email only, priority Normal: severity medium, `pagerduty.enabled = "0"` |

## Summary

The Frontend alert searches the same eopt index as the Backend alert, but treats each event as JSON and checks its `level` field in any case. In Dynatrace, `parse content, "JSON:j"` turns the line into a record and `j[level]` reads the field. Plain-text backend lines don't parse as JSON, so they're skipped, just like in Splunk. The 11 ERROR events in your search are all backend lines, so this alert would have stayed quiet.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index="eopt-prod-axa-li-jp"` | `startsWith(host.name, "eopt")` |
| `spath` | `parse content, "JSON:j"` |
| `eval level=upper(level)` | `upper(toString(j[level]))` |
| `search level="ERROR"` | `== "ERROR"` |
| Run every hour at :00 | Checks every minute and looks back 2 hours |
| Results > 0 | Any row raises an alert |
| For each result | One problem (`alertIdentityFields[0] = check`) |
| Email, priority Normal | `alert.severity medium`, `pagerduty.enabled 0` |

## Backend Compared With Frontend

| Topic | Backend (seq 7) | Frontend (seq 8) |
|---|---|---|
| Log format | Plain text: `<timestamp>Z ERROR ...` | JSON: `{"level":"error", ...}` |
| Splunk extract | `rex` on the line start | `spath` |
| Dynatrace filter | `contains(content, "Z ERROR ")` | `parse JSON`, then `upper(j[level]) == "ERROR"` |
| Case | Capitals only | Any case |
| Resource name | eopt_openpaas_pod_error | eopt_openpaas_pod_error_frontend |

## Query

```
fetch logs
| filter startsWith(host.name, "eopt")
| parse content, "JSON:j"
| filter upper(toString(j[level])) == "ERROR"
| fieldsRemove j
| fieldsAdd check = "eopt_frontend_error"
```

## Data Flow

```
eopt pods → S3 log forwarder → Grail
  → JSON line with level error (any case)? → one medium problem → email
  → plain-text line → not JSON → skipped (Backend detector handles it)
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | spath, upper(level), level="ERROR"; hourly at :00, > 0, email priority Normal |
| Search screenshot | index eopt "ERROR": 11 events, all plain-text backend lines from eoptsystemapi |
| Frontend JSON | Not visible in the screenshots; confirm with check.dql queries 1 and 2 |
| Recipients | Team list plus one personal address; not copied |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to find which eopt pods write JSON |
| 2 | Narrow `startsWith(host.name, "eopt")` to the frontend pod prefix if you know it |
| 3 | Run query 4; if loglevel is filled in, use `loglevel == "ERROR"` |
| 4 | `terraform plan` shows 1 to add |

## Related Files

| File | Purpose |
|---|---|
| `8-eopt-pod-error-frontend-tf.tf` | Frontend detector Terraform |
| `8-eopt-pod-error-frontend-tf-check.dql` | Check queries |
| `8.sh` | Commands |
