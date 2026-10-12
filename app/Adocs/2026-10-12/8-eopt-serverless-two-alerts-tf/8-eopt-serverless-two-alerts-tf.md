# EOPT Serverless Two Alerts Detectors

## Decision tree

```
eopt-serverless.tf (2 x "dynatrace_log_alert")
 resource type not in provider → 2 x dynatrace_davis_anomaly_detectors
 Alert 1: E-Tool Error Lambda (every 5 minutes, last 5 minutes)
   "filtered fields" → fields timestamp, loglevel, content (+ aws.log_group)
 Alert 2: eopt - AWS Serverless Error (daily 10:00, last 24 hours)
   same filter as Alert 1 → one error opens both problems
   need a 10:00 daily email? → scheduled workflow, not a detector
 both: two log group checks → one is enough
 both: "ERROR" case-insensitive → matches "error" anywhere → check query 2
 both: email only, no PagerDuty → medium, pagerduty.enabled "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Both resources became Records detectors in one file. |
| Alert 1 | 5-minute window, keeps only timestamp, loglevel and content. |
| Alert 2 | 24-hour window, all fields. Same filter as Alert 1. |
| Severity | Medium for both. |
| PagerDuty | Off for both. |
| Main decision | Alert 2 was a daily 10:00 digest. As a detector it duplicates Alert 1. |

## Summary

Both alerts look for "ERROR" in the eopt-serverless Lambda logs. Alert 1 is the near-real-time one; Alert 2 was a once-a-day summary with all fields. A detector cannot keep the daily schedule, so Alert 2 ends up as a second, longer copy of Alert 1. A scheduled workflow is the better home for the daily digest.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces both scheduled alerts. |
| `fields` | DQL command that keeps only the listed columns. | Matches Alert 1's "filtered output". |
| `loglevel` | Grail's field for the log level (INFO, WARN, ERROR). | The Dynatrace name for "level". |
| Scheduled workflow | A workflow started by a time trigger. | The way to keep a daily 10:00 digest. |

### Old field to new place

| Old field | Alert 1 | Alert 2 | New place |
|---|---|---|---|
| `alert_name` | E-Tool Error Lambda | eopt - AWS Serverless Error | `title` and `event.name` |
| `description` | Alert with filtered fields: timestamp, level, message | Alert with all fields for investigation | Unchanged |
| Log group filter | Two `contains()` checks | Two `contains()` checks | One `contains(aws.log_group, "eopt-serverless")` |
| Content filter | "ERROR", case-insensitive | Same | Unchanged |
| Output | Filtered fields | All fields | Alert 1 adds `fields`; Alert 2 keeps all |
| Schedule | Every 5 minutes, last 5 minutes | Daily 10:00, last 24 hours | `from:now()-5m` and `from:now()-24h` |
| `SEND_EMAIL` | 1 distribution list, Normal | 2 recipients, Normal | Workflow (not copied) |

### Things to know

| Point | What it means |
|---|---|
| Alert 2 duplicates Alert 1 | One error opens a 5-minute problem and a 24-hour problem. The 24-hour one stays open until a day after the last error. |
| Daily digest option | Build a workflow with a 10:00 schedule trigger that runs Alert 2's query and emails the result. Then delete the Alert 2 detector. |
| "ERROR" is case-insensitive | It also matches words like "error" in normal JSON or messages. Query 2 compares upper-case "ERROR" lines with all matches. If most noise is lower case, drop `caseSensitive:false` or filter on `loglevel == "ERROR"`. |
| `aws.log_group` in Alert 1's fields | The identity field must stay in the output, so it is listed with the three requested fields. |

## Result

```hcl
# ALERT 1
resource "dynatrace_davis_anomaly_detectors" "etool_error_lambda" {
  title       = "E-Tool Error Lambda"
  description = "Alert with filtered fields: timestamp, level, message"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "eopt-serverless")
          | filter contains(content, "ERROR", caseSensitive:false)
          | fields timestamp, loglevel, content, aws.log_group
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
        value = "E-Tool Error Lambda"
      }
      property {
        key   = "event.description"
        value = "Lambda eopt-serverless logged an ERROR. See timestamp, loglevel and content on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "E-Tool"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ALERT 2
resource "dynatrace_davis_anomaly_detectors" "eopt_aws_serverless_error" {
  title       = "eopt - AWS Serverless Error"
  description = "Alert with all fields for investigation"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "eopt-serverless")
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
        value = "eopt - AWS Serverless Error"
      }
      property {
        key   = "event.description"
        value = "Lambda eopt-serverless logged an ERROR in the last 24 hours. All log fields are on the problem for investigation."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "E-Tool"
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
| Run query 1 in the check file | Lists the log groups both alerts watch. |
| Run query 2 | Shows how much of the "ERROR" match is noise. |
| Decide on Alert 2 | Keep it as a 24-hour detector, or move it to a 10:00 scheduled workflow. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `8.sh` | Checks the file before apply. |

## Data flow map

```
Lambda eopt-serverless logs a line containing "ERROR"
  → CloudWatch Logs
  → Dynatrace Grail logs
  → Alert 1: every minute, last 5 minutes, fields timestamp, loglevel, content
      → problem (medium), closes 5 minutes after the last error
  → Alert 2: every minute, last 24 hours, all fields
      → problem (medium), closes 24 hours after the last error
  → workflow: pagerduty.enabled = "0" → email only
```

## Related files

| File | What it is |
|---|---|
| `8-eopt-serverless-two-alerts-tf.tf` | Both converted detectors |
| `8-eopt-serverless-two-alerts-tf-check.dql` | Log group and noise checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `8.sh` | Commands |

## Commands

All commands are in [`8.sh`](8.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/8-eopt-serverless-two-alerts-tf"
terraform init
terraform validate
terraform plan
```
