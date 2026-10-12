# Sa Support Batches Three Alerts

## Decision tree

```
sa-support-batches.tf (3 fake dynatrace_log_alert blocks)
 Alert 1 "Batch Error" → filter is "Task timed out" → same as Alert 3
   real error text known? → change filter → keep both
   not known? → delete Alert 1 → Alert 3 covers timeouts
 Alert 2 "File Import Confirmation" → LESS_THAN 2 results → absence alert
   detector → summarize count() → filter matches < 2
   weekday 08:30 schedule → JST guard (Mon-Fri, 08:30-08:59)
   guard check fails? → use a scheduled workflow at 08:30 JST instead
   "started" matches too much? → drop it from the filter
 Alert 3 "Task Time Out" → 6 minutes → raw rows → problem
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the old file valid Dynatrace? | No. `dynatrace_log_alert` does not exist. |
| What replaces it? | Three `dynatrace_davis_anomaly_detectors` resources. |
| Severity | Medium for all three, because the emails were Normal priority. |
| PagerDuty | Off (`"0"`) for all three. |
| Biggest problem | Alert 1 and Alert 3 run the exact same query. |
| Trickiest alert | Alert 2 fires when something is missing, not when something appears. |

## Summary

All three alerts are converted. Alerts 1 and 3 are simple "a timeout line appeared" detectors, but they are copies of each other, so one timeout opens two problems. Alert 2 is an absence check (fewer than 2 import lines in 24 hours), which needs `summarize count()` plus a weekday 08:30 JST guard to behave like the old schedule.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Records detector | A Dynatrace rule that runs a DQL query every minute and opens a problem when rows come back. | This is the real replacement for the fake `dynatrace_log_alert`. |
| Absence alert | An alert that fires when an expected log line did not show up. | Alert 2 is this kind. Plain filters cannot express "missing". |
| `summarize count()` | Collapses all matching lines into one row with a count. | It returns a row with 0 even when nothing matched, so "fewer than 2" can fire. |
| Identity field | The field Dynatrace uses to decide "same problem or new problem". | One problem per log group, or one per `scope` for Alert 2. |
| JST guard | Extra filters that only let the row through on weekdays between 08:30 and 08:59 Tokyo time. | Copies the old `30 8 * * 1-5` schedule. |

### What each old field became

| Old field | New form |
|---|---|
| `alert_type`, `schedule_type` | Dropped. A detector always runs every minute. |
| `cron_expression "*/5 * * * *"` (Alerts 1 and 3) | Dropped. Every minute is stricter than every 5 minutes. |
| `cron_expression "30 8 * * 1-5"` (Alert 2) | JST guard inside the query. |
| `time_range LAST_6_MINUTES` | `fetch logs, from:now()-6m` |
| `time_range LAST_24_HOURS` | `fetch logs, from:now()-24h` |
| `expires = 24` | Dropped. Problems close on their own when the query returns nothing. |
| `GREATER_THAN 0` (Alerts 1 and 3) | Detector default. Any row opens a problem. |
| `LESS_THAN 2` (Alert 2) | `summarize matches = count()` then `filter matches < 2`. |
| `throttle_enabled = false` | Identity field instead. |
| Two log group checks joined with `or` | One `contains(aws.log_group, "sa-support-batches")`. The short one already covers the long one. |
| `description = "Optional"` | Real descriptions. |
| `SEND_EMAIL` with recipients | Moved to the workflow. Recipients are not copied. |
| `subject "Alert: $name$"` | Dropped. `$name$` is a Splunk token. |
| `priority NORMAL` | `alert.severity = "medium"`. |

### Things found in the file

| Finding | What it means |
|---|---|
| Alert 1 equals Alert 3 | Same log group, same "Task timed out" filter, same 6 minute window. One timeout gives two problems and two emails. |
| Alert 1 name says "Error" | The filter only finds timeouts. The real error text was probably never filled in. |
| Alert 2 uses "started" | This word appears in many normal log lines. The count may never drop below 2, so the alert may never fire. |
| Alert 2 is weekday only | Without the JST guard, a rolling 24 hour window would fire every weekend. |

## Result

### Alert 1: Sa Support Batch Error

```hcl
resource "dynatrace_davis_anomaly_detectors" "sa_support_batch_error" {
  title       = "Sa Support Batch Error"
  description = "Lambda sa-support-batches logged Task timed out in the last 6 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-6m
          | filter contains(aws.log_group, "sa-support-batches")
          | filter contains(content, "Task timed out", caseSensitive:false)
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
        value = "Sa Support Batch Error"
      }
      property {
        key   = "event.description"
        value = "Lambda sa-support-batches logged Task timed out. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "sa-support-batches"
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

### Alert 2: Sa Support Batch File Import Confirmation

Only the query, identity field and texts differ from Alert 1. Full block is in the `.tf` file.

```
fetch logs, from:now()-24h
| filter contains(aws.log_group, "sa-support-batches")
| filter contains(content, "importFileHandler :: runner :")
    or contains(content, "importSagaFundGroup")
    or contains(content, "started")
| summarize matches = count()
| filter matches < 2
| fieldsAdd jst_day = formatTimestamp(now(), format:"EEE", timezone:"Asia/Tokyo"),
            jst_hhmm = toLong(formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo"))
| filter in(jst_day, {"Mon", "Tue", "Wed", "Thu", "Fri"})
| filter jst_hhmm >= 830 and jst_hhmm < 900
| fieldsAdd scope = "sa-support-batches-import"
```

| Setting | Value |
|---|---|
| Resource name | `sa_support_batch_file_import_confirmation` |
| Identity field | `scope` |
| `event.description` | sa-support-batches logged fewer than 2 file import lines in the last 24 hours. The import may not have run. |
| Severity | medium |
| PagerDuty | `"0"` |

The problem opens at 08:30 JST if the import is missing and closes at 09:00 when the guard stops matching. The email goes out once, at open time.

### Alert 3: Sa Support Batch Task Time Out

Same block as Alert 1, with resource name `sa_support_batch_task_timeout` and title and `event.name` "Sa Support Batch Task Time Out".

### What to decide

| Decision | Recommendation |
|---|---|
| Alerts 1 and 3 are duplicates | Ask the owner for the real error text for Alert 1. Check query 2 shows candidate error lines. If no answer, delete Alert 1. |
| Keep "started" in Alert 2? | Run check query 3. If "started" gives many hits per day, remove it. |
| JST guard does not work | Run check query 4 at 08:30 JST. If it fails, use a workflow with a schedule trigger at 08:30 JST Mon-Fri that runs the count query. |

## Data flow map

```
Lambda sa-support-batches writes logs
  → CloudWatch Logs
  → Dynatrace Grail logs
  → Alert 1: every minute, last 6 min, "Task timed out" → problem (medium)
  → Alert 3: every minute, last 6 min, "Task timed out" → problem (medium)  ← duplicate
  → Alert 2: every minute, last 24 h, count import lines
       count < 2 and weekday 08:30-08:59 JST → problem (medium)
  → workflow: pagerduty.enabled = "0" → email (recipients set in workflow)
```

## Related files

| File | What it holds |
|---|---|
| `17-sa-support-batches-three-alerts-tf.tf` | Full Terraform for all three detectors. |
| `17-sa-support-batches-three-alerts-tf-check.dql` | Four check queries to run in a Notebook first. |
| `0-pic.md` | Decision tree and data flow only. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `17.sh` | Commands, one per line. |

## Commands

All commands are in [`17.sh`](./17.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/17-sa-support-batches-three-alerts-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/17-sa-support-batches-three-alerts-tf
git commit -m "Sa support batches three alert detectors"
git push
```
