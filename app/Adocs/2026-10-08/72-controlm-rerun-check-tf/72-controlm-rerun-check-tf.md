# Control-M Rerun Check

## Decision tree

```
CTL-M:リラン確認 (every 4 min, last 8 hours)
 earlier status → 10-05 seq 31/37/38 and 10-07 seq 14 skipped it ("CSV only")
 new screenshot → second action "Send email" → it does notify → migrate
 what it finds → a run (order_id) that abended, then ended OK, not reported yet
   abend seen in controlm_alert in 24 h?  no → ignore
   status has "Ended not OK"?             no → ignore
   status has "Ended OK"?                 no → still failing (abend alerts cover it)
   already reported?                      Splunk: ControlmRerunHistory.csv
                                          Dynatrace: problem identity JOB_CODE (no CSV needed)
 → problem "CTL-M:リラン確認" (medium, pd 0)
 overlap → seq 71 also fires 正常終了 for the same run → keep both (Splunk does) or disable one
 email priority hidden → confirm (High → severity high)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the alert do? | Reports Control-M jobs that abended and then ended OK after a rerun. |
| Why migrate it now? | The screenshot shows a Send email action. Earlier versions thought it only wrote a CSV. |
| What replaces the history CSV? | The problem identity `JOB_CODE`. One rerun opens one problem and does not re-notify. |
| Severity | medium, assuming email priority Normal. Confirm, because the email action is collapsed. |
| PagerDuty | "0". The only notification is email. |
| Overlap | Seq 71 (ジョブ実行結果通知) also reports the same rerun as 正常終了. |

## Summary

Every 4 minutes Splunk looks at the last 8 hours of Control-M runs, finds runs that both abended and ended OK, and mails them once. It remembers what it already mailed in `ControlmRerunHistory.csv`. In Dynatrace a Records detector does the same thing without a CSV: each rerun has its own `JOB_CODE`, so it opens one problem that stays open while the run is in the 8-hour window.

## Investigation

### Splunk search, step by step

| Step | What it does |
|---|---|
| `sourcetype=controlm_activejobs NOT (*-F OR *-S)` | All job snapshots except -F and -S jobs |
| `append [inputlookup ControlmRerunHistory.csv]` | Adds runs already reported, with JOB_CODE "Rerun:..." |
| `append [search sourcetype=controlm_alert earliest=-24h]` | Adds abend events: abend_time = current_time, status = message |
| `stats ... by order_id` | One row per run, with every status it had |
| `where RerunFlag not "Rerun:"` | Drops runs already reported |
| `where status matches "Ended not OK"` | Keeps runs that abended |
| `search status IN ("Ended OK")` | Keeps runs that then ended OK |
| `JOB_CODE = "Rerun:" + job_name + abend_time` | The key for the history CSV |
| Time fields | STARTTIME, ENDTIME, ABENDTIME, AVGSTARTTIME, AVGENDTIME, AVGRUNTIME, RUNTIME, WORKTIME |
| `CMDLINE` | cmd_line, or mem_lib\memname when cmd_line is empty |
| `where isnotnull(JOB_CODE)` | Requires an abend event in the last 24 hours |

### Settings

| Setting | Value |
|---|---|
| Schedule | Cron `*/4`, last 8 hours, expires 24 hours |
| Trigger | Number of results greater than 0, once, for each result, no throttle |
| Action 1 | Output results to lookup `ControlmRerunHistory.csv`, Append |
| Action 2 | Send email. It is collapsed, so recipients and priority are not visible. |

### How it maps to Dynatrace

| Splunk part | Dynatrace equivalent |
|---|---|
| `stats ... by order_id` | `summarize ... by:{ order_id }` with `collectDistinct(status)` |
| `append controlm_alert` | `lookup [ fetch logs ... controlm_alert ... ]` on order_id |
| "Ended not OK" in status | `iAny(statuses[] == "Ended not OK" ...)` or the alert message contains it |
| "Ended OK" in status | `iAny(statuses[] == "Ended OK")` |
| History CSV | Identity `JOB_CODE`: same rerun, same problem |
| RUNTIME and WORKTIME as H:M:S | Durations (`end_ts - start_ts`). Dynatrace shows them as time spans. |

## Result

| Setting | Value |
|---|---|
| Resource | `controlm_rerun_check` |
| Window | Last 8 hours, plus a 24-hour lookback for abend events |
| Identity | `JOB_CODE` = "Rerun:" + job_name + abend_time |
| Severity | medium (confirm priority) |
| PagerDuty | "0" |

| Decision for you | Options |
|---|---|
| Overlap with seq 71 | Keep both, like Splunk. Or set `enabled = false` here if one 正常終了 problem is enough. |
| 10-05 seq 30 workflow | If applied, destroy `dynatrace_automation_workflow.controlm_rerun_check` there. |
| ControlmRerunHistory.csv | Not needed in Dynatrace. Keep it in Splunk until cut-over. |

## Data flow map

```
controlm_activejobs (8 h, not *-F / *-S)
  → one row per order_id, all statuses
  → lookup controlm_alert (24 h) → abend_time, messages
  → abended AND ended OK AND abend in 24 h?
       no  → nothing
       yes → JOB_CODE = Rerun:<job><abend_time>
             → times, durations, CMDLINE
             → problem per JOB_CODE (medium) → email route
  → run leaves the 8 h window → problem closes (no repeat, no CSV)
```

## Related files

| File | What it is |
|---|---|
| `72-controlm-rerun-check-tf.tf` | The detector |
| `72-controlm-rerun-check-tf-check.dql` | Source, fields and a 24-hour dry run |
| `72-controlm-rerun-check-tf.spl` | History CSV volume and the hidden email settings |
| `72.sh` | Commands |

## Commands

These are in `72.sh`. Nothing has been run. Run the seq 30 lines only if that workflow was applied.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/30-controlm-splunk-alerts-transform"
terraform state list
terraform plan -destroy -target='dynatrace_automation_workflow.controlm_rerun_check'
terraform destroy -target='dynatrace_automation_workflow.controlm_rerun_check'
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/72-controlm-rerun-check-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
