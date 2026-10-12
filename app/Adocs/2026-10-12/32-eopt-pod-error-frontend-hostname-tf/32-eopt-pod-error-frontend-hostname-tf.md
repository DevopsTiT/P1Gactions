# eopt Pod Error Frontend Host Name Alert

## Decision tree

```
Splunk: index=eopt-prod-axa-li-jp | spath | eval level=upper(level) | level="ERROR"
 spath → line is JSON → frontend pods write JSON
 scope → host.name starts with "eoptfrontend-"
 spath + level → parse content "JSON:j" → level = upper(j[level])
 every hour → from:now()-1h
 > 0 → any line → one problem (service eoptfrontend, medium)
 email Normal → PagerDuty 0
 Dynatrace already sets loglevel from JSON? → simpler: filter loglevel == "ERROR"
 backend alert (answer 31) still lists eoptfrontend-? → remove it to avoid overlap
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | Frontend JSON log lines whose `level` is ERROR, any case, in the last hour. |
| Scope | Host names starting with `eoptfrontend-`. |
| How is the level found? | `parse content, "JSON:j"`, then read `j[level]` and make it upper case. |
| Severity | medium, PagerDuty off. |
| Pair with | Answer 31 (Backend). Remove the frontend line there. |

## Summary

The Frontend alert uses `spath` instead of `rex`, which means the lines are JSON and the level is a JSON key. In Dynatrace the same is done with a JSON parse. Scoping by the `eoptfrontend-` host prefix keeps it to the frontend pods, and the backend alert should drop its frontend line so the two do not overlap.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| `spath` | Splunk command that reads fields out of JSON text. | Tells us the frontend lines are JSON. |
| JSON | Text made of `"key": value` pairs, like `{"level":"error","message":"..."}`. | The level is one of the keys. |
| `parse content, "JSON:j"` | DQL that turns the JSON text into a record named `j`. | Then `j[level]` gives the level. |
| `upper()` | Turns text into capital letters. | Same as Splunk `eval level=upper(level)`. Catches `error` and `Error`. |
| `loglevel` | Dynatrace field that may already hold the level if Dynatrace read the JSON on intake. | Could replace the parse. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index="eopt-prod-axa-li-jp"` | `startsWith(host.name, "eoptfrontend-")` |
| `spath` | `parse content, "JSON:j"` |
| `eval level=upper(level)` | `fieldsAdd level = upper(toString(j[level]))` |
| `search level="ERROR"` | `filter level == "ERROR"` |
| Run every hour at minute 0 | `from:now()-1h`. The detector runs every minute. |
| Expires 24 hours | Dropped. |
| Results greater than 0 | Detector default. |
| Throttle off | Identity `service` keeps one open problem. |
| Send email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`. Workflow sends email. Recipients not copied. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |
| Description Optional | Replaced with a real description. |

### Why scope to the frontend

| Point | What it means |
|---|---|
| Splunk searched the whole index | Backend lines are plain text, so `spath` found no `level` key in them. In practice only JSON lines, the frontend ones, could match. |
| Dynatrace version | Uses the `eoptfrontend-` prefix to say that directly. |
| Backend alert overlap | Answer 31 includes `eoptfrontend-`. Its `rex` only matches plain lines, so frontend JSON rarely matches, but remove the line to keep the two alerts clean. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_frontend" {
  title       = "eopt - OpenPaaS Pod Error (Frontend)"
  description = "An eopt frontend pod (eoptfrontend) on OpenPaaS logged a JSON line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter startsWith(host.name, "eoptfrontend-")
          | parse content, "JSON:j"
          | fieldsAdd level = upper(toString(j[level]))
          | filter level == "ERROR"
          | fieldsAdd service = "eoptfrontend"
          | fieldsRemove j
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "service"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "eopt - OpenPaaS Pod Error (Frontend)"
      }
      property {
        key   = "event.description"
        value = "eopt frontend logged level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "eopt"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
```

### Change to make in answer 31 (Backend)

Remove this line from its query, so frontend lines only go to this alert:

```
              or startsWith(host.name, "eoptfrontend-")
```

### Simpler version if Dynatrace already reads the JSON

If check query 1 shows `loglevel` filled with ERROR on frontend lines, you can drop the parse:

```
fetch logs, from:now()-1h
| filter startsWith(host.name, "eoptfrontend-")
| filter upper(loglevel) == "ERROR"
| fieldsAdd service = "eoptfrontend"
```

## Data flow map

```
eoptfrontend-* pods on OpenPaaS
  → JSON log {"level":"error", ...}
  → Dynatrace Grail logs (host.name = pod name)
  → detector every minute, last 1 h
       parse JSON → upper(level) == ERROR → problem (medium)
  → workflow: pagerduty.enabled = "0" → email
  → no ERROR for 1 h → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `32-eopt-pod-error-frontend-hostname-tf.tf` | Full Terraform. |
| `32-eopt-pod-error-frontend-hostname-tf-check.dql` | Three check queries. |
| `../31-eopt-pod-error-backend-hostname-tf/31-eopt-pod-error-backend-hostname-tf.tf` | Backend pair. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `32.sh` | Commands, one per line. |

## Commands

All commands are in [`32.sh`](./32.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/32-eopt-pod-error-frontend-hostname-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/32-eopt-pod-error-frontend-hostname-tf
git commit -m "eopt frontend pod error detector on host names"
git push
```
