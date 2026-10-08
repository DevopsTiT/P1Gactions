# Application Monitoring Alert Function

## Decision tree

```
Application Monitoring Alert - function
 which jobs count? → Functional (applications*) results; Real Time results are emptied
 which apps? → every app with pager_duty = "0" in configuration (no single app filter)
 Functional job: 2+ non-SUCCESS in 2h and no SUCCESS?
   → yes → problem per application + job
          → remarks has "Application is in mantenance"? → planned maintenance, ack and wait
          → no remarks → real failure → check the Jenkins build console
   → no → healthy (closes on next SUCCESS)
 app has pager_duty = "1"? → not covered here → its own per-app detector pages instead
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | A Functional Jenkins job returned 2 or more non-SUCCESS results in 2 hours, with no SUCCESS. |
| Which applications? | Every application whose `pager_duty` is "0" in the configuration lookup. |
| How is it different from the per-app alerts? | It counts Functional results instead of Real Time results, and it is a catch-all for non-paging apps. |
| Maintenance? | Maintenance notes come from jenkins_console logs, joined by build URL. They are shown on the problem but not filtered out, the same as in Splunk. |
| Severity and PagerDuty | high (Alert Status Manager, Production) and "0", because these apps do not page. |

## Summary

This is the catch-all Functional check for every application that does not use PagerDuty. Splunk empties the Real Time results, so only Functional job results decide OK or NG. It also joins a maintenance message from the Jenkins console log. The Dynatrace detector does the same with a second `lookup` on a console log subquery, and opens one problem per application and job.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | The same jenkins_statistics template as seq 26 and seq 30 to 33. |
| `eval job_result` | Reversed: it empties `group-jobs` (Real Time) results, so Functional results count. |
| Application filter | None. It uses `where pager_duty="0"` instead. |
| `join type=left build_url` | Pulls "Application is in mantenance" lines from `index=jenkins_console`, keyed by the build URL (the console source without the trailing `console`). |
| Spelling | Splunk searches for "mantenance", which is a typo of maintenance. I kept the same spelling, because the console text must match it. |
| Time range | Last 120 minutes. |
| Cron | `*/1`, every minute. |
| Action | Alert Status Manager, email Production. |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_function` |
| Query window | `from:now()-120m` |
| Counts | `fn_fails` and `fn_oks` from Functional jobs only |
| Fires when | `fn_fails >= 2 and fn_oks == 0` |
| Identity | application and name |
| Maintenance fields | `in_maintenance` (count) and `remarks` (console text) |
| Severity | high |
| pagerduty.enabled | "0" |

Things to confirm:

| Check | Why |
|---|---|
| Build events carry `build_url` (query 1) | Without it, the maintenance lookup never matches. The alert still works, but `remarks` stays empty. |
| Console lines reach Grail (query 2) | If jenkins_console is not ingested, remove the console `lookup` block. |
| Which apps have pager_duty "0" (query 3) | Shows you how many apps this one detector covers. |

If you would rather not be alerted during maintenance, add `| filter in_maintenance == 0` at the end of the query.

## Data flow map

```
Jenkins (ceaa2099)
  ├─ jenkins_statistics build events (job_result, build_url)
  └─ jenkins_console "Application is in mantenance" lines (source = job/.../console)
        → build_url = source without "console"
  → lookup console note by build_url
  → lookup configuration → keep pager_duty == "0"
  → summarize per application + job: fn_fails, fn_oks, in_maintenance
  → fn_fails >= 2 and fn_oks == 0 → Davis problem (high, no page)
  → next SUCCESS → problem closes
```

## Related files

| File | What it is |
|---|---|
| `36-application-monitoring-alert-function-tf.tf` | The detector |
| `36-application-monitoring-alert-function-tf-check.dql` | Checks for build_url, console lines and pager_duty apps |
| `36-application-monitoring-alert-function-tf.spl` | The same checks in Splunk |
| `36.sh` | Commands |

## Commands

These are in `36.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/36-application-monitoring-alert-function-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
