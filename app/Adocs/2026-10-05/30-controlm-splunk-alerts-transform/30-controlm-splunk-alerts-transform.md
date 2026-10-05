# Control-M Splunk Alerts Transform

## Decision tree

```
9 Control-M Splunk alerts (11 screenshots)
 what does each one deliver?
   a status table once a day          → scheduled workflow (4 reports, one for_each resource)
   "a job ended not OK" right now     → detector, one problem per job (V1 + V2 merged)
   one email per job with contact CC  → workflow with a loop (ジョブ実行結果通知)
   "abend then rerun OK" list         → workflow (リラン確認), overlaps with ジョブ実行結果通知
   "job running 15+ minutes"          → workflow every 5 minutes (Claim Job Over Run)
 Splunk used CSV lookups?             → upload them as Grail lookup files, use load + lookup
 Splunk used overlapping windows + throttle to avoid repeats?
   → use "first seen in the last slot" so each event is reported exactly once
 fields are Splunk extractions?       → check.dql query 2, add a parse step if they are only in content
```

## Short takeaway

| Question | Answer |
|---|---|
| How many Dynatrace resources? | 1 detector and 7 workflows (4 daily reports share one `for_each` resource) |
| Why workflows this time? | Most of these alerts are reports or per-job emails. A detector cannot email a table or per-job contacts |
| Which ones were merged? | アベンドアラート V1 and V2 run the same search, so they became one detector |
| Biggest risk | Control-M fields (job_name, status, start_time and so on) may not exist as fields in Dynatrace yet |
| Biggest Splunk bug | Claim Job Over Run groups by job name, so a new run can be missed, and it compares minutes with the text "15" |
| What needs uploading | Five CSV files as Grail lookup data |

## Summary

These nine alerts fall into four shapes: daily status reports, a real-time abend alert, per-job result emails, and an overrun check. Only the abend alert is a true "something is broken now" signal, so it becomes a detector that opens one problem per failed job. Everything else is an email workflow. Splunk's CSV lookups move to Grail lookup files, and the repeated-email tricks (overlapping windows plus throttle) are replaced by "report each job end exactly once".

## Mapping

| # | Splunk alert | What it does | Dynatrace |
|---|---|---|---|
| 1 | CH:UL Email Job status | CHDE010M status today, 13:00 Tue to Sat | `controlm_daily_report["chde010m_ul_today"]` |
| 2 | CHDE010MJob Status for MyAXA UL Email | CHDE010M status for yesterday's order date, OK or 要確認, 11:30 Mon to Sat | `controlm_daily_report["chde010m_myaxa_ul"]` |
| 3 | CHDR010MJob Status for MyAXA User Registration Batch | CHDR010M status OK or NG, 06:00 daily | `controlm_daily_report["chdr010m_user_registration"]` |
| 4 | CTL-M アベンドアラートV2 | Any "Ended not OK" in the last 5 minutes | Merged into detector `controlm_job_abend` |
| 5 | CTL-M:アベンドアラート | Same search plus CSV contact lookups | Merged into detector `controlm_job_abend` |
| 6 | CTL-M:ジョブ実行結果通知 | One email per abended job when it ends, CC from contact CSV | Workflow `controlm_job_result_notify` with a loop |
| 7 | CTL-M:リラン確認 | Jobs that abended and then ended OK after rerun | Workflow `controlm_rerun_check` |
| 8 | Claim Job Over Run Alert | Claims job running 15+ minutes | Workflow `claims_job_overrun` |
| 9 | Claims Status Service PDDW0100 Status | PDDW jobs that ended OK, 08:15 daily | `controlm_daily_report["pddw0100_claims_status"]` |

## Issues found in the Splunk alerts

