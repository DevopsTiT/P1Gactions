# Datalake Batch Result Source Fix

## Decision tree

```
Splunk search: index="batch_monitoring_logs"
 What does the event detail show?
  source     = /app/splunk/var/log/splunk/datalake_transfer.log
  host       = ceaa20bd.prprivmgmt.intraxa (case varies: CEAA20BD on older lines)
  sourcetype = datalake_transfer
 Which filter in Dynatrace?
  index name "batch_monitoring_logs" → does not exist in Dynatrace → drop the seq 11 guess
  file path → contains(log.source, "datalake_transfer.log") → USE THIS
  host name → case changes between nights → do not depend on it
 Check query 1 returns rows?
  yes → apply the tf
  no  → OneAgent is not collecting the file → add it to log ingest rules first
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from seq 11? | The filter now uses the real log file path instead of a guessed index name. |
| New filter | `contains(log.source, "datalake_transfer.log")` |
| Why not filter by host? | The host appears as `ceaa20bd` on new lines and `CEAA20BD` on older ones, and the file path alone is enough. |
| When does the batch run? | 02:00 JST every night. All 8 lines are written in the same second. |
| Severity and PagerDuty | `low`, `pagerduty.enabled = "0"` (email only in Splunk) |
| Resource name | Same as seq 11 (`datalake_batch_result`). Apply only this version. |

## Summary

The screenshot shows the Splunk index `batch_monitoring_logs` is fed from one file, `/app/splunk/var/log/splunk/datalake_transfer.log`. Dynatrace has no Splunk index, so the detector now filters on that file path. Everything else (Records analyzer, one problem per night, low severity, no PagerDuty) stays the same as seq 11.

## What the screenshot proves

| Field | Value | What it means for Dynatrace |
|---|---|---|
| source | `/app/splunk/var/log/splunk/datalake_transfer.log` | This becomes `log.source` in Dynatrace if OneAgent collects the file. |
| host | `ceaa20bd.prprivmgmt.intraxa` | The batch runs on one host. Upper and lower case both appear. |
| sourcetype | `datalake_transfer` | Splunk-only label. Not needed in DQL. |
| Events in 30 days | 240 | 8 lines per night for 30 nights. No missed nights. |
| Time | 02:00:33 (10/6), 02:00:44 (10/5) | The batch runs once at about 02:00 JST. |
| Last line every night | `Failed to delete Data LINEBOT.csv` | A known daily failure in the clean-up step. |

## Terraform

File: `12-datalake-batch-result-source-fix.tf`

```hcl
resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title   = "Datalake_Batch Result"
  enabled = true
  source  = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "datalake_transfer.log")
          | fields timestamp, host.name, content
          | fieldsAdd check = "datalake_batch_result"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
      }
    }
  }

  event_template {
    properties {
      property { key = "event.type"        value = "CUSTOM_ALERT" }
      property { key = "event.name"        value = "Datalake_Batch Result" }
      property { key = "alert.severity"    value = "low" }
      property { key = "app.name"          value = "Datalake" }
      property { key = "pagerduty.enabled" value = "0" }
    }
  }

  execution_settings {}
}
```

The full file in the folder has the provider block and description.

## Check queries

File: `12-datalake-batch-result-source-fix-check.dql`

```
fetch logs, from:now()-2d
| filter contains(log.source, "datalake_transfer")
| summarize lines = count(), by:{host.name, log.source}
```

| Query | What it tells you |
|---|---|
| 1 | Whether the file reaches Dynatrace, and the exact path and host name |
| 2 | Last night's 8 lines in JST, like the Splunk email |
| 3 | Lines per night for 30 days. Fewer than 8 means the batch stopped early. |
| 4 | Every Failed line in 30 days |

## Data flow

```
02:00 JST batch on ceaa20bd
 → writes 8 lines to /app/splunk/var/log/splunk/datalake_transfer.log
   → Splunk forwarder → index batch_monitoring_logs → 08:00 email (old)
   → OneAgent log ingest → Grail logs (log.source = file path)
     → Records detector runs every minute (2 h lookback)
       → rows found → 1 problem (identity = check) → low-severity email
       → about 04:00 rows age out → problem closes
```

## Investigation

| What was checked | Finding |
|---|---|
| Event detail fields in the screenshot | source, host, and sourcetype are all visible on every line. |
| Seq 11 filter `*batch_monitoring*` | That was the Splunk index name, which never exists in Dynatrace log fields. |
| Host name across nights | `ceaa20bd` on 10/6 and upper case `CEAA20BD` on 10/5, so a host filter is fragile. |
| Event count | 240 events in 30 days means 8 per night, every night. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check query 1. If it returns nothing, ask the platform team to add `/app/splunk/var/log/splunk/datalake_transfer.log` to OneAgent log ingest on ceaa20bd. |
| 2 | If query 1 shows a slightly different path, adjust the `contains` text. |
| 3 | Apply only this tf (seq 11 and Oct 5 seq 43 use the same resource name). |
| 4 | Raise the nightly `Failed to delete Data LINEBOT.csv` with the Datalake team. |

## Related files

| File | Purpose |
|---|---|
| `12-datalake-batch-result-source-fix.tf` | Detector |
| `12-datalake-batch-result-source-fix-check.dql` | Check queries |
| `12.sh` | Commands |
| `../11-datalake-batch-result-records-tf/` | Previous version with the guessed filter |

## Commands

See `12.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/12-datalake-batch-result-source-fix"
terraform init
terraform validate
terraform plan
```
