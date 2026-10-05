# Datalake Batch Result Transfer

## Decision tree

```
Splunk "Datalake_Batch Result"
 search = every line in index, shown as a table (_time, _raw)
 runs once a day at 08:00, time range "Today"
   → it is a daily report, not an error alert
   → detector? no (a detector opens a problem, it cannot email a list of lines)
   → scheduled workflow (still a Terraform file)
 "Today" in Dynatrace?
   → workflow runs 08:00 JST → from:now()-8h = midnight JST
   → avoid @d (aligns to UTC midnight = 09:00 JST, after the run)
 no lines today?
   → Splunk sends nothing → workflow skips the email (same)
   → want a "batch did not run" warning instead? → flip the condition to == 0
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk alert do? | Every day at 08:00 it emails all batch monitoring lines since midnight |
| Detector or workflow? | Scheduled workflow, because the deliverable is a list of lines by email |
| Paging? | No. This is a report, it should not go to SILVA or PagerDuty |
| What must be confirmed | The field replacing `index="batch_monitoring_logs"` and the email address spelling |

## Summary

This Splunk "alert" is really a morning report. A Dynatrace detector would turn it into a problem and page through the standard flow, which is wrong. A scheduled workflow runs the same query at 08:00 JST and emails the lines, and skips the email when there are none, exactly like Splunk's "results > 0".

## Splunk to Dynatrace mapping

| Splunk | Dynatrace |
|---|---|
| `index="batch_monitoring_logs"` | `matchesValue(log.source, "*batch_monitoring*")` (CONFIRM) |
| `table _time _raw` | `fields timestamp, content` |
| Time range "Today" | `from:now()-8h` (run time 08:00 JST minus 8 hours) |
| Cron `0 8 * * *` | Workflow schedule `0 8 * * *`, time zone Asia/Tokyo |
| Number of results > 0 | Email task condition: records length > 0, else SKIP |
| Send email, subject `$name$` | `send-email` task, subject shows the workflow name and line count |

## Issues found in the Splunk alert

| Issue | What it means |
|---|---|
| Description "Optional" | Nobody wrote what the report is for |
| One personal recipient | If that person leaves or is on holiday, nobody sees the report. Consider a team list |
| No upper limit | A noisy day would produce a huge email. The workflow caps it at 500 lines |
| No "did not run" check | If the batch never logs anything, Splunk stays silent. That may hide a failed batch |

## Terraform

File: `29-datalake-batch-result-transfer.tf`

```hcl
query = <<-EOT
  fetch logs, from:now()-8h
  | filter matchesValue(log.source, "*batch_monitoring*")   // CONFIRM
  | sort timestamp asc
  | fields timestamp, content
  | limit 500
EOT

custom = "{{ result(\"get_batch_lines\").records | length > 0 }}"   // else SKIP
cron   = "0 8 * * *"   time_zone = "Asia/Tokyo"
```

The email body loops over the records and prints one line per log entry (time, then the raw line).

## Optional: also warn when the batch did not run

Change the email condition to `records | length == 0` in a second workflow (or a second email task) with the subject "Datalake batch wrote no logs since midnight". Only do this if the owner agrees that silence means failure.

## Data flow

```
Datalake batch → batch_monitoring_logs → Grail
08:00 JST schedule → workflow
   → get_batch_lines: lines from 00:00 to 08:00 JST (max 500)
   → lines > 0 ? → send_email (one line per log entry)
   → lines = 0 ? → SKIP (no email, same as Splunk)
```

## Investigation

| Checked | Found |
|---|---|
| Search | `index="batch_monitoring_logs" | table _time _raw`, no filter at all |
| Time range | Today |
| Cron | `0 8 * * *` |
| Trigger | Number of results greater than 0, once |
| Throttle | Off (not needed for a daily run) |
| Action | Email to one person, priority Normal |

## Result

| Step | Action |
|---|---|
| 1 | Run `check.dql` query 1 and fix the `log.source` line |
| 2 | Run query 2 to see daily volume. Raise or lower the 500 limit |
| 3 | Run query 3 with today's 00:00 to 08:00 to preview the email |
| 4 | Confirm the recipient address (and consider a team list) |
| 5 | `terraform plan` should show 1 workflow |
| 6 | Run the workflow once by hand in Dynatrace, check the email, then disable the Splunk alert |

## Related files

| File | Purpose |
|---|---|
| `29-datalake-batch-result-transfer.tf` | Scheduled workflow |
| `29-datalake-batch-result-transfer-check.dql` | Field, volume and preview checks |
| `29.sh` | Commands |

## Commands

See `29.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
