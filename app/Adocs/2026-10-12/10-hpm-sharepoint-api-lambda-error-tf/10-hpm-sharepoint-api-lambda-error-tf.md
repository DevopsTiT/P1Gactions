# HPM SharePoint API Lambda Error Detector

## Decision tree

```
hpm-sharepoint-api.tf ("dynatrace_log_alert")
 resource type not in provider → dynatrace_davis_anomaly_detectors
 query → same filters + from:now()-24h (old LAST_24_HOURS)
 daily 10:00 schedule?
   detector cannot run once a day → checks every minute over 24 hours
   need a 10:00 digest email? → scheduled workflow instead
 throttle 60 minutes → identity field keeps one problem open
 DYNATRACE_PROBLEM MEDIUM → alert.severity "medium"
 no PagerDuty → pagerduty.enabled "0"
 "ERROR" case-insensitive → may match normal text → check query 2
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The `dynatrace_log_alert` resource became a Records detector. |
| Query | Same filters with `from:now()-24h`. No `summarize`. |
| Severity | Medium, from the old Dynatrace problem action. |
| PagerDuty | Off (`"0"`). |
| Behaviour change | No longer a 10:00 daily check. It alerts within a minute of an error. |

## Summary

This is the S3-and-SharePoint sibling of the CMX-to-SharePoint alert (answer 3), but on a daily 10:00 schedule over 24 hours. The query moves over unchanged. A detector cannot keep the daily schedule, so it becomes a near-real-time alert whose problem stays open for a day after the last error.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces the scheduled alert. |
| `alertIdentityFields` | Fields that decide which rows belong to one problem. | Replaces the 60-minute throttle. |
| Scheduled workflow | A workflow started by a time trigger, such as 10:00 daily. | The way to keep a once-a-day email. |

### Old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Prod_Life_HPM_SharepointAPILambdaError_Normal` | `title` and `event.name` |
| `description` | Lambda error transferring files S3 to SharePoint and SharePoint to S3 | `description` (the "Lamda" typo is fixed) |
| `search_query` | Log group and "ERROR" filters | `query.expression`, unchanged |
| `cron_expression` | `0 10 * * *` (daily 10:00) | Not possible in a detector |
| `time_range` | `LAST_24_HOURS` | `from:now()-24h` |
| `expires` | 7 | Not needed |
| `trigger_conditions` | Results > 0, once | Detector default |
| `throttle_suppress_for` | 60 minutes | Identity field keeps one open problem |
| `DYNATRACE_PROBLEM` | `MEDIUM` | `alert.severity = "medium"` |
| `SEND_EMAIL` | 3 recipients, Normal | Workflow (recipients not copied) |

### Things to know

| Point | What it means |
|---|---|
| Daily schedule is lost | The problem opens soon after the first error and closes 24 hours after the last. If the team wants one email at 10:00, build a workflow with a 10:00 schedule trigger that runs this query, and drop the detector. |
| "ERROR" ignores case | It also matches "error" inside ordinary text. Query 2 compares upper-case "ERROR" lines with all matches. |
| Window choice | If you prefer near-real-time with a short memory, change the window to `from:now()-60m`, matching answer 3. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "hpm_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
  description = "To check Lambda error: failure error of transferring files from S3 to SharePoint and SharePoint to S3."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "/aws/lambda/hpm-sharepoint-api")
          | filter contains(content, "ERROR", caseSensitive:false)
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
        value = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda hpm-sharepoint-api logged an error while transferring files between S3 and SharePoint. See the matching log lines (content) on the problem."
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
| Run query 2 | Shows how much of the "ERROR" match is noise. |
| Run query 3 | Shows errors per day, so you know how often it would fire. |
| Decide: detector or 10:00 workflow | The daily schedule cannot be kept in a detector. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `10.sh` | Checks the file before apply. |

## Data flow map

```
Lambda hpm-sharepoint-api fails an S3 ↔ SharePoint transfer
  → CloudWatch Logs line containing "ERROR"
  → Dynatrace Grail logs
  → Records detector, every minute, last 24 hours
      lines found → problem (medium)
      no lines    → problem closes 24 hours after the last error
  → workflow: pagerduty.enabled = "0" → email only
```

## Related files

| File | What it is |
|---|---|
| `10-hpm-sharepoint-api-lambda-error-tf.tf` | Converted Terraform |
| `10-hpm-sharepoint-api-lambda-error-tf-check.dql` | Log group, noise and per-day checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `10.sh` | Commands |

## Commands

All commands are in [`10.sh`](10.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/10-hpm-sharepoint-api-lambda-error-tf"
terraform init
terraform validate
terraform plan
```
