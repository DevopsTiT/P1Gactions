# HPM CMX To SharePoint Lambda Error Detector

## Decision tree

```
cmx-sharepoint-api.tf ("dynatrace_log_alert")
 resource type not in provider → rewrite as dynatrace_davis_anomaly_detectors
 query
   keep the two filters; add from:now()-60m (old time range LAST_60_MINUTES)
   "Error" case-insensitive → may also match harmless lines → check query 2
 cron hourly + throttle 60 minutes → detector runs every minute; identity field keeps one problem open
 action DYNATRACE_PROBLEM MEDIUM → alert.severity = "medium"
 no PagerDuty action → pagerduty.enabled = "0"
 email recipients → workflow (not copied)
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The `dynatrace_log_alert` resource became a Records detector. |
| Query | The same two filters, plus `from:now()-60m`. No `summarize`. |
| Severity | Medium, from the old Dynatrace problem action. |
| PagerDuty | Off (`"0"`), because the old file had no PagerDuty action. |
| Email | Set it up in the workflow. Recipients were not copied. |

## Summary

This is the same conversion as the CCI timeout alert. The query keeps the old log group and "Error" filters and uses the old 60-minute window. The Splunk-style schedule, throttle and actions turn into detector settings and event properties.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces the scheduled "results > 0" alert. |
| `alertIdentityFields` | Fields that decide which rows belong to one problem. | Does the job the 60-minute throttle used to do. |
| `pagerduty.enabled` | Event property the workflow reads to decide whether to page. | `"0"` means no page, only the problem and email. |

### Old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal` | `title` and `event.name` |
| `description` | Lambda error when transferring files from CMX to SharePoint | `description` (the "Lamda" typo is fixed) |
| `search_query` | log group and "Error" filters | `query.expression` |
| `cron_expression` | `0 * * * *` (hourly) | Not needed. The detector runs every minute. |
| `time_range` | `LAST_60_MINUTES` | `from:now()-60m` in the query |
| `expires` | 7 | Not needed. The problem closes when no rows are returned. |
| `NUMBER_OF_RESULTS > 0`, `ONCE` | Alert when anything is found | Detector default |
| `throttle_suppress_for` | 60 minutes | `alertIdentityFields = aws.log_group` keeps one open problem |
| `DYNATRACE_PROBLEM` | `MEDIUM` | `alert.severity = "medium"` |
| `SEND_EMAIL` | 3 recipients, priority Normal | Workflow (recipients not copied) |

### Behaviour difference to know

The old alert checked once an hour. The detector checks every minute, so an error opens a problem within about a minute instead of up to an hour later. The problem stays open while the error line is inside the 60-minute window, and closes about an hour after the last error.

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "hpm_cmx_to_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
  description = "To check Lambda error: failure error of transferring files from CMX to SharePoint."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter contains(aws.log_group, "/aws/lambda/cmx-sharepoint-api")
          | filter contains(content, "Error", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "Lambda cmx-sharepoint-api logged an error while transferring files from CMX to SharePoint. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "HPM"
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

### Before you apply

| Step | Why |
|---|---|
| Run query 1 in the check file | Confirms the exact `aws.log_group` value. |
| Run query 2 | Shows what "Error" matches. Case-insensitive matching can also catch harmless lines such as `errorCount=0`. |
| Set up email in the workflow | A detector does not send email itself. |
| Run `terraform validate` and `terraform plan` from `3.sh` | Checks the file before apply. |

## Data flow map

```
Lambda cmx-sharepoint-api fails a CMX → SharePoint transfer
  → CloudWatch Logs line containing "Error"
  → Dynatrace Grail logs
  → Records detector, every minute, last 60 minutes
      lines found → problem (medium), one per log group
      no lines    → problem closes
  → workflow: pagerduty.enabled = "0" → no page, email only
```

## Related files

| File | What it is |
|---|---|
| `3-hpm-cmx-sharepoint-lambda-error-tf.tf` | Converted Terraform |
| `3-hpm-cmx-sharepoint-lambda-error-tf-check.dql` | Log group and noise check queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `3.sh` | Commands |

## Commands

All commands are in [`3.sh`](3.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/3-hpm-cmx-sharepoint-lambda-error-tf"
terraform init
terraform validate
terraform plan
```
