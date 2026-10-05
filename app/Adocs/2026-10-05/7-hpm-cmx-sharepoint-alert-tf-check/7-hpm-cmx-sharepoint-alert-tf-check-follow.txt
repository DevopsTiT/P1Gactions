# HPM CMX SharePoint Alert Terraform Check

## Decision tree

```
cmx-sharepoint-api.tf uses dynatrace_log_alert
 resource exists?                          → NO → terraform plan fails (same as the other two files)
 contains(content, "Error")
   case?                                   → DQL contains is case-sensitive; Splunk was not → add caseSensitive: false
   too broad?                              → matches any line with "error"; consider "[ERROR]" or a level field
 hourly cron, last 60 min, throttle 60 min → alert within minutes, keep one problem open, close after 60 quiet minutes
 DYNATRACE_PROBLEM severity MEDIUM         → the detector itself opens the problem; add alert.severity medium
 "_Normal" (not urgent)                    → make sure the SILVA/PagerDuty workflow does NOT page for it
 email to 3 people                         → workflow email task
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. `dynatrace_log_alert` does not exist, so plan fails |
| New issue in this file | `contains(content, "Error")` is case-sensitive in DQL, but Splunk searches ignore case |
| Schedule | Hourly in Splunk; Dynatrace checks every minute, so it alerts faster |
| Throttle 60 minutes | `dealertingSamples = 60` keeps one problem open until an hour without errors |
| Severity MEDIUM, "Normal" | Keep it out of the PagerDuty paging path |
| Secrets | None in this file |

## Summary

Same Splunk-to-Terraform pattern, so the resource must change to `dynatrace_davis_anomaly_detectors`. Two things are specific to this file: the plain word "Error" needs `caseSensitive: false` to behave like Splunk, and the alert is a medium, non-urgent one, so your SILVA and PagerDuty workflow should not page on it.

## Line by line

| Line | Content | OK? | Fix |
|---|---|---|---|
| resource | `dynatrace_log_alert` | No | `dynatrace_davis_anomaly_detectors` |
| alert_name | `Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal` | Not a field | `title` and `event.name` |
| description | "To check Lamda error, ..." | Field OK | Fix the typo "Lamda" to "Lambda" |
| filter log group | `contains(aws.log_group, "/aws/lambda/cmx-sharepoint-api-prod")` | OK | Prefer `==` |
| filter content | `contains(content, "Error")` | Case problem | `contains(content, "Error", caseSensitive: false)` |
| sort, limit 100 | List of lines | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| alert_type, schedule, cron `0 * * * *`, LAST_60_MINUTES, expires 7 | Splunk schedule | No | Not needed; Dynatrace checks every minute |
| trigger > 0, once | Splunk trigger | No | `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| throttle 60 minutes | Splunk suppression | No | `dealertingSamples = 60` |
| DYNATRACE_PROBLEM, severity MEDIUM | Open a problem | Not a field | The detector opens the problem; add `alert.severity = medium` |
| SEND_EMAIL to 3 people, priority, subject | Email | No | Workflow email task |

## The "Error" case issue

| Log line | Splunk `Error` | DQL `contains(content, "Error")` | DQL with `caseSensitive: false` |
|---|---|---|---|
| `[ERROR] Upload failed` | Match | No match | Match |
| `Error: 403 Forbidden` | Match | Match | Match |
| `error while copying file` | Match | No match | Match |

Python Lambdas log `[ERROR]` in capitals, so without the fix the alert would miss most real errors.

The same case rule applies to the earlier conversions (`skipping table`, `Task timed out`, `Windows_LDAP as FAILED`). Those messages normally have fixed case, but adding `caseSensitive: false` makes them behave exactly like Splunk.

"Error" is also very broad. It matches lines like `0 errors` or `retrying after error`. If that becomes noisy, narrow it to `[ERROR]` or to the real failure text, after checking with the query below.

## Hourly schedule vs Dynatrace

| Behaviour | Splunk | Dynatrace |
|---|---|---|
| When it checks | Once an hour at minute 0 | Every minute |
| Delay before alert | Up to 60 minutes | About 1 to 2 minutes |
| Repeat alerts | Suppressed for 60 minutes by throttle | One problem stays open while errors continue |
| When it closes | Never (just stops firing) | After 60 minutes without errors (`dealertingSamples = 60`) |

If you want to keep the old "only bother me hourly" feel, leave the alert as is and just send the email; nobody is paged. If the Anomaly Detection app rejects 60 for dealerting samples, use the largest value it allows.

## Fixed version

Full file: `7-hpm-cmx-sharepoint-alert-tf-check-main.tf`.

```hcl
resource "dynatrace_davis_anomaly_detectors" "hpm_cmx_to_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
  description = "To check Lambda error: failure transferring files from CMX to SharePoint (cmx-sharepoint-api-prod)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cmx-sharepoint-api-prod"
          | filter contains(content, "Error", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "60"
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
        value = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda /aws/lambda/cmx-sharepoint-api-prod logged an error. Failure transferring files from CMX to SharePoint."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}
```

## Routing for a "Normal" alert

| Item | What to do |
|---|---|
| Problem | Opened by the detector (replaces the DYNATRACE_PROBLEM action) |
| PagerDuty | Should not page; if your SILVA/PagerDuty workflow fires on every problem, add a filter that skips titles ending in `_Normal` or `alert.severity = medium` |
| Email | Workflow email task to naoya.sota, chungyueh.chiu and hiroshi.annaka (@axa.co.jp); check spelling against the original file |
| Subject | `Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal` |

## Check the query before apply

```dql
fetch logs, from:-7d
| filter aws.log_group == "/aws/lambda/cmx-sharepoint-api-prod"
| filter contains(content, "Error", caseSensitive: false)
| summarize count = count(), by:{line = substring(content, from:0, to:120)}
| sort count desc
| limit 30
```

This groups the matching lines so you can see what "Error" actually catches and decide whether to narrow it.

## Data flow

```
Lambda cmx-sharepoint-api-prod (CMX → SharePoint file transfer)
  → CloudWatch /aws/lambda/cmx-sharepoint-api-prod
  → Dynatrace AWS log forwarding (aws.log_group)
  → Grail logs
  → detector: lines containing "error" (any case) per minute, window 5, > 0
  → Davis event CUSTOM_ALERT, alert.severity medium
  → Problem → workflow email to 3 people (no PagerDuty page)
  → 60 minutes without errors → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot `cmx-sharepoint-api.tf` | Same `dynatrace_log_alert` pattern; hourly cron, 60-minute range, throttle 60 minutes, DYNATRACE_PROBLEM medium, email to 3 |
| DQL `contains` | Case-sensitive unless `caseSensitive: false` is set |
| Splunk search terms | Case-insensitive, so the old alert matched ERROR, Error and error |
| Secrets | None in this file |

## Result

Not OK as is. Switch to `dynatrace_davis_anomaly_detectors`, add `caseSensitive: false` to the "Error" filter, use `dealertingSamples = 60` instead of the throttle, send email from a workflow, and make sure this medium alert doesn't trigger PagerDuty.

## Related files

| File | Purpose |
|---|---|
| `7-hpm-cmx-sharepoint-alert-tf-check-main.tf` | Fixed resource |
| `7.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/6-cci-batch-timeout-alert-tf-check/` | Previous file check |
| `2026-10-05/5-compass-glue-skip-alert-tf-review/` | First file check |

## Commands

See `7.sh` (not run).
