# Compass BigData Glue Skip Detector

## Decision tree

```
compass-sales-performance.tf ("dynatrace_log_alert")
 resource type not in provider → rewrite as dynatrace_davis_anomaly_detectors
 query → keep both filters; add from:now()-5m (old LAST_5_MINUTES)
 cron every 5 minutes, expires 2400 → detector runs every minute; problem closes on its own
 no throttle → identity field aws.log_group keeps one open problem
 only action is email (Normal) → alert.severity = "medium"; email in workflow
 no PagerDuty → pagerduty.enabled = "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The `dynatrace_log_alert` resource became a Records detector. |
| Query | The same two filters, plus `from:now()-5m`. No `summarize`. |
| Severity | Medium. The only action was a Normal-priority email. |
| PagerDuty | Off (`"0"`). |
| Email | Set it up in the workflow. Recipients were not copied. |

## Summary

This is the same conversion as answers 2 and 3. A Glue job writing "skipping table" to its error log group opens one medium problem, which closes about 5 minutes after the last matching line.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| AWS Glue job | A managed ETL job that moves data between stores. | `compass-sales-performance` feeds the BigData side. |
| "skipping table" | The job skipped a table instead of loading it. | Data for that table is missing downstream. |
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces the scheduled alert. |

### Old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Prod_Life_Compass_BigData連動Glue_Skip発生` | `title` and `event.name` |
| `description` | `"Optional"` (placeholder) | A real description |
| `search_query` | Log group and "skipping table" filters | `query.expression`, unchanged |
| `time_range` | `LAST_5_MINUTES` | `from:now()-5m` |
| `cron_expression` | `*/5 * * * *` | Not needed. The detector runs every minute. |
| `expires` | 2400 | Not needed. |
| `trigger_conditions` | Results > 0, once | Detector default |
| `throttle_enabled` | false | The identity field keeps one open problem. |
| `SEND_EMAIL` | 2 recipients, Normal, subject `Alert: $name$` | Workflow. `$name$` is Splunk syntax. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "compass_bigdata_glue_skip" {
  title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  description = "Glue job compass-sales-performance logged 'skipping table' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws-glue/jobs/custom/compass-sales-performance/error")
          | filter contains(content, "skipping table", caseSensitive:false)
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
        value = "Prod_Life_Compass_BigData連動Glue_Skip発生"
      }
      property {
        key   = "event.description"
        value = "Glue job compass-sales-performance skipped a table. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Compass"
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
| Run query 2 | Shows past "skipping table" lines. |
| Set up email in the workflow | A detector does not send email itself. |
| Run `terraform validate` and `terraform plan` from `4.sh` | Checks the file before apply. |

## Data flow map

```
Glue job compass-sales-performance skips a table
  → CloudWatch Logs /aws-glue/jobs/custom/compass-sales-performance/error
  → Dynatrace Grail logs
  → Records detector, every minute, last 5 minutes
      lines found → problem (medium)
      no lines    → problem closes
  → workflow: pagerduty.enabled = "0" → email only
```

## Related files

| File | What it is |
|---|---|
| `4-compass-bigdata-glue-skip-tf.tf` | Converted Terraform |
| `4-compass-bigdata-glue-skip-tf-check.dql` | Log group and history check queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `4.sh` | Commands |

## Commands

All commands are in [`4.sh`](4.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/4-compass-bigdata-glue-skip-tf"
terraform init
terraform validate
terraform plan
```
