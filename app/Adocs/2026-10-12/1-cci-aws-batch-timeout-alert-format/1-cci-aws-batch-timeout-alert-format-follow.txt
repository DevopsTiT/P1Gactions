# CCI AWS Batch Timeout Alert Format

## Decision tree

```
Is this file a valid Dynatrace alert?
 resource type "dynatrace_log_alert"?
   not in the dynatrace-oss/dynatrace provider → terraform plan fails
   fix → dynatrace_davis_anomaly_detectors (Records detector)
 search query?
   mostly valid DQL → keep the filters
   no time range inside → add fetch logs, from:now()-6m
   two contains() on the log group → one is enough
 schedule / trigger / throttle fields?
   Splunk-style settings → the detector runs every minute; "results > 0" = query returns rows
 trigger_actions PAGERDUTY with integration_key?
   secret in plain text → remove; set pagerduty.enabled = "1" and let the workflow send it
   file ever committed? → rotate the key in PagerDuty
 trigger_actions SEND_EMAIL with recipients?
   not part of a detector → workflow or notification settings
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this the correct format? | No. `dynatrace_log_alert` is not a real resource in the Dynatrace Terraform provider. |
| What happens if you apply it? | `terraform plan` stops with "does not support resource type". |
| Is the query itself OK? | Mostly. The DQL filters are fine; it only needs a time range. |
| What format should it be? | `dynatrace_davis_anomaly_detectors` (Records detector), same as the 2026-10-08 detectors. |
| Biggest risk in the file | The PagerDuty integration key is written in plain text. |

## Summary

The file looks like a Splunk saved search translated field-by-field (cron, expires, trigger mode, throttle, actions). Dynatrace does not have a resource with that shape. The search logic is good and can be moved almost as-is into a Records detector. Alerting to PagerDuty and email is done by the workflow, not inside the detector, so the key and recipients should leave this file.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Terraform provider | The plugin that knows which resource types exist (here `dynatrace-oss/dynatrace`). | A resource type the provider does not know cannot be applied. |
| Records detector | A Dynatrace detector that runs a DQL query every minute and opens a problem when rows come back. | The Dynatrace equivalent of a Splunk "results > 0" alert. |
| `alertIdentityFields` | The fields that decide "is this the same problem or a new one". | Stops a new problem being opened every minute for the same timeout. |
| Integration key | The PagerDuty secret that lets anyone create incidents on that service. | Must not live in a Terraform file in Git. |
| Lambda "Task timed out" | The line AWS Lambda writes when a function runs longer than its timeout. | This is the event the alert is looking for. |

### Line-by-line check

| Line(s) | What it says | Verdict |
|---|---|---|
| 1 | `resource "dynatrace_log_alert"` | Wrong. This resource type does not exist in the provider. |
| 4 | `description = "Optional"` | Placeholder text. Write a real description. |
| 6–11 | `fetch logs` and three filters | Valid DQL, but no time range. |
| 8 | `contains(aws.log_group, "/aws/lambda/cci-fa-comm-calc") or contains(aws.log_group, "cci-fa-comm-calc")` | The second check already covers the first. One is enough. |
| 9 | `contains(content, "Task timed out", caseSensitive: false)` | Good. Matches the Lambda timeout message. |
| 10 | `not contains(content, "[DEBUG]")` | Good. |
| 13–17 | `SCHEDULED`, `CUSTOM`, `*/5 * * * *`, `LAST_6_MINUTES`, `expires = 24` | Splunk settings. A Records detector has no cron; it runs every minute. The 6-minute window goes into the query. |
| 19–24 | `NUMBER_OF_RESULTS`, `GREATER_THAN`, `0`, `ONCE` | Same as "the query returned rows". The detector does this by default. |
| 26 | `throttle_enabled = false` | The identity field does the de-duplication instead. |
| 28–32 | PagerDuty action with `integration_key` | Secret in plain text. Remove it and use `pagerduty.enabled = "1"`. |
| 34–46 | `SEND_EMAIL`, recipient list, `priority`, `subject = "Alert: $name$"` | Not part of a detector. `$name$` is Splunk token syntax. Handle email in the workflow. |

### About the 6-minute window

The Splunk job ran every 5 minutes and looked back 6 minutes, so a 1-minute overlap stopped gaps. In Dynatrace the detector runs every minute. With `from:now()-6m`, one timeout stays in the window for about 6 runs. Because the identity field is the log group, those runs keep **one** problem open instead of opening six. It closes on its own when no new timeouts appear for 6 minutes.

## Result

Use the fixed file `1-cci-aws-batch-timeout-alert-format-fixed.tf`:

```hcl
resource "dynatrace_davis_anomaly_detectors" "cci_aws_batch_timeout" {
  title       = "CCI_AWS_Batch Time Out"
  description = "Lambda cci-fa-comm-calc logged 'Task timed out' in the last 6 minutes (DEBUG lines excluded)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-6m
          | filter contains(aws.log_group, "cci-fa-comm-calc")
          | filter contains(content, "Task timed out", caseSensitive:false)
          | filter not contains(content, "[DEBUG]")
          | summarize timeouts = count(),
                      first_seen = min(timestamp),
                      last_seen = max(timestamp),
                      sample = takeFirst(content),
                      by:{ aws.log_group }
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
        value = "CCI AWS Batch Task Timeout Alert"
      }
      property {
        key   = "event.description"
        value = "Lambda cci-fa-comm-calc timed out. See timeouts, first_seen, last_seen and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "CCI"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
```

### What maps to what

| Old field | New place |
|---|---|
| `alert_name` | `title` |
| `search_query` | `query.expression`, with `from:now()-6m` added |
| `cron_expression` and `time_range` | Detector runs every minute; window is in the query |
| `NUMBER_OF_RESULTS > 0` | Detector default: any row opens a problem |
| `trigger_mode = ONCE` and `throttle_enabled` | `alertIdentityFields` keeps it to one open problem |
| PagerDuty action | `pagerduty.enabled = "1"`; the workflow sends it |
| Email action | Workflow or notification settings (recipients not copied here) |
| `custom_description` | `event.name` |

### Before you apply

| Step | Why |
|---|---|
| Run query 1 in `1-cci-aws-batch-timeout-alert-format-check.dql` | Confirms the field is really called `aws.log_group` in your tenant. |
| Run query 2 | Shows past timeouts, so you know what a real alert would contain. |
| Remove the old file from the repo or keep it out of Git | It holds the integration key and email addresses. |
| Rotate the PagerDuty key if the old file was ever pushed or shared | Anyone with the key can create incidents. |
| If your team has its own converter that reads `dynatrace_log_alert` files | Then it is that tool's input format, not Terraform. Ask the owner which format the tool expects. |

## Data flow map

```
Lambda cci-fa-comm-calc runs too long
  → AWS writes "Task timed out after N seconds" to CloudWatch Logs
  → logs shipped to Dynatrace Grail (field aws.log_group)
  → Records detector, every minute, last 6 minutes
      rows found → problem "CCI AWS Batch Task Timeout Alert" (one per log group)
      no rows    → problem closes
  → workflow reads pagerduty.enabled = "1"
      → PagerDuty incident
      → email (configured in workflow, not in the detector)
```

## Related files

| File | What it is |
|---|---|
| `1-cci-aws-batch-timeout-alert-format-fixed.tf` | The corrected Terraform |
| `1-cci-aws-batch-timeout-alert-format-check.dql` | Queries to confirm the field name and see past timeouts |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Line-by-line check |
| `2-result.md` | Fix and before-apply steps |
| `3-glossary.md` | Terms |
| `1.sh` | Commands |

## Commands

All commands are in [`1.sh`](1.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/1-cci-aws-batch-timeout-alert-format"
terraform init
terraform validate
terraform plan
```
