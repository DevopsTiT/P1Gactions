# Datalake Batch Result Alert

## Decision tree

```
Splunk: index="batch_monitoring_logs" | table _time _raw, daily 08:00, Today
 index → host + source from screenshot
   hosts → CEAA20BD, CEAA20BE, CEAA2101
   source → datalake_transfer.log
 cron 0 8 * * * → detector runs every minute → JST guard 08:00 to 08:04
 Today → from:now()-8h (08:00 minus 8 hours = midnight JST)
 table _time _raw → fields timestamp, host.name, content
 more than 0 results → no summarize
 email Normal, really a report → low, PagerDuty 0
 want a real alert instead? → check query 3 → alert only on Failed lines
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it? | A daily 08:00 report that emails today's datalake batch log. It is not a failure alert. |
| Hosts | CEAA20BD, CEAA20BE and CEAA2101. |
| Source | `datalake_transfer.log`. |
| Timing | JST guard lets rows through only from 08:00 to 08:04. |
| Identity | `host.name`, one problem per host. |
| Severity | low, PagerDuty off. |

## Summary

Splunk runs this once a day at 08:00 and emails every batch line from today. Dynatrace detectors run every minute, so a time guard stands in for the cron. The batch log shows lines such as "Failed to delete Data LINEBOT.csv", so a failure-only alert would be more useful than a daily dump.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Cron `0 8 * * *` | Run every day at 08:00. | Detectors have no cron, so a time guard copies it. |
| Time range Today | From midnight until now. | At 08:00 JST that is the last 8 hours. |
| `table _time _raw` | Show time and full log line only. | Becomes `fields timestamp, host.name, content`. |
| JST guard | A filter on the current Tokyo time. | Makes rows exist only for 5 minutes after 08:00. |
| Identity field | Field deciding one problem or many. | `host.name` gives each server its own problem. |

### What the screenshots show

| Item | Value |
|---|---|
| Host 1 | ceaa20BD.prprivmgmt.intraxa (112 events, 45%) |
| Host 2 | CEAA20BE.prprivmgmt.intraxa (80 events, 32%) |
| Host 3 | CEAA2101.prprivmgmt.intraxa (56 events, 23%) |
| Source | /app/splunk/var/log/splunk/datalake_transfer.log |
| Batch time | About 02:00:43 JST |
| Example success | Compression SP_LINE_LOG_...csv successfully Completed |
| Example failure | Failed to delete Data LINEBOT.csv |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| Alert `Datalake_Batch Result` | `title` kept. |
| Description "Optional" | Replaced with a real description. |
| `index="batch_monitoring_logs"` | Three `host.name` filters plus `log.source` contains `datalake_transfer.log`. |
| `table _time _raw` | `fields timestamp, host.name, log.source, content`. |
| Time range Today | `fetch logs, from:now()-8h`. |
| Cron `0 8 * * *` | JST guard: `jst_hhmm >= 800 and jst_hhmm < 805`. |
| Expires 24 hours | Dropped. |
| Number of results greater than 0 | Detector default. No `summarize`. |
| Trigger once, throttle off | Identity `host.name`. |
| Send email, Normal | `alert.severity = "low"`, `pagerduty.enabled = "0"`. Recipients not copied. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title       = "Datalake_Batch Result"
  description = "Daily 08:00 JST report of today's datalake transfer batch log from CEAA20BD, CEAA20BE and CEAA2101. One problem per host, carrying the batch lines."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-8h
          | filter contains(host.name, "CEAA20BD", caseSensitive:false)
              or contains(host.name, "CEAA20BE", caseSensitive:false)
              or contains(host.name, "CEAA2101", caseSensitive:false)
          | filter contains(log.source, "datalake_transfer.log", caseSensitive:false)
          | fieldsAdd jst_hhmm = toLong(formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo"))
          | filter jst_hhmm >= 800 and jst_hhmm < 805
          | fields timestamp, host.name, log.source, content
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "host.name"
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
        value = "Datalake batch result"
      }
      property {
        key   = "event.description"
        value = "Today's datalake transfer batch log lines for this host. Check for lines such as Failed to delete or missing Successfully Completed."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "datalake"
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

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Confirms the logs reach Dynatrace and shows the exact `host.name` and `log.source`. The Splunk source path lives under Splunk's own folder, so the Dynatrace path may differ. |
| Check query 2 | Shows today's lines, the same as the Splunk table. |
| Check query 3 | Failure-only view. If the team only cares about failures, use this filter in the detector and raise severity to medium. |
| Severity | Set to low because this is a daily report. Change to medium if you want it in the normal alert flow. |
| Problem closing | The problem opens at 08:00 and closes after 08:05 when the guard stops matching. The email is sent when it opens. |

## Data flow map

```
02:00 JST datalake batch runs on CEAA20BD, CEAA20BE, CEAA2101
  → writes datalake_transfer.log
  → Dynatrace Grail logs
  → detector every minute
       JST time 08:00 to 08:04? no → nothing
       yes → today's lines (last 8 h) → problem per host (low)
  → workflow: pagerduty.enabled = "0" → email
  → after 08:05 → guard stops matching → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `38-datalake-batch-result-tf.tf` | Full Terraform. |
| `38-datalake-batch-result-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `38.sh` | Commands, one per line. |

## Commands

All commands are in [`38.sh`](./38.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/38-datalake-batch-result-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/38-datalake-batch-result-tf
git commit -m "Datalake batch result detector"
git push
```
