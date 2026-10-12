# CSDDM Two Alerts Detectors

## Decision tree

```
cs-digital-document-management.tf (2 x "dynatrace_log_alert")
 resource type not in provider → 2 x dynatrace_davis_anomaly_detectors
 Alert 1: Claims API fails (daily 10:00, last 24 hours)
   detector cannot run once a day → checks every minute over 24 hours
   problem opens soon after the error, closes 24 hours after the last one
   need a 10:00 daily email instead? → use a scheduled workflow, not a detector
   two log group checks → one is enough
 Alert 2: CSDDM Error alerts (every 5 minutes, throttle 1 hour)
   sort and limit 100 → removed (detector only needs rows)
   "error" is case-sensitive → "Error" and "ERROR" missed → check query 2
   throttle 1 hour → identity field keeps one open problem while errors continue
 both: email only (Normal) → medium; pagerduty.enabled "0"; recipients not copied
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Both resources became Records detectors in one file. |
| Alert 1 query | Same filters with `from:now()-24h`. The log group check is shortened to one `contains()`. |
| Alert 2 query | Same filters with `from:now()-5m`. The `sort` and `limit` were removed. |
| Severity | Medium for both, because each only sent a Normal-priority email. |
| PagerDuty | Off (`"0"`) for both. |
| Biggest behaviour change | Alert 1 is no longer a daily 10:00 email. It alerts within a minute of an error. |

## Summary

Both alerts move over almost unchanged. Alert 1 was a daily report-style check; a detector cannot keep that schedule, so it becomes a near-real-time alert with a 24-hour window. Alert 2 keeps its original case-sensitive "error" match, which may miss "Error" lines; the check queries show whether that matters.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces both scheduled alerts. |
| `alertIdentityFields` | Fields that decide which rows belong to one problem. | Replaces alert 2's 1-hour throttle. |
| Case-sensitive match | "error" matches only lower case. | Alert 2 misses "Error" and "ERROR". |
| Scheduled workflow | A Dynatrace workflow started by a time trigger, such as 10:00 daily. | The way to keep a once-a-day report. |

### Alert 1: old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `[CSDDM] Send alert email when Claims API fails` | `title` and `event.name` |
| `description` | `"Optional"` (placeholder) | A real description |
| Log group filter | `/aws/lambda/cs-digital-document-management` or `cs-digital-document-management` | `contains(aws.log_group, "cs-digital-document-management")` |
| Content filters | "error", not "elivery not possible", not "errorEmailNotification", all case-insensitive | Unchanged |
| `cron_expression` | `0 10 * * *` (daily 10:00) | Not possible in a detector. See the note below. |
| `time_range` | `LAST_24_HOURS` | `from:now()-24h` |
| `expires` | 24 | Not needed |
| `SEND_EMAIL` | 4 recipients, Normal | Workflow (recipients not copied) |

### Alert 2: old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `CS Digital Document Management Error alerts` | `title` and `event.name` |
| `description` | Alerts when an error occurs. Github Repo: cs-digital-document-management | Unchanged |
| Log group filter | `/aws/lambda/cs-digital-document-management-prod` | Unchanged |
| Content filters | "error", not "elivery not possible" (case-sensitive) | Unchanged |
| `sort timestamp desc` and `limit 100` | Ordering and row cap | Removed |
| `cron_expression` | `*/5 * * * *` | Not needed. The detector runs every minute. |
| `time_range` | `LAST_5_MINUTES` | `from:now()-5m` |
| `throttle_suppress_for` | 1 hour | Identity field keeps one open problem |
| `SEND_EMAIL` | 1 recipient, Normal | Workflow (recipient not copied) |

### Things to know

| Point | What it means |
|---|---|
| Alert 1 is no longer daily | It opens a problem soon after the first error and stays open until 24 hours after the last one. If the team wants a 10:00 summary email, build a workflow with a 10:00 schedule trigger that runs the same query. |
| Alert 1 also covers the -prod group | Its log group check matches every group with "cs-digital-document-management" in the name, so one error can open a problem in both alerts. |
| Alert 2 throttle | The old alert stayed silent for 1 hour after firing. The detector closes 5 minutes after the last error and can reopen on the next one. If that is too noisy, widen alert 2's window to `from:now()-60m`. |
| Alert 2 case sensitivity | The original had no `caseSensitive:false`, so only lower-case "error" matches. Query 2 shows what is missed. Add `caseSensitive:false` if you want those lines too. |
| "elivery not possible" | Probably written that way on purpose, so it matches both "Delivery" and "delivery". Kept as is. |

## Result

```hcl
# ALERT 1
resource "dynatrace_davis_anomaly_detectors" "csddm_claims_api_fails" {
  title       = "[CSDDM] Send alert email when Claims API fails"
  description = "Lambda cs-digital-document-management logged an error in the last 24 hours (delivery-not-possible and errorEmailNotification lines excluded)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "cs-digital-document-management")
          | filter contains(content, "error", caseSensitive:false)
          | filter not contains(content, "elivery not possible", caseSensitive:false)
          | filter not contains(content, "errorEmailNotification", caseSensitive:false)
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
        value = "[CSDDM] Send alert email when Claims API fails"
      }
      property {
        key   = "event.description"
        value = "Claims API (cs-digital-document-management) logged an error. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "CSDDM"
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
resource "dynatrace_davis_anomaly_detectors" "cs_digital_document_management_error" {
  title       = "CS Digital Document Management Error alerts"
  description = "Alerts when an error occurs. Github Repo: cs-digital-document-management"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/cs-digital-document-management-prod")
          | filter contains(content, "error")
          | filter not contains(content, "elivery not possible")
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
        value = "CS Digital Document Management Error alerts"
      }
      property {
        key   = "event.description"
        value = "Lambda cs-digital-document-management-prod logged an error. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "CSDDM"
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
| Run query 1 in the check file | Shows every log group alert 1 will watch. |
| Run query 2 | Shows "Error" lines that alert 2 misses because of case sensitivity. |
| Run query 3 | Shows what alert 1 would have caught in the last day. |
| Decide whether alert 1 must stay a 10:00 daily email | If yes, use a scheduled workflow instead of this detector. |
| Set up email in the workflow | A detector does not send email itself. |
| Run `terraform validate` and `terraform plan` from `5.sh` | Checks the file before apply. |

## Data flow map

```
Lambda cs-digital-document-management(-prod) logs an error
  → CloudWatch Logs
  → Dynatrace Grail logs
  → Alert 1 detector: every minute, last 24 hours, all cs-digital-document-management groups
      → problem (medium), closes 24 hours after the last error
  → Alert 2 detector: every minute, last 5 minutes, -prod group only, lower-case "error"
      → problem (medium), closes 5 minutes after the last error
  → workflow: pagerduty.enabled = "0" → email only
```

## Related files

| File | What it is |
|---|---|
| `5-csddm-two-alerts-tf.tf` | Both converted detectors |
| `5-csddm-two-alerts-tf-check.dql` | Log group, case-sensitivity and history checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `5.sh` | Commands |

## Commands

All commands are in [`5.sh`](5.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/5-csddm-two-alerts-tf"
terraform init
terraform validate
terraform plan
```
