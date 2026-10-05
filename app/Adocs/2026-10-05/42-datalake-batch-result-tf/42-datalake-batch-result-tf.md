# Datalake Batch Result Terraform

## Decision Tree

```
Splunk "Datalake_Batch Result" (daily 08:00 list of today's batch lines)
 incident or report? → report → scheduled workflow (not a detector)
 already converted?  → yes, seq 29 → this is the standalone copy with JST times
 email empty?        → check.dql query 1 → fix log.source filter
 more than 500 lines a day? → check.dql query 3 → raise limit
 apply seq 29 and 42 together? → no, same resource name
```

## Short Takeaway

| Question | Answer |
|---|---|
| New alert? | No, same as seq 29 |
| Dynatrace shape | 1 scheduled workflow: DQL query, then email |
| Schedule | 08:00 every day, Asia/Tokyo |
| Time range | Midnight JST to 08:00 (`now()-8h`), same as Splunk "Today" |
| Empty day | Email is skipped, same as "results > 0" |
| Change from seq 29 | Provider block added; email shows JST timestamps |

## Summary

The alert is a daily report, so it becomes a scheduled workflow instead of a detector. A query collects every batch monitoring line since midnight JST, and the email step sends them only when there is at least one line.

## Splunk Settings Mapped

| Splunk | Dynatrace |
|---|---|
| `index="batch_monitoring_logs" \| table _time _raw` | `fetch logs` filtered on `log.source`, fields `time_jst` and `content` |
| Time range Today | `from:now()-8h` (run time 08:00 JST) |
| Cron `0 8 * * *` | Schedule trigger, cron `0 8 * * *`, time zone Asia/Tokyo |
| Results greater than 0 | Email task condition: records length > 0, else SKIP |
| Email to masayuki.yasuda@axa.co.jp, Normal | `dynatrace.email:send-email` to the same address |
| Subject `Splunk Alert: $name$` | `Prod_Datalake_BatchResult_Normal: N lines since midnight` |

## Data Flow

```
08:00 JST schedule
  → get_batch_lines: fetch logs since 00:00 JST, batch_monitoring, sorted, JST time
  → records > 0 ?
      yes → send_email: list of lines to masayuki.yasuda
      no  → skip
```

## Investigation

| Checked | Evidence |
|---|---|
| Screenshot | Search, Today, cron 0 8, results > 0, email masayuki.yasuda, Normal |
| Seq 29 tf | Same logic; no provider block; timestamps printed in UTC |
| Time range | `@d` would mean midnight UTC, so `now()-8h` is kept |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm the log.source filter |
| 2 | Run query 2 to preview the email |
| 3 | Run query 3; if a day has more than 500 lines, raise the limit |
| 4 | `terraform plan` should show 1 to add |
| 5 | Use this file or seq 29, not both |

## Related Files

| File | Purpose |
|---|---|
| `42-datalake-batch-result-tf.tf` | Standalone Terraform |
| `42-datalake-batch-result-tf-check.dql` | 3 check queries |
| `42.sh` | Commands |

## Commands

See `42.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/42-datalake-batch-result-tf"
terraform init
terraform validate
terraform plan
```
