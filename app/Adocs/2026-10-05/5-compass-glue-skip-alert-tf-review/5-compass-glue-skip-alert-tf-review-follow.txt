# Compass Glue Skip Alert Terraform Review

## Decision tree

```
Is this "dynatrace_log_alert" pattern OK to copy?
 resource type exists in dynatrace-oss provider?    → NO, dynatrace_log_alert does not exist → plan fails
 fields (alert_type, cron_expression, trigger_*)?   → Splunk saved-search fields, not Dynatrace
 DQL part OK?
   aws.log_group filter                              → OK (field set by AWS log forwarding); prefer == for exact group
   contains(content, "skipping table")               → OK
   sort + limit 100                                  → fine for a Notebook, wrong for an alert (needs a timeseries)
 What to use instead?
   count over 5 minutes (same as schedule)?          → dynatrace_davis_anomaly_detectors (Option A)
   alert on every matching line, API token only?     → dynatrace_log_events (Option B)
 Email to yuta.inoue and shihao.he?                  → workflow email task or problem email notification, not in the alert resource
```

## Short takeaway

| Question | Answer |
|---|---|
| Can you copy this file as is? | No. `terraform plan` will error: the provider has no `dynatrace_log_alert` resource |
| Where did the fields come from? | Splunk saved-search settings translated word for word |
| What is reusable? | The DQL filters on `aws.log_group` and `content` |
| What to use | `dynatrace_davis_anomaly_detectors` (count-based) or `dynatrace_log_events` (per line) |
| Email | Configure separately (workflow or email notification) |

## Summary

The file looks right but it isn't a real Dynatrace resource. `dynatrace_log_alert`, `alert_type`, `cron_expression`, `trigger_conditions`, `throttle_enabled`, `trigger_actions` and `$name$` all come from Splunk's alert screen. The Dynatrace provider will reject it. The DQL inside is a good starting point; wrap it in a real resource and change the end of the query from `sort`/`limit` to a per-minute count.

## Line by line review

| Line in your file | OK? | Why | Dynatrace equivalent |
|---|---|---|---|
| `resource "dynatrace_log_alert"` | No | Not in the provider (checked the provider docs) | `dynatrace_davis_anomaly_detectors` or `dynatrace_log_events` |
| `enabled = true` | Yes | Both real resources have it | `enabled` |
| `alert_name` | No | Not a field | `title` and `event.name` property |
| `description = "Optional"` | Partly | Field exists but the value is a placeholder | Write a real description |
| `filter contains(aws.log_group, "...")` | Yes, could be better | `aws.log_group` comes from AWS CloudWatch log forwarding; `contains` also matches other groups with the same text | `aws.log_group == "/aws-glue/jobs/custom/compass-sales-performance"` |
| `filter contains(content, "skipping table")` | Yes | Same in both | Keep |
| `sort timestamp desc` and `limit 100` | No for alerts | An alert needs a number per minute, not a list of lines | `makeTimeseries count = count(default: 0), interval:1m` |
| `alert_type = "SCHEDULED"` | No | Dynatrace evaluates every minute automatically | Remove |
| `schedule_type`, `cron_expression = "*/5 * * * *"` | No | Same reason | `slidingWindow = 5` |
| `time_range = "LAST_5_MINUTES"` | No | Same reason | `slidingWindow = 5` |
| `expires = 2400` | No | Splunk triggered-alert retention | Remove |
| `trigger_conditions` NUMBER_OF_RESULTS GREATER_THAN 0 | No as written | Not a field | `threshold = "0"`, `alertCondition = "ABOVE"` |
| `trigger_mode = "ONCE"` | No | Not a field | `violatingSamples = "1"` |
| `throttle_enabled = false` | No | Dynatrace keeps one problem open, so no throttle needed | Remove |
| `trigger_actions` SEND_EMAIL with recipients | No | Alerts don't send email themselves | Workflow email task or problem email notification |
| `priority = "NORMAL"` | No | Not a field | Event property `alert.priority` if your workflow uses it |
| `subject = "Alert: $name$"` | No | `$name$` is a Splunk token | Workflow email subject using `{{ event()["event.name"] }}` |

