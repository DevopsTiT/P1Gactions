# eopt Pod Error Frontend All Hosts

## Decision tree

```
Both eopt alerts use the same host filter (whole Splunk index)
 host.name starts with eoptsystemapi- / eoptprocessapi- / eoptfrontend-
   Backend alert (answer 31) → plain text line → parse "timestamp level" → ERROR
   Frontend alert (this one) → JSON line → parse JSON → upper(level) → ERROR
 plain lines fail the JSON parse → only JSON lines reach the Frontend alert
 JSON lines fail the "timestamp level" check → only plain lines reach the Backend alert
 → same scope, no double counting
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from answer 32? | The host filter now lists all three prefixes, the same as the Backend alert. |
| Why is that safe? | The JSON parse only succeeds on JSON lines, like Splunk `spath`. Plain backend lines drop out. |
| Pair with | Answer 31 (Backend, same three prefixes). |
| Severity | medium, PagerDuty off. |
| Apply | Answers 31 and 34. Not 27, 30, 32 or 33. |

## Summary

Both alerts now share the exact host filter you gave, which mirrors the whole Splunk index. The difference between them is only how the level is read: the Backend alert reads it from the start of a plain line, and the Frontend alert reads it from a JSON key. Each line can only match one of the two.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| `spath` | Splunk command that reads JSON fields. | Only JSON lines have a `level` to read. |
| `parse content, "JSON:j"` | DQL that turns JSON text into a record `j`. | On plain text lines, `j` stays empty, so the line drops out. |
| `upper()` | Capital letters. | Same as Splunk `eval level=upper(level)`. |
| Identity field | Field deciding one problem or many. | One problem per service. |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index="eopt-prod-axa-li-jp"` | The three `startsWith(host.name, ...)` checks. |
| `spath` | `parse content, "JSON:j"` |
| `eval level=upper(level)` | `fieldsAdd level = upper(toString(j[level]))` |
| `search level="ERROR"` | `filter level == "ERROR"` |
| Every hour at minute 0 | `from:now()-1h` |
| Results greater than 0 | Detector default. |
| Email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`. Workflow sends email. |

### How the two alerts split the lines

| Line type | Example | Backend alert | Frontend alert |
|---|---|---|---|
| Plain text | `2026-10-12T09:18:54.959Z ERROR [ip: ...]` | Matches | JSON parse fails, drops out |
| JSON | `{"timestamp":"2026-10-12 18:18:58.055","level":"error",...}` | First word is not an ISO timestamp, drops out | Matches |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_frontend" {
  title       = "eopt - OpenPaaS Pod Error (Frontend)"
  description = "An eopt pod on OpenPaaS logged a JSON line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter startsWith(host.name, "eoptsystemapi-")
              or startsWith(host.name, "eoptprocessapi-")
              or startsWith(host.name, "eoptfrontend-")
          | parse content, "JSON:j"
          | fieldsAdd level = upper(toString(j[level]))
          | filter level == "ERROR"
          | fieldsAdd service = if(startsWith(host.name, "eoptsystemapi-"), "eoptsystemapi",
                                else: if(startsWith(host.name, "eoptprocessapi-"), "eoptprocessapi",
                                else: "eoptfrontend"))
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
        value = "eopt - OpenPaaS Pod Error (Frontend): {service}"
      }
      property {
        key   = "event.description"
        value = "eopt service {service} logged a JSON line with level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
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

### Which eopt files to apply

| Answer | Alert | Host filter | Apply? |
|---|---|---|---|
| 31 | Backend | All three prefixes | Yes |
| 34 | Frontend | All three prefixes | Yes |
| 27, 30, 32, 33 | Earlier versions | Different scopes | No |

## Data flow map

```
eoptsystemapi-* ─┐
eoptprocessapi-* ┼→ Grail logs (host.name = pod)
eoptfrontend-*  ─┘
   ├─ plain "…Z ERROR …" → Backend detector (answer 31) → problem per service
   └─ JSON {"level":"error"} → Frontend detector (answer 34) → problem per service
   → workflow: pagerduty.enabled = "0" → email
```

## Related files

| File | What it holds |
|---|---|
| `34-eopt-pod-error-frontend-all-hosts-tf.tf` | Full Terraform. |
| `34-eopt-pod-error-frontend-all-hosts-tf-check.dql` | Two check queries. |
| `../31-eopt-pod-error-backend-hostname-tf/31-eopt-pod-error-backend-hostname-tf.tf` | Backend pair. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `34.sh` | Commands, one per line. |

## Commands

All commands are in [`34.sh`](./34.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/34-eopt-pod-error-frontend-all-hosts-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/34-eopt-pod-error-frontend-all-hosts-tf
git commit -m "eopt frontend pod error detector with shared host filter"
git push
```
