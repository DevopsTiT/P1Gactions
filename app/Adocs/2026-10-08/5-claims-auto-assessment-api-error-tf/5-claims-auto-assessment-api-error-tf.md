# Claims Auto-Assessment API Error

## Decision tree

```
Splunk: Auto-Assessment API Error - !PRODUCTION!
 Source: index claimsda*, host claims-auto-assessment-api*
  pod name in host.name or k8s.pod.name? → filter both (check query 1, then keep one)
 Match: "] ERROR " in the line
  Splunk terms are case-insensitive → caseSensitive:false
 Exclude: "Error stacktraces are turned on" (startup notice, not a real error)
  → filter not contains(...)
 Schedule: every 10 min, last 10 min, > 0, Trigger Once
  → Records detector, from:now()-10m, identity check → 1 problem while errors continue
 Action: email claims incident list, priority High
  → severity high, pagerduty "0" (email only)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the alert catch? | Any ERROR log line from the claims auto-assessment API pods in production |
| What is excluded? | The "Error stacktraces are turned on" message, which is a harmless startup notice |
| Detector type | Records detector, no `makeTimeseries` |
| Lookback | Last 10 minutes, same as Splunk |
| Problems | One open problem while errors keep appearing (identity `check`) |
| Severity | high (Splunk priority High) |
| PagerDuty | `"0"` (Splunk only sends email) |
| Recipients | Not copied. Route by `app.name = Claims` in the standard flow. |

## Summary

The Splunk alert checks every 10 minutes for ERROR lines from the auto-assessment API pods and emails the claims incident list. The Dynatrace detector runs the same filter every minute over the last 10 minutes. It opens one problem when errors appear and closes it about 10 minutes after the last one.

## Splunk query line by line

| Splunk part | What it means | DQL |
|---|---|---|
| `index=claimsda*` | Claims log indexes | Not needed; Dynatrace has no indexes |
| `host IN ("claims-auto-assessment-api*")` | Only the auto-assessment API pods | `startsWith(host.name, ...) or startsWith(k8s.pod.name, ...)` |
| `("*] ERROR *")` | Lines where the log level after the `]` is ERROR | `contains(content, "] ERROR ", caseSensitive:false)` |
| `NOT ("*Error stacktraces are turned on*")` | Drop the startup notice | `not contains(content, "Error stacktraces are turned on", caseSensitive:false)` |
| `table _time, host, _raw` | Show time, pod, full line | `fields timestamp, host.name, k8s.pod.name, content` |
| `sort _time asc` | Oldest first | `sort timestamp asc` |

## Splunk settings to Dynatrace

| Splunk | Dynatrace |
|---|---|
| Cron `*/10 * * * *` | Detector runs every minute |
| Last 10 minutes | `fetch logs, from:now()-10m` |
| Number of Results > 0 | Any row opens a problem |
| Trigger Once | `alertIdentityFields[0] = check` |
| Expires 10 minutes | Problem closes when no error is in the last 10 minutes |
| Priority High | `alert.severity = high` |

## Terraform

File: `5-claims-auto-assessment-api-error-tf.tf`

```hcl
resource "dynatrace_davis_anomaly_detectors" "claims_auto_assessment_api_error" {
  title   = "Prod_Claims_AutoAssessmentAPI_Error_High"
  enabled = true
  source  = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-10m
          | filter startsWith(host.name, "claims-auto-assessment-api") or startsWith(k8s.pod.name, "claims-auto-assessment-api")
          | filter contains(content, "] ERROR ", caseSensitive:false)
          | filter not contains(content, "Error stacktraces are turned on", caseSensitive:false)
          | fields timestamp, host.name, k8s.pod.name, content
          | sort timestamp asc
          | fieldsAdd check = "claims_auto_assessment_api_error"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
      }
    }
  }
  # event_template: CUSTOM_ALERT, severity high, app.name Claims, pagerduty.enabled "0"
}
```

## Data flow

```
claims-auto-assessment-api pods → stdout logs → OneAgent → Grail
 → Records detector every minute (last 10 min)
   → "] ERROR " line, not the stacktrace notice → 1 problem (check) → high email
   → no error for 10 min → problem closes
```

## Investigation

| What was checked | Finding |
|---|---|
| Edit Alert screenshot | Search, cron `*/10 * * * *`, Last 10 minutes, > 0, Once, no throttle, email, priority High |
| Search screenshot | 2 events, host looks like a Kubernetes pod name (`claims-auto-assessment-api-<hash>`) |
| Recipient | Claims incident distribution lists; not copied |
| PagerDuty | No PagerDuty action visible, so `"0"` |

## Result

| Step | What to do |
|---|---|
| 1 | Run check query 1 to see if the pod name is in `host.name` or `k8s.pod.name`, then keep only that one in the filter |
| 2 | Run check query 2 and compare with the Splunk result |
| 3 | Run check query 3 to see how often it would fire |
| 4 | `terraform plan`, then apply |

## Related files

| File | Purpose |
|---|---|
| `5-claims-auto-assessment-api-error-tf.tf` | Detector |
| `5-claims-auto-assessment-api-error-tf-check.dql` | Check queries |
| `5.sh` | Commands |

## Commands

See `5.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/5-claims-auto-assessment-api-error-tf"
terraform init
terraform validate
terraform plan
```
