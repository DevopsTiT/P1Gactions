# MyAXA Onboarding Batch Five Alerts

## Decision tree

```
myaxa-onboarding-batch.tf (5 x "dynatrace_log_alert")
 resource type not in provider → 5 x dynatrace_davis_anomaly_detectors
 email priority HIGH, no PagerDuty → severity high, pagerduty.enabled "0"
 copy-paste checks
   Alert 4 text = Alert 3 text ("email sending failed")? → yes → likely "message sending failed"
   Alert 5 text = Alert 1 text ("sendNotifications :: error")? → yes → likely "sendNotificationsQueueConsumer :: error"
   → run query 2 to see the real messages, then fix
 Alert 2 second filter redundant → dropped
 two log group checks → one is enough
 description "Optional" → real descriptions
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | All five resources became Records detectors in one file. |
| Severity | High for all, because the old emails were priority HIGH. |
| PagerDuty | Off for all. |
| Biggest issue | Alerts 4 and 5 copy the text of Alerts 3 and 1, so they send duplicate emails and never catch their own error. |
| What the file does | Keeps the filters as written. Suggested fixes are below. |

## Summary

These five alerts watch named functions in the Emma myaxa-onboarding-batch Lambda. Three are fine. Alert 4 and Alert 5 look like copies that were never edited: each searches for another alert's message. As written, they duplicate those alerts and miss the errors in their own names.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| `functionName :: message` | The log format this batch uses, for example `sendNotifications :: error`. | Each alert searches for one of these. |
| Queue consumer | Code that reads jobs from a queue and processes them, here sending notifications. | Alerts 3, 4 and 5 watch it. |
| Case-sensitive `contains` | Exact upper and lower case must match. | All five filters are case-sensitive. |
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces all five alerts. |

### The five alerts

| Alert | Title ends with | Content filter as written | Looks right? |
|---|---|---|---|
| 1 | `sendNotifications_error_High` | "sendNotifications :: error" | Yes |
| 2 | `handleOnboardedCustomers_error_High` | "handleOnboardedCustomers :: error" (plus a redundant "handleOnboardedCustomers") | Yes |
| 3 | `sendNotificationsQueueConsumer_email_sending_failed_High` | "sendNotificationsQueueConsumer :: email sending failed" | Yes |
| 4 | `sendNotificationsQueueConsumer_message_sending_failed_High` | "sendNotificationsQueueConsumer :: email sending failed" | No, same as Alert 3 |
| 5 | `sendNotificationsQueueConsumer_error_High` | "sendNotifications :: error" | No, same as Alert 1 |

Alerts 3, 4 and 5 were read from rotated photos, so confirm the exact text.

All five: every 5 minutes, last 5 minutes, expires 24, no throttle, description "Optional", email priority HIGH to 6 recipients (not copied).

### Why Alert 5 misses its own error

"sendNotifications :: error" needs a space right after "sendNotifications". In "sendNotificationsQueueConsumer :: error" the word continues with "QueueConsumer", so the text never matches. Alert 5 only fires when Alert 1 fires.

### Suggested fixes (after query 2 confirms the real messages)

| Alert | Change the content filter to |
|---|---|
| 4 | `contains(content, "sendNotificationsQueueConsumer :: message sending failed")` |
| 5 | `contains(content, "sendNotificationsQueueConsumer :: error")` |

## Result

The full file is `14-myaxa-onboarding-batch-five-alerts-tf.tf`. Every alert uses this block; only the resource name, title, description, `event.name`, `event.description` and the content filter change.

```hcl
resource "dynatrace_davis_anomaly_detectors" "emma_send_notifications_error" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotifications_error_High"
  description = "myaxa-onboarding-batch logged 'sendNotifications :: error'."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "myaxa-onboarding-batch")
          | filter contains(content, "sendNotifications :: error")
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
        value = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotifications_error_High"
      }
      property {
        key   = "event.description"
        value = "sendNotifications failed in myaxa-onboarding-batch. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Emma myaxa-onboarding-batch"
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

| Alert | Resource name | Content filter in the file |
|---|---|---|
| 1 | `emma_send_notifications_error` | "sendNotifications :: error" |
| 2 | `emma_handle_onboarded_customers_error` | "handleOnboardedCustomers :: error" |
| 3 | `emma_queue_consumer_email_sending_failed` | "sendNotificationsQueueConsumer :: email sending failed" |
| 4 | `emma_queue_consumer_message_sending_failed` | "sendNotificationsQueueConsumer :: email sending failed" (as written) |
| 5 | `emma_queue_consumer_error` | "sendNotifications :: error" (as written) |

### Before you apply

| Step | Why |
|---|---|
| Run query 2 in the check file | Lists every `function :: message` text the batch logs, so you can pick the right text for Alerts 4 and 5. |
| Fix Alerts 4 and 5 | Otherwise they duplicate Alerts 3 and 1. |
| Run query 3 | Shows how often each alert text appeared in 30 days. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `14.sh` | Checks the file before apply. |

## Data flow map

```
myaxa-onboarding-batch Lambda logs "function :: message"
  → CloudWatch Logs
  → Dynatrace Grail logs
  → 5 Records detectors, every minute, last 5 minutes
      Alert 1 sendNotifications :: error            → problem (high)
      Alert 2 handleOnboardedCustomers :: error     → problem (high)
      Alert 3 QueueConsumer :: email sending failed → problem (high)
      Alert 4 (same text as Alert 3)                → duplicate problem
      Alert 5 (same text as Alert 1)                → duplicate problem
  → workflow: pagerduty.enabled = "0" → email to the 6 recipients
```

## Related files

| File | What it is |
|---|---|
| `14-myaxa-onboarding-batch-five-alerts-tf.tf` | All five detectors, filters as written |
| `14-myaxa-onboarding-batch-five-alerts-tf-check.dql` | Log group, real message list and per-alert hit counts |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Copy-paste findings |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `14.sh` | Commands |

## Commands

All commands are in [`14.sh`](14.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/14-myaxa-onboarding-batch-five-alerts-tf"
terraform init
terraform validate
terraform plan
```
