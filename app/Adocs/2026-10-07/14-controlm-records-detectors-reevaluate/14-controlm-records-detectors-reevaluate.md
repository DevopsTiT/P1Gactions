# Control-M Records Detectors Re-evaluated

## Decision tree

```
Seq 31 (2026-10-05): 1 makeTimeseries detector + 6 workflows
 Today's rules: detectors only, Records analyzer, no makeTimeseries
 For each Splunk alert, what is it really?
  real-time failure (abend)            → Records detector, 1 problem per job_name
  "abended job ended again"            → Records detector, 1 problem per order_id
  claims job stuck 15+ min             → Records detector, 1 problem per run, closes when run ends
  daily status-report email (4 alerts) → a report is not an alert
                                        → re-evaluated as "no Ended OK run in lookback" detector
                                        → still need the daily email? keep those seq 31 workflows
  test copy, personal copy, CSV only   → not migrated
 Result: 6 detectors in one for_each resource, 0 workflows
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from seq 31? | Everything is a Records detector now. No workflows and no `makeTimeseries`. |
| How many detectors? | 6, in one resource `controlm_alerts` with `for_each` |
| Biggest change | The 4 daily status reports became "job had no successful run" alerts |
| Why? | A report email every day is not an alert. The useful signal in it is "the job did not finish OK". |
| What about failures? | `job_abend` already alerts on every Ended not OK within minutes, so the reports do not need to repeat it. |
| PagerDuty | `"0"` on all. `job_abend` is marked CONFIRM because its Splunk action was not visible. |

## Summary

Seq 31 copied the Splunk design closely, including four scheduled report emails. Re-evaluated with today's rules, every alert becomes a Records detector. Real-time alerts map almost one to one. The report emails turn into absence alerts that only fire when a job did not succeed, which is the thing people actually read those reports for.

## The 6 detectors

| Key | Splunk alert it replaces | Fires when | Identity | Severity |
|---|---|---|---|---|
| `job_abend` | CTL-M アベンドアラート and V2 | A job ended not OK in the last 5 minutes | `job_name` | high |
| `job_result_after_abend` | CTL-M:ジョブ実行結果通知 | A job that abended in the last 24 hours just ended again | `order_id` | medium |
| `claims_job_overrun` | Claim Job Over Run Alert | A claims job has run 15+ minutes with no end time | `order_id` | medium |
| `chde010m_no_success` | 3 CHDE010M report emails | CHDE010M has no Ended OK in 74 hours | `check` | medium |
| `chdr010m_no_success` | CHDR010M report email | CHDR010M has no Ended OK in 26 hours | `check` | medium |
| `pddw_no_success` | PDDW0100 report email | No PDDW job has Ended OK in 26 hours | `check` | medium |

## Why each identity field

| Identity | Effect |
|---|---|
| `job_name` | Two different jobs abending give two problems. The same job abending twice stays one problem. |
| `order_id` | Each Control-M run is its own problem. A stuck run closes as soon as it gets an end time. |
| `check` (constant) | Absence queries return at most one row, so one problem per detector |

## Lookback windows

| Detector | Lookback | Why |
|---|---|---|
| `chde010m_no_success` | 74h | The Splunk reports ran Tuesday to Saturday, so the Saturday-to-Tuesday gap is about 72 hours. |
| `chdr010m_no_success` | 26h | Daily job plus 2 hours grace |
| `pddw_no_success` | 26h | Daily jobs plus 2 hours grace |

Check query 4 shows the real run days. Shorten or lengthen the windows to match.

## Example: absence query

```
fetch logs, from:now()-26h
| filter matchesValue(log.source, "*controlm_activejobs*")
| filter job_name == "CHDR010M"
| summarize ok = countIf(status == "Ended OK")
| filter ok == 0
| fieldsAdd check = "chdr010m_no_success"
```

`summarize` without `by` always returns one row, so `filter ok == 0` works even when there are no CHDR010M lines at all.

## What is lost compared with seq 31

| Seq 31 feature | Status now | If you still need it |
|---|---|---|
| Daily job status emails with start and end times | Gone | Keep those 4 seq 31 workflows only |
| Per-job CC from controlm_SpecificContact.csv | Gone | Notifications follow the standard problem flow; route by `app.name` |
| Japanese title format (正常終了 and 異常終了) | Replaced by `result` field (recovered or failed again) | Add a workflow if the exact format matters |

## Data flow

```
Control-M → controlm_activejobs and controlm_alert logs → Grail
  → job_abend (5 min)               → 1 problem per job_name → high
  → job_result_after_abend (30 min) → 1 problem per order_id → medium
  → claims_job_overrun (24 h)       → 1 problem per stuck run → closes at end_time
  → *_no_success (26 h or 74 h)     → 1 problem when no Ended OK → closes on next success
     → problem notification → standard flow (email, PagerDuty only if enabled)
```

## Investigation

| What was checked | Finding |
|---|---|
| Seq 31 tf | 1 timeseries detector, 6 workflows, 4 of them daily reports |
| Today's rules | Detectors only, Records analyzer, no `makeTimeseries` |
| Abend detector | Already covers Ended not OK for every job, including the report jobs |
| Report alerts | Their value is "did the job finish OK", which an absence detector covers |
| Not-migrated list from seq 31 | Still valid: リラン確認, _test, and two 複製 copies |

## Result

| Step | What to do |
|---|---|
| 1 | Run check queries 1 and 2 to confirm log source and fields. |
| 2 | Run check query 3 to see how noisy `job_abend` will be. |
| 3 | Run check query 4 and adjust the lookback windows. |
| 4 | Confirm PagerDuty for `job_abend` with the Control-M owners. |
| 5 | Decide if the 4 daily emails are still needed. If yes, keep those seq 31 workflows next to this file. |
| 6 | If seq 31 was applied, `terraform plan` will remove the old `controlm_job_abend` resource and the workflows you drop. Read the plan before apply. |

## Related files

| File | Purpose |
|---|---|
| `14-controlm-records-detectors-reevaluate.tf` | The 6 detectors |
| `14-controlm-records-detectors-reevaluate-check.dql` | Check queries |
| `14.sh` | Commands |
| `../../2026-10-05/31-controlm-alerts-full-inventory-v2/` | Previous version (workflows) |

## Commands

See `14.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/14-controlm-records-detectors-reevaluate"
terraform init
terraform validate
terraform plan
```
