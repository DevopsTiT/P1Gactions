# PDDW0100 Claims Status

## Decision tree

```
Claims Status Service PDDW0100 Status (08:15 daily, last 24 h, priority Highest)
 what does Splunk send? → completion-time report of PDDW runs that ended OK
 what is the action item? → a PDDW run that has NOT ended OK by 08:15
 earlier versions
   10-05 seq 31 → daily report workflow (no detector)
   10-07 seq 14 → pddw_no_success: fires only if NO PDDW job ended OK (misses single failures)
   → rebuild: one problem per run (odate + order_id) whose latest snapshot is not Ended OK
 time gate → judged from 08:15 JST to midnight
 PDDW job that normally ends after 08:15? → check query 4 → exclude by exec_time
 seq 14 applied? → remove pddw_no_success key
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk alert do? | Every day at 08:15 it emails the completion times of PDDW claims jobs. |
| What does the detector do? | Opens a problem for each PDDW run that has not ended OK by 08:15. |
| Why not copy the report? | A report of successes is information. A detector should fire on the run that did not finish. |
| Severity | high, because the email priority is Highest. |
| PagerDuty | "0". The only action is email. |
| What it replaces | 10-07 seq 14 `pddw_no_success` and the 10-05 seq 31 report workflow |

## Summary

PDDW is the overnight claims batch, and the business team wants to know by 08:15 that it finished. Splunk mails the list of finished runs. The detector looks at the same runs, keeps the latest snapshot of each, and opens a problem for any run that is not "Ended OK" from 08:15 onwards. It closes by itself when the run ends OK.

## Investigation

### Splunk settings

| Setting | Value |
|---|---|
| Search | `controlm_activejobs`, job names starting PDDW, excluding -S, -F and TEST001 |
| Latest snapshot | `eventstats max(current_time) by odate,order_id`, keep where current_time is the max |
| Filter | status = "Ended OK" |
| Lookup 1 | `controlm_avg_run_info_lookup.csv` by job_name (average run info) |
| Lookup 2 | `claims_job_list.csv job_id as job_name`, output exec_time, exec_no, app_name, processing, job_name_jp |
| Output | JOB, 起動日 (start date), StartTime, EndTime, sorted by start time |
| Schedule | Cron `15 8 * * *`, which is 08:15 every day, looking at the last 24 hours |
| Expires | 1 hour |
| Action | Send email, priority Highest, inline table. I did not copy the recipients. |
| Message | "担当各位 PDDWの完了時刻のレポートを送信致します。", then a note about runs that have not finished |

### What the earlier versions missed

| Version | What it did | Gap |
|---|---|---|
| 10-05 seq 31 | Daily report workflow | Not a detector. Matched the claims list on job_name instead of job_id. |
| 10-07 seq 14 | `pddw_no_success` | Fires only when no PDDW job at all ended OK, so one failed job out of many is missed. |
| 10-08 seq 73 | Per-run detector | Latest snapshot per run, claims list keyed on job_id, priority Highest mapped to high |

### How it maps to Dynatrace

| Splunk part | Dynatrace equivalent |
|---|---|
| `eventstats max(current_time) by odate,order_id` then `where current_time = max_time` | `sort current_time asc`, then `summarize takeLast(...)` by odate and order_id |
| `status="Ended OK"` (report) | `status != "Ended OK"` (alert on the opposite) |
| `lookup claims_job_list.csv job_id as job_name` | `lookup ... lookupField:job_id` |
| Cron 08:15 | Time gate: Japan time is 08:15 or later |
| Priority Highest | `alert.severity` high |

## Result

| Setting | Value |
|---|---|
| Resource | `pddw0100_claims_status` |
| Window | Last 24 hours |
| Identity | `odate` and `order_id`, so one problem per run |
| Fires when | The latest snapshot of a PDDW run is not Ended OK, from 08:15 JST |
| Closes | When the run ends OK, or when it leaves the 24-hour window |
| Severity | high |
| PagerDuty | "0" |

Check before apply:

| Item | Why it matters |
|---|---|
| Query 4: runs ending after 08:15 | A PDDW job that normally runs later in the day would be flagged every morning. Exclude it with `cjl.exec_time` once you know the format. |
| Claims job list lookup | Must be uploaded with `job_id` and `job_name_jp`, or 処理 will be empty. |
| Average run info lookup | Not used. Splunk loads it, but no column from it reaches the email table. |
| 10-07 seq 14 | Remove `pddw_no_success` (and `chde010m_no_success`, see seq 70) if that file was applied. |

## Data flow map

```
Control-M → controlm_activejobs snapshots (PDDW*, not -S / -F / TEST001, last 24 h)
  → latest snapshot per odate + order_id
  → JST >= 08:15?
       no  → nothing
       yes → status Ended OK?  yes → nothing (this is what Splunk lists in the report)
                               no  → lookup claims_job_list (job_id) → 処理, exec_time
                                     → problem per run (high) → email route
  → run ends OK → problem closes
```

## Related files

| File | What it is |
|---|---|
| `73-pddw0100-claims-status-tf.tf` | The detector |
| `73-pddw0100-claims-status-tf-check.dql` | Source, snapshot fields, claims list and end-time checks |
| `73-pddw0100-claims-status-tf.spl` | Splunk side: latest status, end times and lookups |
| `73.sh` | Commands |

## Commands

These are in `73.sh`. Nothing has been run. Run the seq 14 lines only if it was applied. Remove `pddw_no_success` from that file by hand first.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/14-controlm-records-detectors-reevaluate"
terraform state list
terraform plan
terraform apply
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/73-pddw0100-claims-status-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
