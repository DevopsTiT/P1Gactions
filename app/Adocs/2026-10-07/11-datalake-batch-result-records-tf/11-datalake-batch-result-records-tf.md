# Datalake Batch Result Records Alert

## Decision Tree

```
Splunk: index=batch_monitoring_logs | table _time _raw, Today, 08:00 daily → email the lines
 → it is a daily REPORT, not a failure alert
 Records detector (this file): any batch line in the last 2 hours → one email at about 02:00
 must arrive exactly at 08:00? → scheduled workflow (2026-10-05 seq 42)
 want a real alert instead?
   "Failed" line → alert on that (but "Failed to delete Data LINEBOT.csv" happens every night)
   no "sent to UDM successfully" by 03:00 → batch broke → missing-success alert
```

## Short Takeaway

| Question | Answer |
|---|---|
| What the Splunk alert does | Emails today's batch log lines every morning at 08:00 |
| What the batch does | Every night at about 02:00 it compresses the LINE log, sends it to UDM and deletes the original |
| Lines per night | 8 (240 in 30 days) |
| Hidden problem | "Failed to delete Data LINEBOT.csv" happens every night |
| Dynatrace timing | Email at about 02:00 when the lines arrive, not at 08:00 |
| Notification | Email only: severity low, `pagerduty.enabled = "0"` |

## Summary

This Splunk alert is really a morning report: at 08:00 it sends whatever the batch logged today. The batch writes 8 lines at about 02:00. The Records detector raises one low-severity problem when those lines arrive, so the email comes at about 02:00. The logs show the deletion step fails every night, which nobody seems to act on. Fix it or agree it's expected, otherwise any "Failed" alert will fire daily.

## Batch Steps In The Log

| Line | What it means |
|---|---|
| `########Process Start########` | The batch started |
| `File LINEBOT.csv is existing` | The input file is present |
| `########Data Compression Initiated########` | Compression step started |
| `Compression SP_LINE_LOG_<date>.csv successfully Completed` | The file was compressed |
| `########Data transfering Initiated########` | Transfer step started |
| `Data SP_LINE_LOG_<date>.csv sent to UDM successfully` | The file reached UDM (the main success signal) |
| `########Original Data Deletion Initiated########` | Clean-up step started |
| `Failed to delete Data LINEBOT.csv` | Clean-up failed (every night) |

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index="batch_monitoring_logs"` | `matchesValue(log.source, "*batch_monitoring*")` (confirm with check.dql query 1) |
| `table _time _raw` | `fields timestamp, content` |
| Time range Today, cron 08:00 | Checks every minute and looks back 2 hours, so it alerts at about 02:00 |
| Results > 0 | Any row raises an alert |
| For each result | One problem per night (`alertIdentityFields[0] = check`) |
| Expires 24 hours | No equivalent |
| Email to one person, Normal | `alert.severity low`, `pagerduty.enabled 0`; send to a team list in the standard flow |

## Compared With 2026-10-05 Seq 43

| Topic | Seq 43 | This file |
|---|---|---|
| Detector type | Timeseries (makeTimeseries, threshold 0, dealerting 60) | Records (no makeTimeseries) |
| Query | Count per minute | The lines themselves (timestamp and content) |
| Knowledge of data | Guessed | 8 lines at 02:00, real step names |
| Resource name | datalake_batch_result | datalake_batch_result (apply one only) |

## Query

```
fetch logs
| filter matchesValue(log.source, "*batch_monitoring*")
| fields timestamp, content
| fieldsAdd check = "datalake_batch_result"
```

## Better Alerts To Consider

| Idea | Query change | Why |
|---|---|---|
| Batch did not deliver | `from:now()-24h`, count "sent to UDM successfully", alert when 0 | Catches a broken or skipped batch |
| Step failed | `filter contains(content, "Failed")` and not the known LINEBOT delete line | Alerts only on new failures |

## Data Flow

```
02:00 nightly batch → 8 lines → batch_monitoring log → Grail
  → Records detector (every minute): lines in last 2 hours? → low problem → email (about 02:00)
  → 04:00: no lines in the last 2 hours → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | index batch_monitoring_logs, table _time _raw, Today, cron 0 8 * * *, > 0, email Normal to one person |
| Search screenshot | 240 events from 9/7 to 10/7, 8 per night at about 02:00 |
| Daily pattern | Same 8 steps every night; deletion of LINEBOT.csv always fails |
| Earlier answers | 2026-10-05 seq 42 (workflow at 08:00) and seq 43 (Timeseries detector) |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm the log.source filter |
| 2 | Run query 4 and raise the nightly LINEBOT.csv delete failure with the Datalake team |
| 3 | Choose: this detector (about 02:00), the seq 42 workflow (08:00), or a missing-success alert |
| 4 | `terraform plan` shows 1 to add (or 1 to change if seq 43 was applied) |

## Related Files

| File | Purpose |
|---|---|
| `11-datalake-batch-result-records-tf.tf` | Records detector Terraform |
| `11-datalake-batch-result-records-tf-check.dql` | Check queries |
| `11.sh` | Commands |
