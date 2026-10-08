# Application Monitoring Alert URL

## Decision tree

```
Application Monitoring Alert - URL
 source? → jenkins_console "[HTTP Monitor]" lines (text, not JSON)
 per job (name from console path): non-200 twice in 15m and no 200?
   → yes → problem per application + job
          → open last_build console → which URL / status code
          → 5xx → app or upstream down | 4xx → URL or auth changed | timeout → network
   → no → healthy (closes on next 200)
 parse finds no status? → check line format (query 1), fix the "status=" pattern
 job runs less than twice per 15m? → widen window to 30m
 PagerDuty? → Disable in Splunk → "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | A Jenkins HTTP Monitor job returned non-200 twice in 15 minutes with no 200. |
| Where does the data come from? | `jenkins_console` text logs that contain `[HTTP Monitor]`. |
| How is the job name built? | From the console path: drop `job/`, decode `%20`, cut `/<build>/console`. |
| Which apps? | Any job found in the configuration lookup (no app filter). |
| Severity and PagerDuty | high (Alert Status Manager, Production) and "0" (PagerDuty Disable is visible). |

## Summary

This is the URL version of the Application Monitoring Alert. It reads Jenkins console output from HTTP Monitor jobs, takes the newest two runs per job, and alerts when they are not 200. The Dynatrace detector counts non-200 and 200 results per job over 15 minutes, opens a problem when there are 2 or more failures and no success, and closes on the next 200.

## Investigation

| What I checked | What I found |
|---|---|
| Index | `jenkins_console`, sourcetype `text:jenkins`, text containing `[HTTP Monitor]`. |
| Job name | Built from `source`: drop `job/`, replace `%20` with a space, remove `/<number>/console`. |
| Build URL | `source` without `/console`. |
| Response code | Splunk's auto-extracted `status` field, renamed to `responsecode`. |
| Lookup | configuration by job name, and rows with no match are dropped. |
| Window | `streamstats ... index<=2` keeps the newest 2 runs per job. |
| OK or NG | OK when the response code is 200, otherwise NG. |
| Time range and cron | Last 15 minutes, every minute. |
| Action | Alert Status Manager, email Production, PagerDuty Disable. I did not copy the recipients. |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_url` |
| Query window | `from:now()-15m` |
| Response code parse | `LD 'status=' INT:responsecode`, which needs to be confirmed |
| Fires when | `fails >= 2 and oks == 0` |
| Identity | application and name |
| Severity | high |
| pagerduty.enabled | "0" |

Things to confirm:

| Check | Why |
|---|---|
| Line format (query 1) | If the line says `status: 500` or `HTTP 500` instead of `status=500`, change the parse pattern, or the detector never fires. |
| `log.source` holds the console path | The job name comes from it. If the path is in another field, swap the field name. |
| Runs per job (query 2) | Fewer than 2 runs in 15 minutes means the rule can never reach 2 failures. Widen to 30 minutes. |

## Data flow map

```
Jenkins HTTP Monitor job → console output "[HTTP Monitor] ... status=<code>"
  → Grail (log.source = job/applications/job/.../<build>/console)
  → name = path cleaned, build_url = path without /console
  → lookup configuration (drop unknown jobs) → application
  → per application + name: fails (non-200), oks (200)
  → fails >= 2 and oks == 0 → Davis problem (high, no page)
  → next 200 → problem closes
```

## Related files

| File | What it is |
|---|---|
| `44-application-monitoring-alert-url-tf.tf` | The detector |
| `44-application-monitoring-alert-url-tf-check.dql` | Line format, runs per job, lookup rows |
| `44-application-monitoring-alert-url-tf.spl` | The same checks in Splunk |
| `44.sh` | Commands |

## Commands

These are in `44.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/44-application-monitoring-alert-url-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
