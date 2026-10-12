# eopt OpenPaaS Pod Error Backend

## Decision tree

```
Splunk: index=eopt-prod-axa-li-jp | rex timestamp + level | level="ERROR"
 index → 12 pod host names
   backend → eoptsystemapi-* and eoptprocessapi-* → keep
   frontend → eoptfrontend-* → left out (alert says Backend)
   pod name in host.name or k8s.pod.name? → coalesce both
 rex "^timestamp level" → parse "NSPACE:log_ts SPACE+ ALPHA:level"
 eval upper + search ERROR → filter level == "ERROR"
 Run every hour → from:now()-1h
 results > 0 → any line
 email Normal → medium, PagerDuty 0
 parse returns no levels? → check query 2 → adjust pattern
 frontend errors matter too? → check query 4 → add eoptfrontend-
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | Any backend pod log line whose level is ERROR in the last hour. |
| Which pods? | Names starting with `eoptsystemapi-` or `eoptprocessapi-`. |
| How is the level found? | `parse` reads the first two words of the line: timestamp and level. |
| Identity | `service`, so one problem for systemapi and one for processapi. |
| Severity | medium, PagerDuty off, because the only action was a Normal email. |

## Summary

The Splunk alert reads the log level from the start of each line and keeps only ERROR. The Dynatrace detector does the same with `parse`, scoped to the backend pod name prefixes. Pod names change on every deploy, so the prefix is the stable reference, and the problem is grouped per service, not per pod.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| eopt | The application owning these pods. | App name on the problem. |
| OpenPaaS | The Kubernetes platform running the pods. | Pod names come from it. |
| Pod | One running copy of an app. Name is app plus random letters. | Match the prefix, not the full name. |
| `rex` | Splunk command that pulls fields out of text with a regular expression. | Replaced by DQL `parse`. |
| `parse` | DQL command that pulls fields out of text with a pattern. | Gets `log_ts` and `level`. |
| `NSPACE` | Pattern for characters up to the next space. | Captures the timestamp. |
| `ALPHA` | Pattern for letters only. | Captures the level word. |
| `coalesce` | Takes the first field that has a value. | Works whether the pod name is in `k8s.pod.name` or `host.name`. |

### Host names from Splunk

| Host (top values) | Service |
|---|---|
| eoptsystemapi-564c45bd9f-joqtl | eoptsystemapi |
| eoptsystemapi-564c45bd9f-drgst | eoptsystemapi |
| eoptprocessapi-7d49b9556c-egtxs | eoptprocessapi |
| eoptprocessapi-7d49b9556c-5whbq | eoptprocessapi |
| eoptsystemapi-564c45bd9f-l6f4n | eoptsystemapi |
| eoptprocessapi-7d49b9556c-kdk88 | eoptprocessapi |
| eoptfrontend-688699b68f-flt32 | eoptfrontend (left out) |
| eoptfrontend-688699b68f-ktnn9 | eoptfrontend (left out) |

There are 12 values in total. Pod suffixes are read from a blurry photo and do not matter, because only the prefix is used.

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index="eopt-prod-axa-li-jp"` | Pod name starts with `eoptsystemapi-` or `eoptprocessapi-`. |
| `rex "^(?<timestamp>...Z)\s+(?<level>[A-Z]+)"` | `parse content, "NSPACE:log_ts SPACE+ ALPHA:level"` plus a check that `log_ts` contains `T` and ends with `Z`. |
| `eval level=upper(level)` | Not needed. The Splunk regex already only accepts capital letters. |
| `search level="ERROR"` | `filter level == "ERROR"` |
| Run every hour at minute 0 | `from:now()-1h`. The detector runs every minute. |
| Expires 24 hours | Dropped. |
| Results greater than 0 | Detector default. |
| Send email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`. Workflow sends email. No recipients copied. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |
| Description Optional | Replaced with a real description. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_backend" {
  title       = "eopt - OpenPaaS Pod Error (Backend)"
  description = "An eopt backend pod (eoptsystemapi or eoptprocessapi) on OpenPaaS logged a line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | fieldsAdd pod = coalesce(k8s.pod.name, host.name)
          | filter startsWith(pod, "eoptsystemapi-") or startsWith(pod, "eoptprocessapi-")
          | parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
          | filter level == "ERROR"
          | filter endsWith(log_ts, "Z") and contains(log_ts, "T")
          | fieldsAdd service = if(startsWith(pod, "eoptsystemapi-"), "eoptsystemapi", else:"eoptprocessapi")
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
        value = "eopt - OpenPaaS Pod Error (Backend): {service}"
      }
      property {
        key   = "event.description"
        value = "eopt backend service {service} logged level ERROR in the last hour. See pod and the matching log lines (content) on the problem."
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

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Shows whether pod names are in `k8s.pod.name` or `host.name`. |
| Check query 2 | Confirms the parse finds levels such as DEBUG, INFO, WARN and ERROR. If `level` is empty, the line format in Dynatrace is different. |
| Check query 3 | ERROR lines per hour per service. Many per hour means the email will be constant. |
| Check query 4 | Frontend errors. The Splunk search covered the whole index, including frontend pods. If the team wants them, add `or startsWith(pod, "eoptfrontend-")` and a third service name. |
| Window | 1 hour keeps the problem open for an hour after the last error. Use `from:now()-15m` if you want faster closing. |

## Data flow map

```
eopt backend pods on OpenPaaS
  eoptsystemapi-*  ─┐
  eoptprocessapi-* ─┤ log "2026-...Z ERROR ..."
  eoptfrontend-*   ─┘ (left out)
  → S3 log forwarder → Dynatrace Grail logs
  → detector every minute, last 1 h
       parse level → ERROR → one problem per service (medium)
  → workflow: pagerduty.enabled = "0" → email
  → no ERROR for 1 h → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `27-eopt-openpaas-pod-error-backend-tf.tf` | Full Terraform. |
| `27-eopt-openpaas-pod-error-backend-tf-check.dql` | Four check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `27.sh` | Commands, one per line. |

## Commands

All commands are in [`27.sh`](./27.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/27-eopt-openpaas-pod-error-backend-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/27-eopt-openpaas-pod-error-backend-tf
git commit -m "eopt OpenPaaS backend pod error detector"
git push
```
