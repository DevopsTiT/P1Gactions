# Customer Process API Two Alerts Detectors

## Decision tree

```
customer-process-api.tf (2 x "dynatrace_log_alert")
 resource type not in provider → 2 x dynatrace_davis_anomaly_detectors
 Alert 1: Success Request Monitoring (statusCode 201)
   success notice, not an error → severity low
   two log group checks → one is enough
   two statusCode checks → kept as written (escaped and plain forms)
 Alert 2: Customer Process API Alerts (9 known error messages)
   all OR-ed, case-insensitive → kept as written
   "IBL0250002" read from photo → confirm the exact code
 both: every 5 minutes, last 5 minutes, no throttle → detector every minute over 5 minutes
 both: email only, no PagerDuty → pagerduty.enabled "0"; recipients not copied
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Both resources became Records detectors in one file. |
| Alert 1 | Same 201 filter, 5-minute window, severity low because it reports success. |
| Alert 2 | Same 9 error messages, 5-minute window, severity medium. |
| PagerDuty | Off (`"0"`) for both. |
| Email | Set it up in the workflow. Recipients were not copied. |

## Summary

Both alerts move across with the same filters and the old 5-minute window. Alert 1 is really a business notification ("a production contract request was created"), so it gets low severity. Alert 2 is a list of known error messages and gets medium, like the other email-only alerts.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| statusCode 201 | HTTP "Created". The request made something new, here a contract request. | Alert 1 fires on success, not failure. |
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces both scheduled alerts. |
| `alertIdentityFields` | Fields that decide which rows belong to one problem. | Several 201s or errors in 5 minutes give one problem, not many. |
| `caseSensitive:false` | Match regardless of upper or lower case. | Used on all of Alert 2's messages. |

### Alert 1: old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Customer Process API Success Request Monitoring` | `title` |
| `description` | To immediately understand the actual production contract requested and confirm operations. | Unchanged |
| Log group filter | `/aws/lambda/customer-process-api` or `customer-process-api` | `contains(aws.log_group, "customer-process-api")` |
| Content filter | `"statusCode":201` or `statusCode":201` | Unchanged |
| Schedule | Every 5 minutes, last 5 minutes, expires 24 | Detector every minute, `from:now()-5m` |
| Subject | `\|\|PROD\|\| Alert: $name$` | `event.name` starts with `\|\|PROD\|\|` |
| `SEND_EMAIL` | 4 recipients, Normal | Workflow (recipients not copied) |

### Alert 2: the nine messages

| Message | What it likely means |
|---|---|
| Task timed out | The Lambda hit its timeout. |
| An error occurred | A generic error, often from an AWS SDK call. |
| Failed to handle: lifeJData | The handler could not process the lifeJData payload. |
| Got unexpected investment company code | Input data had a company code the code does not know. |
| The policy is ineligible for creating a request | Business rule rejected the request. |
| IBL0250002 | An application or backend message code (read from the photo; confirm). |
| `<StatusCd>EB` | An XML response with status code EB, an error from a backend system. |
| imported a total of 0 data | A batch import found nothing to import. |
| Handler Error: Too many connections | The database ran out of connections. |

### Alert 2: other fields

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Customer Process API Alerts` | `title` |
| `description` | `"Optional"` (placeholder) | A real description |
| Schedule | Every 5 minutes, last 5 minutes, expires 24 | Detector every minute, `from:now()-5m` |
| `SEND_EMAIL` | 1 distribution list, Normal | Workflow (not copied) |

### Things to know

| Point | What it means |
|---|---|
| Alert 1 is a success notice | A Dynatrace "problem" for a successful request is unusual. Low severity keeps it out of error dashboards. If the team only wants the email, a workflow with a schedule trigger is a cleaner fit. |
| The two statusCode checks | The second is a shorter form of the first, so it already covers it. They were kept as written because the log may hold escaped JSON. Query 2 shows the real format. |
| One problem per log group | If 10 contracts arrive within 5 minutes, you get one problem, not 10 emails. The matching lines are all on the problem. |

## Result

```hcl
# ALERT 1
resource "dynatrace_davis_anomaly_detectors" "customer_process_api_success_monitoring" {
  title       = "Customer Process API Success Request Monitoring"
  description = "To immediately understand the actual production contract requested and confirm operations."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "customer-process-api")
          | filter contains(content, "\"statusCode\":201") or contains(content, "statusCode\":201")
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
        value = "||PROD|| Customer Process API Success Request Monitoring"
      }
      property {
        key   = "event.description"
        value = "Customer Process API returned statusCode 201 (production contract request created). See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "Customer Process API"
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
resource "dynatrace_davis_anomaly_detectors" "customer_process_api_alerts" {
  title       = "Customer Process API Alerts"
  description = "Lambda customer-process-api logged a known error message (timeout, handler failure, ineligible policy, zero import, too many connections and others)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "customer-process-api")
          | filter contains(content, "Task timed out", caseSensitive:false)
              or contains(content, "An error occurred", caseSensitive:false)
              or contains(content, "Failed to handle: lifeJData", caseSensitive:false)
              or contains(content, "Got unexpected investment company code", caseSensitive:false)
              or contains(content, "The policy is ineligible for creating a request", caseSensitive:false)
              or contains(content, "IBL0250002", caseSensitive:false)
              or contains(content, "<StatusCd>EB", caseSensitive:false)
              or contains(content, "imported a total of 0 data", caseSensitive:false)
              or contains(content, "Handler Error: Too many connections", caseSensitive:false)
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
        value = "||PROD|| Customer Process API Alerts"
      }
      property {
        key   = "event.description"
        value = "Customer Process API logged a known error message. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Customer Process API"
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
| Run query 1 in the check file | Shows which log groups both alerts watch. |
| Run query 2 | Shows how statusCode 201 really appears in the log text. |
| Run query 3 | Shows which of the nine messages fired in the last 7 days. |
| Confirm the code `IBL0250002` | It was read from a photo. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `6.sh` | Checks the file before apply. |

## Data flow map

```
Lambda customer-process-api writes logs
  → CloudWatch Logs
  → Dynatrace Grail logs
  → Alert 1 detector: every minute, last 5 minutes, statusCode 201
      → problem (low) "contract request created"
  → Alert 2 detector: every minute, last 5 minutes, 9 known error messages
      → problem (medium)
  → workflow: pagerduty.enabled = "0" → email only
```

## Related files

| File | What it is |
|---|---|
| `6-customer-process-api-two-alerts-tf.tf` | Both converted detectors |
| `6-customer-process-api-two-alerts-tf-check.dql` | Log group, 201 format and message-hit checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `6.sh` | Commands |

## Commands

All commands are in [`6.sh`](6.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/6-customer-process-api-two-alerts-tf"
terraform init
terraform validate
terraform plan
```
