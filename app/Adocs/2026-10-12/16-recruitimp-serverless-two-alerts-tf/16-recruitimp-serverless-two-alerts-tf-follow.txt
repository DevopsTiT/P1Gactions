# Recruitimp Serverless Two Alerts

## Decision tree

```
recruitimp-serverless.tf (2 x "dynatrace_log_alert")
 resource type not in provider → 2 x dynatrace_davis_anomaly_detectors
 Alert 1: AWS Serverless Error (daily 08:00, last 24 hours, level:ERROR)
   "level:ERROR" or "level:error" with caseSensitive:false → one check is enough
   detector cannot run once a day → every minute over 24 hours
   need an 08:00 digest? → scheduled workflow instead
 Alert 2: RI Monitoring Error (every 5 minutes, "ERROR" anywhere)
   broader than Alert 1 → every Alert 1 line also fires Alert 2
   "ERROR" case-insensitive → matches "error" in normal text → check query 2
 both: two log group checks → one is enough
 both: email only, no PagerDuty → medium, pagerduty.enabled "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Both resources became Records detectors in one file. |
| Alert 1 | 24-hour window, `level:ERROR` only. |
| Alert 2 | 5-minute window, "ERROR" anywhere in the line. |
| Severity | Medium for both. |
| PagerDuty | Off for both. |
| Main decision | Alert 1 was an 08:00 daily digest. As a detector it overlaps Alert 2. |

## Summary

This file has the same shape as eopt-serverless (answer 8). Alert 1 was a once-a-day summary of real error-level lines; Alert 2 is a 5-minute check for the word "error" anywhere. As detectors, any error-level line opens both problems. A scheduled workflow is the better home for the daily digest.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| `level:ERROR` | The log format this Lambda uses for its log level. | A precise signal for a real error line. |
| "ERROR" anywhere | Matches any line containing the word, in any case. | Broader and noisier than `level:ERROR`. |
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces both alerts. |
| Scheduled workflow | A workflow started by a time trigger. | Keeps an 08:00 daily email. |

### Old field to new place

| Old field | Alert 1 | Alert 2 | New place |
|---|---|---|---|
| `alert_name` | recrutimp - AWS Serverless Error | RI Monitoring Error | `title` and `event.name` |
| `description` | `"Optional"` | `"Optional"` | Real descriptions |
| Log group filter | Two `contains()` checks | Two `contains()` checks | One `contains(aws.log_group, "recruitimp-serverless")` |
| Content filter | "level:ERROR" or "level:error", case-insensitive | "ERROR", case-insensitive | Alert 1 keeps one check; Alert 2 unchanged |
| Schedule | Daily 08:00, last 24 hours | Every 5 minutes, last 5 minutes | `from:now()-24h` and `from:now()-5m` |
| `SEND_EMAIL` | 2 recipients, Normal | 1 distribution list, Normal | Workflow (not copied) |

### Things to know

| Point | What it means |
|---|---|
| Redundant OR in Alert 1 | With `caseSensitive:false`, "level:ERROR" already matches "level:error". |
| Alert 1 overlaps Alert 2 | A `level:ERROR` line contains "error", so both alerts open a problem for it. |
| Daily digest option | Build a workflow with an 08:00 schedule trigger that runs Alert 1's query and emails the result. Then delete the Alert 1 detector. |
| Alert 2 noise | "ERROR" in any case can match words inside normal messages. If query 2 shows many non-level lines, switch Alert 2 to `level:ERROR` too. |
| Spelling | Resource names keep the original "recrutimp"; the log group is "recruitimp". |

## Result

```hcl
# ALERT 1
resource "dynatrace_davis_anomaly_detectors" "recrutimp_aws_serverless_error" {
  title       = "recrutimp - AWS Serverless Error"
  description = "Lambda recruitimp-serverless logged level:ERROR in the last 24 hours."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "recruitimp-serverless")
          | filter contains(content, "level:ERROR", caseSensitive:false)
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
        value = "recrutimp - AWS Serverless Error"
      }
      property {
        key   = "event.description"
        value = "Lambda recruitimp-serverless logged level:ERROR. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "recruitimp"
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
resource "dynatrace_davis_anomaly_detectors" "recrutimp_ri_monitoring_error" {
  title       = "RI Monitoring Error"
  description = "Lambda recruitimp-serverless logged a line containing ERROR in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "recruitimp-serverless")
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
        value = "RI Monitoring Error"
      }
      property {
        key   = "event.description"
        value = "Lambda recruitimp-serverless logged an ERROR. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "recruitimp"
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
| Run query 2 | Shows how many Alert 2 matches are not real error-level lines. |
| Run query 3 | Shows samples of those extra matches. |
| Decide on Alert 1 | Keep it as a 24-hour detector, or move it to an 08:00 scheduled workflow. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `16.sh` | Checks the file before apply. |

## Data flow map

```
Lambda recruitimp-serverless writes logs
  → CloudWatch Logs
  → Dynatrace Grail logs
  → Alert 1: every minute, last 24 hours, level:ERROR
      → problem (medium), closes 24 hours after the last error
  → Alert 2: every minute, last 5 minutes, "ERROR" anywhere
      → problem (medium), closes 5 minutes after the last match
  → workflow: pagerduty.enabled = "0" → email
```

## Related files

| File | What it is |
|---|---|
| `16-recruitimp-serverless-two-alerts-tf.tf` | Both converted detectors |
| `16-recruitimp-serverless-two-alerts-tf-check.dql` | Log group and noise checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `16.sh` | Commands |

## Commands

All commands are in [`16.sh`](16.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/16-recruitimp-serverless-two-alerts-tf"
terraform init
terraform validate
terraform plan
```