| Alert | Issue | What it means |
|---|---|---|
| 1 | Throttle on JOB_CODE for 6 minutes | Does nothing for a job that runs once a day |
| 1 | No dedup | Every Control-M snapshot line is emailed, so the same run can appear many times |
| 1 and 2 | Same job, two reports | CHDE010M is reported twice a day to different lists. Could be one report |
| 2, 3 and 9 | Silent when the job did not run | No row means no email, which looks the same as a quiet day |
| 4 and 5 | Same search twice | Every abend can be emailed twice |
| 4, 5 and 6 | 5-minute window checked every minute | Each event is seen five times; only the throttle hides it |
| 6 and 7 | Both report "abend then OK" | The same recovery can be emailed by two alerts |
| 7 | Uses a CSV as "already reported" memory | That state does not move to Dynatrace; the workflow uses time slots instead |
| 8 | Groups by job_name, not by run | If yesterday's run has an end time, today's stuck run is missed |
| 8 | `where elapsed>="15"` | Compares with the text "15" instead of the number 15 |
| 8 | No throttle | Emails every 5 minutes for as long as the job is stuck |
| All | Description "Optional" on most | Nobody wrote what the alert is for |

## How the tricky parts work

### Daily reports (1, 2, 3, 9)

One resource with `for_each` over a map. Each entry has its own title, cron, recipients, query and the line format for the email. The email lists one row per record and is skipped when there are no rows (same as Splunk "results > 0").

| Splunk | DQL |
|---|---|
| `dedup odate` after the newest event | `sort timestamp desc` then `dedup odate` |
| `eventstats max(current_time) by odate, order_id` then keep the max | `sort timestamp desc` then `dedup odate, order_id` (latest snapshot per run) |
| `substr(start_time,5,2)` (1-based) | `substring(start_time, from:4, to:6)` (0-based) |
| `case(status="Ended OK","OK",true(),"NG")` | `if(status == "Ended OK", "OK", else:"NG")` |
| `strftime(relative_time(now(),"-1d"),"%Y%m%d")` | `formatTimestamp(now() - 1d, format:"yyyyMMdd", timezone:"Asia/Tokyo")` |
| "Today" at 13:00 | `from:now()-13h` |

### Abend detector (4 and 5)

```
fetch logs
| filter matchesValue(log.source, "*controlm_alert*")      // CONFIRM
| filter lower(message) == "ended not ok"
| makeTimeseries count = count(default: 0), by:{ job_name }, interval:1m
```

Threshold 0, any line opens a problem, one problem per `job_name`, closes after 10 quiet minutes (like the old throttle). It goes through the standard SILVA and PagerDuty flow, so two decisions are needed:

| Decision | Why |
|---|---|
| Should every abend page someone? | Splunk only emailed (the action is not visible in the screenshots). If not, make it a workflow instead |
| How is it routed? | Log-based problems have no host tags, so the standard flow cannot find the SILVA group (same gap as earlier alerts) |

### Per-job result emails (6)

- Each job end is picked up once: the first snapshot that shows the end must fall between 6 and 1 minutes ago, and the workflow runs every 5 minutes. No throttle needed.
- `lookup [ fetch ... controlm_alert ... ]` replaces Splunk's `join` with the alert search. Only jobs with an abend in the last 24 hours are kept (Splunk's `where message!=""`).
- TITLE and BODY are rebuilt in Japanese exactly like Splunk.
- `with_items` runs the email task once per record. To is the fixed person plus the job's contact Email from the CSV.

### Rerun check (7)

Same "first seen" idea: the first Ended OK snapshot must fall in the last 4-minute slot, and the run must have an abend in the last 24 hours. Splunk's runtime and average-runtime columns are left out to keep it readable; add them later if anyone uses them.

### Claim job overrun (8)

Groups by run (`order_id`), keeps runs with no end time, and emails only when the run crosses 15 minutes (first seen 15 to 20 minutes ago). One email per stuck run instead of one every 5 minutes. "First seen" is the first Control-M snapshot of the run, which avoids parsing the JST start_time text into a timestamp.

### CSV lookups

