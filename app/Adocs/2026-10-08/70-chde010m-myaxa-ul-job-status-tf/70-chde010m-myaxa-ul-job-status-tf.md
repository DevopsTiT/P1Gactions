# CHDE010M MyAXA UL Job Status

## Decision tree

```
CHDE010MJob Status for MyAXA UL Email (Control-M, controlm_temp)
 what does Splunk do? → 11:30 Mon-Sat, mails yesterday's CHDE010M status (OK or 要確認)
 converted before?
   10-05 seq 30/31 → daily report workflow, odate compared as yyyyMMdd (wrong, raw is yyMMdd)
   10-07 seq 14    → merged into chde010m_no_success (74h lookback)
   → rebuild as its own Records detector (today's standard)
 yesterday's run Ended OK? → no problem (the OK mail is information only)
 not Ended OK, Mon-Sat, after 11:30 JST? → problem "正常終了していません要確認" (medium, pd 0)
 job did not run yesterday (not a run day)? → no rows → no problem (same as Splunk: no mail)
 seq 14 applied? → remove chde010m_no_success key
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk alert do? | At 11:30 Monday to Saturday, it emails the status of yesterday's CHDE010M run. |
| What does the Dynatrace detector do? | Opens a problem only when yesterday's run is not Ended OK. |
| Why not the OK mail? | An OK result is not a problem. A detector cannot send "all good" mails. |
| Severity | medium, because the email priority is Normal. |
| PagerDuty | "0". The only action is email. |
| Earlier versions | 10-05 seq 30/31 and 10-07 seq 14. This version replaces both for this alert. |

## Summary

CHDE010M is the Control-M batch that creates MyAXA UL data, weekly and monthly. Splunk checks it every morning and mails "OK" or "正常終了していません要確認" (not ended normally, please check). The detector keeps only the check part. It runs every minute but only judges Monday to Saturday from 11:30 JST, so it never fires while the job is still allowed to be running.

## Investigation

### Splunk settings

| Setting | Value |
|---|---|
| Search | `index=controlm_temp sourcetype=controlm_activejobs job_name=CHDE010M` |
| Dedup | `dedup odate`, which keeps the latest record per order date |
| Time formatting | StartTime and EndTime become `MM/dd HH:mm:ss` |
| Message | MSG is "OK" when status is "Ended OK", otherwise "正常終了していません要確認" |
| Date filter | OrderDate equals yesterday |
| Schedule | Cron `30 11 * * 1-6`, which is 11:30 Monday to Saturday, looking at the last 1 day |
| Trigger | Number of results greater than 0, once, for each result, no throttle |
| Action | Send email, priority Normal, subject `$name$ $result.MSG$`. I did not copy the recipients. |
| Email body | Data is created weekly on the day after the first business day of the week (11:00), and monthly on the day after the first business day of the month. |

### How each part maps to Dynatrace

| Splunk part | Dynatrace equivalent |
|---|---|
| `job_name=CHDE010M` | `filter job_name == "CHDE010M"` |
| `dedup odate` | `sort timestamp asc`, then `summarize takeLast(...) by job_name, odate` |
| `strptime(odate,"%y%m%d")` | `odate` is 6 digits, so compare with `formatTimestamp(now() - 1d, format:"yyMMdd")` |
| `where OrderDate = WKday` | `filter odate == yesterday` |
| `MSG = case(...)` | `filter status != "Ended OK"`, then MSG is "正常終了していません要確認" |
| Cron 11:30 Monday to Saturday | Time gate: JST time is 11:30 or later, and day of week is 6 or less |
| Priority Normal | `alert.severity` medium |

### The odate bug in 10-05

| Version | odate compare | Result |
|---|---|---|
| 10-05 seq 30/31 | `yyyyMMdd`, for example 20261007 | Never matches a 6-digit odate |
| 10-08 seq 70 | `yyMMdd`, for example 261007 | Matches |

## Result

| Setting | Value |
|---|---|
| Resource | `chde010m_myaxa_ul_job_status` |
| Window | Last 1 day |
| Fires when | Yesterday's CHDE010M order is not Ended OK, Monday to Saturday from 11:30 JST |
| Identity | `job_name` and `odate`, so each order date is its own problem |
| Closes | When a rerun ends OK, or at midnight JST when "yesterday" moves on |
| Severity | medium |
| PagerDuty | "0" |

Check before apply:

| Item | Why it matters |
|---|---|
| log.source | `*controlm_activejobs*` is the same guess as seq 13. Query 1 shows the real value. |
| odate length | Query 2 should show 6 digits. If it shows 8, change the format to `yyyyMMdd`. |
| Day of week | Query 4 shows `jst_day_of_week`. Monday should be 1 and Sunday 7. |
| Old versions | Remove `chde010m_no_success` from 10-07 seq 14 if it was applied, or you get two alerts for one failure. |

## Data flow map

```
Control-M → controlm_activejobs log (job_name, status, odate, start_time, end_time)
  → CHDE010M only → yesterday's odate only → latest record per odate
  → Mon-Sat and JST >= 11:30?
       no  → nothing
       yes → status Ended OK?  yes → nothing
                               no  → problem "正常終了していません要確認" (medium) → email route
  → rerun ends OK or midnight JST → problem closes
```

## Related files

| File | What it is |
|---|---|
| `70-chde010m-myaxa-ul-job-status-tf.tf` | The detector |
| `70-chde010m-myaxa-ul-job-status-tf-check.dql` | Log source, field shape, dry run and time gate checks |
| `70-chde010m-myaxa-ul-job-status-tf.spl` | Splunk side: per-odate status and field lengths |
| `70.sh` | Commands |

## Commands

These are in `70.sh`. Nothing has been run. Run the seq 14 lines only if that file was applied. Remove the `chde010m_no_success` key there by hand first.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/14-controlm-records-detectors-reevaluate"
terraform state list
terraform plan
terraform apply
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/70-chde010m-myaxa-ul-job-status-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
