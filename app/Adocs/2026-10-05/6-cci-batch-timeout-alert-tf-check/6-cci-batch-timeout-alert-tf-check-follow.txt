# CCI Batch Timeout Alert Terraform Check

## Decision tree

```
cci-fa-comm-calc.tf uses dynatrace_log_alert
 resource exists?                        → NO → terraform plan fails (same issue as compass-sales-performance.tf)
 PagerDuty integration_key in plain text → SECURITY: remove from the file, move to a secret/variable
 DQL filters
   aws.log_group /aws/lambda/cci-fa-comm-calc → OK, use == for exact match
   contains "Task timed out"                    → OK (Lambda timeout message)
   not contains "!DEBUG!"                       → OK
   sort + limit 100                             → replace with makeTimeseries count per 1m
 schedule */5, last 6 minutes, > 0, once  → slidingWindow 5, threshold 0 ABOVE, violatingSamples 1
 PagerDuty + 6 email recipients           → workflow (PD task + email task) or problem notifications
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. Same problem as the Compass file: `dynatrace_log_alert` does not exist |
| Biggest extra risk | A PagerDuty integration key is hard-coded on line 32; don't commit it |
| What is reusable? | The three DQL filters |
| Fixed resource | `dynatrace_davis_anomaly_detectors` (or `dynatrace_log_events`) |
| PagerDuty and email | Separate: workflow or problem notification |

## Summary

This is the same Splunk-to-Terraform copy pattern, so it will fail at `terraform plan`. The query filters are good. On top of that, line 32 has a PagerDuty integration key in plain text; anyone with repo access could send pages to that service. Move it out of the file before this goes to Git.

## Line by line

| Line | Content | OK? | Fix |
|---|---|---|---|
| 1 | `resource "dynatrace_log_alert"` | No | `dynatrace_davis_anomaly_detectors` or `dynatrace_log_events` |
| 3 | `alert_name = "CCI_AWS_Batch Time Out"` | No | `title` and `event.name` |
| 4 | `description = "Optional"` | Placeholder | Real text, e.g. "CCI AWS Batch Task Timeout Alert" |
| 8 | `contains(aws.log_group, "/aws/lambda/cci-fa-comm-calc")` | OK | Prefer `aws.log_group == "/aws/lambda/cci-fa-comm-calc"` |
| 9 | `contains(content, "Task timed out")` | OK | Keep; Lambda writes "Task timed out after N seconds" |
| 10 | `not contains(content, "!DEBUG!")` | OK | Keep |
| 11–12 | `sort timestamp desc`, `limit 100` | Not for alerts | `makeTimeseries count = count(default: 0), interval:1m` |
| 15–19 | alert_type, schedule_type, cron `*/5`, LAST_6_MINUTES, expires | No | `slidingWindow = 5` (Dynatrace runs every minute; the extra 1-minute overlap Splunk needed is not required) |
| 21–26 | NUMBER_OF_RESULTS GREATER_THAN 0, ONCE | No | `threshold = 0`, `ABOVE`, `violatingSamples = 1` |
| 28 | `throttle_enabled = false` | No | Remove; one problem stays open |
| 30–34 | PagerDuty action with `integration_key` | No, and a secret leak | PagerDuty task in the workflow, key stored as a secret |
| 36–48 | SEND_EMAIL to 6 recipients, priority, `$name$` | No | Email task in the workflow |

## The PagerDuty key

| Point | What it means |
|---|---|
| What it is | The routing key for one PagerDuty service; with it anyone can trigger pages |
| Why it matters | Committed to Git, it stays in history even after you delete the line |
| What to do now | Remove it from the file before committing |
| If it was already pushed | Ask the PagerDuty admin to rotate the integration key |
| Where it should live | A Dynatrace workflow secret / credential vault entry, or a Terraform variable marked `sensitive = true` fed from CI secrets |

## Fixed version

Full file: `6-cci-batch-timeout-alert-tf-check-main.tf`.

```hcl
resource "dynatrace_davis_anomaly_detectors" "cci_aws_batch_timeout" {
  title       = "CCI_AWS_Batch Time Out"
  description = "Lambda cci-fa-comm-calc logged 'Task timed out' in the last 5 minutes. CCI AWS Batch Task Timeout Alert."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cci-fa-comm-calc"
          | filter contains(content, "Task timed out")
          | filter not contains(content, "!DEBUG!")
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
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
        value = "CCI_AWS_Batch Time Out"
      }
      property {
        key   = "event.description"
        value = "CCI AWS Batch Task Timeout Alert. Lambda /aws/lambda/cci-fa-comm-calc logged 'Task timed out'."
      }
    }
  }

  execution_settings {}
}
```

Option B (`dynatrace_log_events`, one event per line) is also in the file, set to `enabled = false`.

## PagerDuty and email

| Old action | Dynatrace way |
|---|---|
| PagerDuty with custom description "CCI AWS Batch Task Timeout Alert" | Workflow triggered on problems titled `CCI_AWS_Batch Time Out`, with a PagerDuty Events v2 task using the key from a secret |
| Email to aij_jp_dl_aog_to, maiko.ogawa, hiroshi.takamori, jun.okazaki, satoshi.koyama, kyosuke.takahashi | Email task in the same workflow, or a problem email notification on an alerting profile matching this title |

Recipients from the screenshot (check spelling against the original, the photo is small):

| Recipient |
|---|
| aij_jp_dl_aog_to@axa.co.jp |
| maiko.ogawa@axa.co.jp |
| hiroshi.takamori@axa.co.jp |
| jun.okazaki@axa.co.jp |
| satoshi.koyama@axa.co.jp |
| kyosuke.takahashi@axa.co.jp |

## Check the query before apply

```dql
fetch logs, from:-7d
| filter aws.log_group == "/aws/lambda/cci-fa-comm-calc"
| filter contains(content, "Task timed out")
| filter not contains(content, "!DEBUG!")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 20
```

If this returns nothing but CloudWatch shows timeouts, the Lambda log group may not be forwarded to Dynatrace yet.

## Data flow

```
Lambda cci-fa-comm-calc runs too long
  → Lambda writes "Task timed out after N seconds" to /aws/lambda/cci-fa-comm-calc
  → Dynatrace AWS log forwarding (aws.log_group)
  → Grail logs
  → detector: count per minute, DEBUG excluded, window 5, > 0
  → Davis event CUSTOM_ALERT "CCI_AWS_Batch Time Out"
  → Problem → workflow → PagerDuty (key from secret) + email to 6 recipients
  → 5 quiet minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot `cci-fa-comm-calc.tf` | Same `dynatrace_log_alert` pattern as `compass-sales-performance.tf` |
| Provider docs | `dynatrace_log_alert` does not exist; `dynatrace_davis_anomaly_detectors` and `dynatrace_log_events` do |
| Secrets | PagerDuty `integration_key` hard-coded on line 32 |
| Query | Filters valid; output must be a timeseries for the threshold alert |
| Naming | Title says "Batch" but the log group is a Lambda function; fine if intended |

## Result

Not OK as is. Replace the resource with `dynatrace_davis_anomaly_detectors`, keep the three filters, drop the Splunk-only fields, move PagerDuty and email into a workflow, and remove the PagerDuty key from the file (rotate it if it was already pushed).

## Related files

| File | Purpose |
|---|---|
| `6-cci-batch-timeout-alert-tf-check-main.tf` | Fixed resource (Option A on, Option B off) |
| `6.sh` | Validate, plan, secret search, mirror and git one-liners |
| `2026-10-05/5-compass-glue-skip-alert-tf-review/` | Same review for the Compass file |

## Commands

See `6.sh` (not run).