## Fixed version (Option A, count over 5 minutes)

Full file: `5-compass-glue-skip-alert-tf-review-main.tf`.

```hcl
resource "dynatrace_davis_anomaly_detectors" "compass_bigdata_glue_skip" {
  title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  description = "Glue job compass-sales-performance logged 'skipping table' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws-glue/jobs/custom/compass-sales-performance"
          | filter contains(content, "skipping table")
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
        value = "Prod_Life_Compass_BigData連動Glue_Skip発生"
      }
      property {
        key   = "event.description"
        value = "Glue job compass-sales-performance logged 'skipping table'. Log group /aws-glue/jobs/custom/compass-sales-performance."
      }
    }
  }

  execution_settings {}
}
```

| Your old setting | New setting |
|---|---|
| Every 5 minutes, last 5 minutes | `slidingWindow = 5` |
| More than 0 results | `threshold = 0`, `ABOVE` |
| Once | `violatingSamples = 1` |
| (none) | `dealertingSamples = 5`, closes after 5 quiet minutes |

## Option B — one event per line

`dynatrace_log_events` raises an event for every matching log line. It is simpler and works with a classic API token (`settings.read`, `settings.write`). It is in the same `.tf` file, set to `enabled = false` so you don't deploy both by accident.

```hcl
resource "dynatrace_log_events" "compass_bigdata_glue_skip_line" {
  enabled = false
  summary = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  query   = "matchesValue(aws.log_group, \"/aws-glue/jobs/custom/compass-sales-performance\") and matchesPhrase(content, \"skipping table\")"

  event_template {
    title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
    description = "{content}"
    event_type  = "CUSTOM_ALERT"
  }
}
```

| Pick | When |
|---|---|
| Option A | You want the same "check last 5 minutes" behaviour and you have a platform token |
| Option B | Any single "skipping table" line should alert, and you only have a classic API token |

## Email to the two recipients

Neither resource sends email. Choose one:

| Way | What it means |
|---|---|
| Workflow with an email task | Trigger on problems whose title is `Prod_Life_Compass_BigData連動Glue_Skip発生`, send to yuta.inoue@axa.co.jp and shihao.he@axa.co.jp |
| Problem email notification | An alerting profile that matches this custom alert title, plus an email notification pointing at that profile |

If your `dynatrace-terraform/applications` repo already has one of these patterns, reuse it for this alert.

## Data flow

```
AWS Glue job compass-sales-performance
  → CloudWatch log group /aws-glue/jobs/custom/compass-sales-performance
  → Dynatrace AWS log forwarding (sets aws.log_group)
  → Grail logs
  → Option A: detector counts "skipping table" per minute, window 5
    Option B: log event rule matches each line
  → Davis event CUSTOM_ALERT "Prod_Life_Compass_BigData連動Glue_Skip発生"
  → Problem → workflow or email notification → yuta.inoue, shihao.he
```

## Investigation

| Checked | Finding |
|---|---|
| Provider docs for `log_alert` | Page does not exist (404); no such resource |
| Provider docs for `davis_anomaly_detectors` | Exists; static threshold with string input fields |
| Provider docs for `log_events` | Exists; matcher `query`, `event_template` with title, description, event_type |
| Your DQL | Filters are fine; the ending must be a timeseries for Option A |

## Result

Don't copy the `dynatrace_log_alert` pattern; it is Splunk settings in Terraform syntax and won't plan. Reuse the DQL filters, put them in `dynatrace_davis_anomaly_detectors` (or `dynatrace_log_events`), and set up email separately. Run `terraform validate` and `plan` before merging.

## Related files

| File | Purpose |
|---|---|
| `5-compass-glue-skip-alert-tf-review-main.tf` | Fixed Option A and Option B |
| `5.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/4-cisco-vpn-ldap-alert-terraform/` | Same pattern for the Cisco VPN alert |

## Commands

See `5.sh` (not run).
