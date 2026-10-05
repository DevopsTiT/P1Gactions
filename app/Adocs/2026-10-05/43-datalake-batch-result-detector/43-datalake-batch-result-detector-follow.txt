# Datalake Batch Result Detector

## Decision Tree

```
Splunk "Datalake_Batch Result" → Dynatrace alert only (no workflow)
 → static-threshold detector: any batch_monitoring line → problem
   one batch run opens many problems? → dealerting is 60 quiet minutes, so no
   alerts on every normal run?        → check.dql query 4 → add a failure filter
   no data?                           → check.dql query 1 → fix log.source
   seq 29 or 42 workflow applied?     → remove it (same report, different shape)
```

## Short Takeaway

| Question | Answer |
|---|---|
| Shape | 1 static-threshold detector, no workflow |
| Fires when | Any batch_monitoring line appears (count above 0 in a minute) |
| Closes when | 60 minutes with no new lines |
| Severity | low, no paging (Splunk priority Normal) |
| Main difference | Real-time problem instead of one 08:00 email with the list of lines |

## Summary

A Dynatrace detector runs every minute, so it cannot hold results until 08:00. It opens one problem as soon as the batch writes lines and closes it an hour after the last line, so each batch run becomes one problem. The notification comes from the standard flow and does not include the log lines; query 2 shows them.

## Splunk Settings Mapped

| Splunk | Dynatrace detector |
|---|---|
| `index="batch_monitoring_logs"` | `filter matchesValue(log.source, "*batch_monitoring*")` |
| Results greater than 0 | `threshold = 0`, `alertCondition = ABOVE` |
| Time range Today, cron 08:00 | Not possible in a detector; it checks every minute |
| Email to masayuki.yasuda, Normal | Standard flow notification, severity low, `pagerduty.enabled = 0` |
| `table _time _raw` in the email | Not in the problem; use check.dql query 2 |

## Settings

| Setting | Value | Why |
|---|---|---|
| threshold | 0 | Same as "results > 0" |
| violatingSamples | 1 | One minute with lines is enough |
| slidingWindow | 5 | Short window, opens quickly |
| dealertingSamples | 60 | A batch that writes lines over an hour stays one problem |
| alert.severity | low | Informational, like Splunk Normal |

## Watch Out

| Risk | What to do |
|---|---|
| batch_monitoring_logs may hold normal success lines | Run query 4; if so, add a filter such as `loglevel == "ERROR"` or a failure keyword |
| Recipient was one person | Route through the standard flow by `app.name = Datalake` |

## Data Flow

```
batch job → batch_monitoring_logs → Grail
  → detector (every minute): lines in this minute > 0 ?
      yes → open problem (one per run) → standard flow → email / SILVA
  → 60 minutes with no lines → problem closes
```

## Investigation

| Checked | Evidence |
|---|---|
| Screenshot | Search, Today, cron 0 8, results > 0, email masayuki.yasuda, Normal |
| User request | Alert only, no workflow |
| Seq 29 and 42 | Workflow versions of the same alert; replaced by this |

## Result

| Step | What to do |
|---|---|
| 1 | Run query 1 to confirm log.source |
| 2 | Run query 4; add a failure filter if success lines exist |
| 3 | `terraform plan` should show 1 to add |
| 4 | Do not also apply seq 29 or 42 |

## Related Files

| File | Purpose |
|---|---|
| `43-datalake-batch-result-detector.tf` | Standalone detector Terraform |
| `43-datalake-batch-result-detector-check.dql` | 4 check queries |
| `43.sh` | Commands |

## Commands

See `43.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/43-datalake-batch-result-detector"
terraform init
terraform validate
terraform plan
```
