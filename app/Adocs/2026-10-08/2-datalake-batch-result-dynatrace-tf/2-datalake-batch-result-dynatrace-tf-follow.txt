# Datalake Batch Result Dynatrace Terraform

## Decision tree

```
Splunk alert Datalake_Batch Result
 Search: index="batch_monitoring_logs" | table _time _raw
  index has no Dynatrace equivalent → use the file it comes from
   → contains(log.source, "datalake_transfer.log")
 Schedule: 08:00 daily, range Today, results > 0
  Dynatrace Records detector → fires when lines arrive (about 02:00)
  must be exactly 08:00? → use the scheduled workflow (2026-10-05 seq 42) instead
 Trigger Once or For each result?
  Once            → identity check (constant) → 1 problem per night → USE THIS
  For each result → Splunk sends 8 emails → do not copy
 Action: email to one person, priority Normal
  → severity low, pagerduty "0", route by app.name Datalake
```

## Short takeaway

| Question | Answer |
|---|---|
| Detector type | Records detector (no `makeTimeseries`) |
| Filter | `contains(log.source, "datalake_transfer.log")` |
| Problems per night | 1 (identity `check`) |
| When it fires | About 02:00, when the batch writes its 8 lines |
| Severity | low |
| PagerDuty | `"0"` (email only in Splunk) |
| Recipient | Not copied (personal address); use team routing |
| Same as | 2026-10-07 seq 12. Apply only one version. |

## Summary

Splunk reads the `batch_monitoring_logs` index at 08:00 and emails whatever the batch wrote today. Dynatrace has no Splunk index, so the detector filters on the real file path. It fires when the lines arrive instead of at 08:00, and groups all lines into one problem.

## Splunk setting to Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index="batch_monitoring_logs"` | `filter contains(log.source, "datalake_transfer.log")` |
| `table _time _raw` | `fields timestamp, host.name, content` |
| Cron `0 8 * * *` | Detector runs every minute |
| Time range Today | Default 2-hour lookback, so the problem lasts about 02:00 to 04:00 |
| Number of Results > 0 | Any row opens a problem |
| Trigger Once | `alertIdentityFields[0] = check` (one problem) |
| Expires 24 hours | Problem closes by itself when rows age out |
| Send email, priority Normal | `alert.severity = low`, `pagerduty.enabled = "0"` |

## Terraform

File: `2-datalake-batch-result-dynatrace-tf.tf`

```hcl
resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title       = "Datalake_Batch Result"
  description = "Daily Datalake batch result from datalake_transfer.log: LINE log compression, transfer to UDM, and original data deletion."
  enabled     = true
  source      = "Davis Anomaly Detection"

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

The full file has the provider block and the event description.

## Data flow

```
02:00 batch on ceaa20bd → datalake_transfer.log (8 lines)
 → OneAgent → Grail logs
   → Records detector every minute
     → rows → 1 problem (check) → low email via standard flow
     → about 04:00 rows leave the 2 h window → problem closes
```

## Investigation

| What was checked | Finding |
|---|---|
| Edit Alert screenshot | Scheduled, cron `0 8 * * *`, Today, results > 0, email one person, Normal |
| Trigger setting | Once and For each result buttons visible; selected one is unclear in the photo |
| Earlier event screenshot (10-07) | Source is `/app/splunk/var/log/splunk/datalake_transfer.log` |
| Earlier versions | 2026-10-07 seq 11 (guessed filter) and seq 12 (same as this) |

## Result

| Step | What to do |
|---|---|
| 1 | Run check query 1 to confirm the file reaches Dynatrace |
| 2 | Apply this file only (not seq 11 or 12 as well) |
| 3 | Need the email at exactly 08:00? Use the workflow from 2026-10-05 seq 42 |
| 4 | Raise the nightly `Failed to delete Data LINEBOT.csv` with the Datalake team |

## Related files

| File | Purpose |
|---|---|
| `2-datalake-batch-result-dynatrace-tf.tf` | Detector |
| `2-datalake-batch-result-dynatrace-tf-check.dql` | Check queries |
| `2.sh` | Commands |

## Commands

See `2.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/2-datalake-batch-result-dynatrace-tf"
terraform init
terraform validate
terraform plan
```
