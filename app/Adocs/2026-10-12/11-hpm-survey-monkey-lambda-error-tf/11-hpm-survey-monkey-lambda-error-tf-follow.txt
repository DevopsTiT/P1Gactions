# HPM SurveyMonkey Lambda Error Detector

## Decision tree

```
hpm-survey-monkey.tf ("dynatrace_log_alert")
 resource type not in provider → dynatrace_davis_anomaly_detectors
 query → same filters + from:now()-60m (old LAST_60_MINUTES)
 hourly cron + throttle 60 minutes → detector every minute; identity field keeps one problem open
 DYNATRACE_PROBLEM MEDIUM → alert.severity "medium"
 no PagerDuty → pagerduty.enabled "0"
 "ERROR" case-insensitive → may match normal text → check query 2
 email 3 recipients → workflow (not copied)
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The `dynatrace_log_alert` resource became a Records detector. |
| Query | Same filters with `from:now()-60m`. No `summarize`. |
| Severity | Medium, from the old Dynatrace problem action. |
| PagerDuty | Off (`"0"`). |
| Behaviour change | Alerts within a minute instead of at the top of the hour. |

## Summary

This is the same shape as the CMX-to-SharePoint alert (answer 3): hourly check over 60 minutes, medium, email only. The query is unchanged apart from the time window, and the description typos ("Lamda", "Survey money") are fixed.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces the hourly alert. |
| `alertIdentityFields` | Fields that decide which rows belong to one problem. | Replaces the 60-minute throttle. |
| SurveyMonkey | Online survey service. | The Lambda copies its files into S3. |

### Old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Prod_Life_HPM_SurveyMonkeyLambdaError_Normal` | `title` and `event.name` |
| `description` | "To check Lamda error, failure error of transferring files from Survey money to S3" | Same meaning, typos fixed |
| `search_query` | Log group and "ERROR" filters | `query.expression`, unchanged |
| `cron_expression` | `0 * * * *` (hourly) | Not needed. The detector runs every minute. |
| `time_range` | `LAST_60_MINUTES` | `from:now()-60m` |
| `expires` | 7 | Not needed |
| `trigger_conditions` | Results > 0, once | Detector default |
| `throttle_suppress_for` | 60 minutes | Identity field keeps one open problem |
| `DYNATRACE_PROBLEM` | `MEDIUM` | `alert.severity = "medium"` |
| `SEND_EMAIL` | 3 recipients, Normal | Workflow (recipients not copied) |

### Behaviour difference

The old alert checked at the top of each hour. The detector checks every minute, so an error opens a problem within about a minute. The problem closes about an hour after the last error.

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "hpm_survey_monkey_lambda_error" {
  title       = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
  description = "To check Lambda error: failure error of transferring files from SurveyMonkey to S3."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter contains(aws.log_group, "/aws/lambda/hpm-survey-monkey")
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
        value = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda hpm-survey-monkey logged an error while transferring files from SurveyMonkey to S3. See the matching log lines (content) on the problem."
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
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `11.sh` | Checks the file before apply. |

## Data flow map

```
Lambda hpm-survey-monkey fails a SurveyMonkey → S3 transfer
  → CloudWatch Logs line containing "ERROR"
  → Dynatrace Grail logs
  → Records detector, every minute, last 60 minutes
      lines found → problem (medium)
      no lines    → problem closes
  → workflow: pagerduty.enabled = "0" → email only
```

## Related files

| File | What it is |
|---|---|
| `11-hpm-survey-monkey-lambda-error-tf.tf` | Converted Terraform |
| `11-hpm-survey-monkey-lambda-error-tf-check.dql` | Log group and noise checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `11.sh` | Commands |

## Commands

All commands are in [`11.sh`](11.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/11-hpm-survey-monkey-lambda-error-tf"
terraform init
terraform validate
terraform plan
```
