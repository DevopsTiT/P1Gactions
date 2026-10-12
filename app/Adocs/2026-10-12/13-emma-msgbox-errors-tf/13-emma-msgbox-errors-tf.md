# Emma MsgBox Errors Detector

## Decision tree

```
message-box-api.tf ("dynatrace_log_alert")
 resource type not in provider → dynatrace_davis_anomaly_detectors
 threshold GREATER_THAN 5 (not 0)?
   detector alerts on any row → must count first
   summarize count → filter matches > 5 → one row only when over 5
 two log group checks → one is enough
 status error or warn, not DeprecationWarning → kept as written
 DYNATRACE_PROBLEM MEDIUM → alert.severity "medium"
 no PagerDuty → pagerduty.enabled "0"
 email 3 recipients (one is a Teams channel) → workflow (not copied)
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | The `dynatrace_log_alert` resource became a Records detector. |
| Why is there a summarize this time? | The old alert fired only on more than 5 matching lines. Counting is the only way to do that. |
| Window | `from:now()-5m` (old `LAST_5_MINUTES`). |
| Severity | Medium, from the old Dynatrace problem action. |
| PagerDuty | Off (`"0"`). |

## Summary

Every alert so far used "more than 0 results", so raw rows were enough. This one uses "more than 5", so the query counts the matching lines and only returns a row when the count is above 5. The count covers all message-box-api log groups together, the same as the old alert.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Threshold | The number of results that must be passed before the alert fires. | Here it is 5, not 0. |
| `summarize matches = count()` | Counts the matching lines into one row. | Needed to compare against 5. |
| `status` | Grail log field holding the normalised level (ERROR, WARN, INFO). | What the old query filters on. |
| `scope` | A fixed text field added to the result. | Gives the detector a stable identity field. |
| DeprecationWarning | A Node.js warning about outdated code. | Excluded as noise. |

### Old field to new place

| Old field | Old value | New place |
|---|---|---|
| `alert_name` | `Prod_Life_Emma_OverallMsgBoxErrors_Normal` | `title` and `event.name` |
| `description` | Catch unexpected errors related to Emma Life MsgBox | `description`, with the threshold noted |
| Log group filter | `/aws/lambda/message-box-api` or `message-box-api` | `contains(aws.log_group, "message-box-api")` |
| Status filter | "error" or "warn", case-insensitive | Unchanged |
| Exclusion | not "DeprecationWarning" | Unchanged |
| `threshold` | 5, `GREATER_THAN` | `summarize` then `filter matches > 5` |
| `cron_expression` | `*/5 * * * *` | Not needed. The detector runs every minute. |
| `time_range` | `LAST_5_MINUTES` | `from:now()-5m` |
| `DYNATRACE_PROBLEM` | `MEDIUM` | `alert.severity = "medium"` |
| `SEND_EMAIL` | 3 recipients, one a Teams channel address | Workflow (not copied) |

### Things to know

| Point | What it means |
|---|---|
| Rolling 5 minutes | The old alert counted fixed 5-minute blocks. The detector counts the last 5 minutes every minute, so a burst that straddled two blocks (for example 3 + 3) now fires. That is usually what you want. |
| Count is across all groups | `summarize` has no `by`, so lines from every message-box-api group add up, as before. |
| Warn lines count | "warn" lines count toward the 5. If warnings are noisy, query 2 and query 3 will show it. |
| Teams channel recipient | One address is a Microsoft Teams channel email. Keep it in the workflow's email step, or use a Teams action instead. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "emma_overall_msgbox_errors" {
  title       = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
  description = "Catch unexpected errors related to Emma Life MsgBox (more than 5 error or warn lines in 5 minutes, DeprecationWarning excluded)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "message-box-api")
          | filter contains(status, "error", caseSensitive:false)
              or contains(status, "warn", caseSensitive:false)
          | filter not contains(content, "DeprecationWarning", caseSensitive:false)
          | summarize matches = count(), log_groups = collectDistinct(aws.log_group), sample = takeFirst(content)
          | filter matches > 5
          | fieldsAdd scope = "message-box-api"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 5 error or warn lines from message-box-api in 5 minutes. See matches, log_groups and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Emma Life MsgBox"
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
| Run query 1 in the check file | Lists the log groups being counted. |
| Run query 2 | Shows the real `status` values. |
| Run query 3 | Shows how many 5-minute windows went over 5 in the last week. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `13.sh` | Checks the file before apply. |

## Data flow map

```
message-box-api Lambdas log error or warn lines
  → CloudWatch Logs
  → Dynatrace Grail logs (status field)
  → Records detector, every minute, last 5 minutes
      count of matching lines > 5 → one row → problem (medium)
      count 5 or less             → no row  → no problem / problem closes
  → workflow: pagerduty.enabled = "0" → email (including the Teams channel address)
```

## Related files

| File | What it is |
|---|---|
| `13-emma-msgbox-errors-tf.tf` | Converted Terraform |
| `13-emma-msgbox-errors-tf-check.dql` | Log group, status and threshold checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Field mapping |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `13.sh` | Commands |

## Commands

All commands are in [`13.sh`](13.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/13-emma-msgbox-errors-tf"
terraform init
terraform validate
terraform plan
```
