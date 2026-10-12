# MyAXA Onboarding Batch Alerts

## Decision tree

```
myaxa-onboarding-batch.tf ("dynatrace_log_alert" x 5+)
 resource type not in provider → dynatrace_davis_anomaly_detectors
 Alerts 1-4 visible → converted
 Alert 5 (sendNotificationsQueueConsumer Error) body not in photos → need screenshot from line 182
 Alert 4 filter = Alert 3 filter? → reads "email sending failed" in both
   probably should be "message sending failed" → check query 3
 Alert 2 has two content filters → second is covered by the first → one is enough
 email priority HIGH, names "_High" → severity high
 no PagerDuty action → pagerduty.enabled "0" → confirm if these should page
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | Alerts 1 to 4 became Records detectors in one file. |
| Window | All `from:now()-5m` (old `LAST_5_MINUTES`). |
| Severity | High, from the email priority HIGH and the "_High" names. |
| PagerDuty | Off (`"0"`): the old file had email only. |
| Blockers | Alert 4 probably has a copy-paste filter, and Alert 5 was not in the photos. |

## Summary

Each alert watches the myaxa-onboarding-batch logs for one function's error marker, written as `functionName :: message`. They move across with the same filters. Two things need your input: Alert 4's filter looks copied from Alert 3, and the fifth alert's body is missing from the screenshots.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces each scheduled alert. |
| `functionName :: message` | The log style this batch uses for errors. | Every filter matches one of these markers. |
| Queue consumer | A function that reads jobs from a queue and processes them. | Alerts 3 and 4 watch its failures. |
| Case-sensitive match | Upper and lower case must match exactly. | "Email Sending Failed" would not match. |

### The four alerts

| Alert | Title (after `Prod_Life_Emma_myaxa-onboarding-batch_`) | Content filter |
|---|---|---|
| 1 | sendNotifications_error_High | `sendNotifications :: error` |
| 2 | handleOnboardedCustomers_error_High | `handleOnboardedCustomers :: error` |
| 3 | sendNotificationsQueueConsumer_email_sending_failed_High | `sendNotificationsQueueConsumer :: email sending failed` |
| 4 | sendNotificationsQueueConsumer_message_sending_failed_High | Reads as `sendNotificationsQueueConsumer :: email sending failed` |

All four: log group contains `myaxa-onboarding-batch`, every 5 minutes, last 5 minutes, expires 24, results > 0, once, no throttle, email to 6 recipients with priority HIGH (not copied).

### Problems found

| Alert | Problem | What to do |
|---|---|---|
| 4 | Its filter reads the same as Alert 3 ("email sending failed"), although its name says "message sending failed". | If query 3 finds "message sending failed" lines, change Alert 4's filter to that text. |
| 2 | Two filters: "handleOnboardedCustomers :: error" and "handleOnboardedCustomers". The second is already covered. | Kept only the first. Same result. |
| All | `description = "Optional"` placeholders. | Real descriptions written. |
| All | Two log group checks joined with `or`. | One `contains(aws.log_group, "myaxa-onboarding-batch")`. |
| All | Names end in "_High" but there is no PagerDuty action. | Confirm whether these should page. If yes, set `pagerduty.enabled = "1"`. |
| 5 | Body not visible. | Send a screenshot from line 182. |

## Result

The full file is `14-myaxa-onboarding-batch-alerts-tf.tf`. Alert 1 in full:

```hcl
resource "dynatrace_davis_anomaly_detectors" "emma_send_notifications_error" {
  title       = "Prod_Life_Emma_myaxa-onboarding-batch_sendNotifications_error_High"
  description = "myaxa-onboarding-batch logged 'sendNotifications :: error' in the last 5 minutes."
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

Alerts 2 to 4 use the same block with their own resource name, title, description and query:

| Alert | Resource name |
|---|---|
| 2 | `emma_handle_onboarded_customers_error` |
| 3 | `emma_queue_consumer_email_sending_failed` |
| 4 | `emma_queue_consumer_message_sending_failed` |

```
// Alert 2
fetch logs, from:now()-5m
| filter contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "handleOnboardedCustomers :: error")

// Alert 3
fetch logs, from:now()-5m
| filter contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: email sending failed")

// Alert 4 (as read; probably should be "message sending failed")
fetch logs, from:now()-5m
| filter contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: email sending failed")
```

Likely fix for Alert 4:

```
fetch logs, from:now()-5m
| filter contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: message sending failed")
```

### Before you apply

| Step | Why |
|---|---|
| Send a screenshot from line 182 | Alert 5 is missing. |
| Run query 3 | Decides Alert 4's real filter text. |
| Run query 2 | Lists every `:: error` and `:: failed` marker, so nothing is mistyped. |
| Decide whether these should page | Names say "_High" but there is no PagerDuty action. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `14.sh` | Checks the file before apply. |

## Data flow map

```
myaxa-onboarding-batch Lambdas log "functionName :: error/failed"
  → CloudWatch Logs
  → Dynatrace Grail logs
  → 4 Records detectors, every minute, last 5 minutes
      Alert 1 sendNotifications :: error                  → problem (high)
      Alert 2 handleOnboardedCustomers :: error           → problem (high)
      Alert 3 QueueConsumer :: email sending failed       → problem (high)
      Alert 4 QueueConsumer :: (same text as Alert 3?)    → problem (high)
  → workflow: pagerduty.enabled = "0" → email to 6 recipients
```

## Related files

| File | What it is |
|---|---|
| `14-myaxa-onboarding-batch-alerts-tf.tf` | Alerts 1 to 4 |
| `14-myaxa-onboarding-batch-alerts-tf-check.dql` | Log group, marker list and Alert 4 checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Problems found |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `14.sh` | Commands |

## Commands

All commands are in [`14.sh`](14.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/14-myaxa-onboarding-batch-alerts-tf"
terraform init
terraform validate
terraform plan
```
