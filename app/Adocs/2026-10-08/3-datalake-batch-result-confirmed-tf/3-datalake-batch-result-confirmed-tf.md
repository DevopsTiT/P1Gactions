# Datalake Batch Result Confirmed

## Decision tree

```
Today's Splunk search (10/8 00:00 to 10:11)
 8 events? → yes → one batch run per night, 8 lines → identity check (1 problem) is right
 source = /app/splunk/var/log/splunk/datalake_transfer.log? → yes → filter unchanged
 host = ceaa20bd? → yes → no host filter needed
 time 02:00:41? → yes → detector fires about 02:00, problem closes about 04:00
 last line "Failed to delete Data LINEBOT.csv"? → yes, again → raise with Datalake team
Result: seq 2 Terraform is correct as is
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the screenshot show? | Exactly what the 08:00 Splunk email contains today: 8 lines from 02:00:41 |
| Does the Terraform change? | No. Seq 2 is confirmed. This folder is a confirmed copy. |
| Filter | `contains(log.source, "datalake_transfer.log")` |
| Problems per night | 1 |
| New finding | The LINEBOT.csv delete failure happened again on 10/8 |

## Summary

The Today search returns 8 events, all written at 02:00:41 JST by one batch run on ceaa20bd into `datalake_transfer.log`. That matches every assumption in the seq 2 detector, so the Terraform stays the same.

## Today's 8 lines

| Order | Line | Meaning |
|---|---|---|
| 1 | `########Process Start########` | Batch started |
| 2 | `File LINEBOT.csv is existing` | Input file found |
| 3 | `########Data Compression Initiated########` | Compression started |
| 4 | `Compression SP_LINE_LOG_20261007_020041.csv successfully Completed` | Compression done |
| 5 | `########Data transfering Initiated########` | Transfer started |
| 6 | `Data SP_LINE_LOG_20261007_020041.csv sent to UDM successfully` | Delivered to UDM |
| 7 | `########Original Data Deletion Initiated########` | Clean-up started |
| 8 | `Failed to delete Data LINEBOT.csv` | Clean-up failed (every night) |

## Terraform

File: `3-datalake-batch-result-confirmed-tf.tf` (same detector as seq 2)

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
  # event_template: CUSTOM_ALERT, severity low, app.name Datalake, pagerduty.enabled "0"
}
```

## Data flow

```
10/8 02:00:41 batch on ceaa20bd → 8 lines → datalake_transfer.log
 → Splunk index batch_monitoring_logs → 08:00 email (old)
 → OneAgent → Grail → Records detector → 1 problem 02:00 to 04:00 → low email (new)
```

## Investigation

| What was checked | Finding |
|---|---|
| Event count, Today | 8 |
| Time of all events | 10/8 02:00:41 JST |
| host | ceaa20bd.prprivmgmt.intraxa |
| source | /app/splunk/var/log/splunk/datalake_transfer.log |
| sourcetype | datalake_transfer |
| Last line | Failed to delete Data LINEBOT.csv |

## Result

| Step | What to do |
|---|---|
| 1 | Use seq 2 or this file (identical detector). Apply only one. |
| 2 | Run check query 1 in Dynatrace to confirm the file is ingested |
| 3 | Raise the LINEBOT.csv delete failure with the Datalake team |

## Related files

| File | Purpose |
|---|---|
| `3-datalake-batch-result-confirmed-tf.tf` | Detector |
| `3-datalake-batch-result-confirmed-tf-check.dql` | Check queries |
| `3.sh` | Commands |

## Commands

See `3.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/3-datalake-batch-result-confirmed-tf"
terraform init
terraform validate
terraform plan
```