| Splunk CSV | Grail lookup file | Used for |
|---|---|---|
| controlm_addresslist.csv | `/lookups/controlm/addresslist` | Method (対応方法) |
| controlm_job_Definition.csv | `/lookups/controlm/job_definition` | mem_lib, cmd_line, memname, node_id, host |
| controlm_SpecificContact.csv | `/lookups/controlm/specific_contact` | Email (per-job CC) |
| claims_jobs.csv | `/lookups/controlm/claims_jobs` | Which jobs are claims jobs |
| claims_job_list.csv | `/lookups/controlm/claims_job_list` | job_name_jp (処理) |

Upload in Dynatrace: Settings, Lookup data, Upload. Set the lookup field to `job_name`. ControlmRerunHistory.csv and controlm_avg_run_info_lookup.csv are not needed.

## Data flow

```
Control-M → activejobs snapshots + alert events → Grail
   ├─ alert "Ended not OK" → detector (per job) → problem → standard flow → SILVA + PagerDuty
   ├─ daily cron → report workflow → table email (skip if empty)
   ├─ every 5 min → job_result_notify → first end in slot? + abend in 24h? → 1 email per job (To + contact CC)
   ├─ every 4 min → rerun_check → first OK in slot? + abend in 24h? → list email
   └─ every 5 min → claims_job_overrun → run open 15-20 min? → list email
lookup files (/lookups/controlm/*) → joined in by job_name
```

## Investigation

| Screenshot | Alert | Schedule | Window | Trigger and throttle | Recipients |
|---|---|---|---|---|---|
| 1 | CH:UL Email Job status | 0 13 * * 2-6 | Today | > 0, throttle JOB_CODE 6 min | noda, yasuda, one cut off |
| 2 | CHDE010MJob Status for MyAXA UL Email | 30 11 * * 1-6 | Last 1 day | > 0 | digital marketing squad, emma support |
| 3 | CHDR010MJob Status for MyAXA User Registration Batch | Every day 06:00 | Default | > 0 | Same lists, CC chen and a Teams channel |
| 4 | CTL-M アベンドアラートV2 | */1 | Last 5 min | > 0, throttle JOB_CODE 6 min | Not visible |
| 5 | CTL-M:アベンドアラート | */1 | Last 5 min | > 0, throttle $result.JOB_CODE$ | Not visible |
| 6 and 7 | CTL-M:ジョブ実行結果通知 | */1 | Last 5 min | > 0, throttle $result.JOB_CODE$ 10 min | yoshida, CC $result.Email$ |
| 8 and 9 | CTL-M:リラン確認 | */4 | Last 8 hours | > 0 | Not visible |
| 10 | Claim Job Over Run Alert | */5 | Last 24 hours | > 0, no throttle | claims incident list |
| 11 | Claims Status Service PDDW0100 Status | 15 8 * * * | Last 24 hours | > 0 | Not visible |

The Teams channel email in screenshot 3 was not copied into the file.

## Result

| Step | Action |
|---|---|
| 1 | Run `check.dql` query 1 and fix `local.cm_activejobs` and `local.cm_alert` |
| 2 | Run query 2. If job_name, status and the others are not fields, add a parse step |
| 3 | Run query 3 to see how often snapshots arrive (the "first seen" logic needs at least one every few minutes) |
| 4 | Upload the five CSV files as lookup data, then run query 5 |
| 5 | Fill in every `CONFIRM` email address |
| 6 | Decide: should abends page through the standard flow, or only email? |
| 7 | Decide: keep リラン確認, or let ジョブ実行結果通知 cover recoveries? |
| 8 | `terraform plan` should show 1 detector and 7 workflows |
| 9 | Run each workflow once by hand, check the emails, then disable the Splunk alerts |

## Related files

| File | Purpose |
|---|---|
| `30-controlm-splunk-alerts-transform.tf` | Detector and workflows |
| `30-controlm-splunk-alerts-transform-check.dql` | Source, field, snapshot, abend volume and lookup checks |
| `30.sh` | Commands |

## Commands

See `30.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
