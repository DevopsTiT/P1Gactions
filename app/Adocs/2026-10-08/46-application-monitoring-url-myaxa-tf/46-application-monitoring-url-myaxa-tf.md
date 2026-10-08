# URL Monitoring For MyAXA

## Decision tree

```
Application Monitoring Alert - URL for MyAXA
 sourcetype="text:jenkins" exists? → no (seq 45) → Splunk alert dead → has never paged
 Dynatrace detector → enabled = false, pagerduty "1"
 Splunk filters to MyAXA? → no (title only) → detector adds application == "MyAXA" (because it pages)
 before enabling:
   "[HTTP Monitor]" lines with job_result? no → keep off
   yes → which MyAXA jobs would fire now? few and real → enable | many → fix first
 should it cover all apps? → team confirms → remove the MyAXA filter line
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | A MyAXA URL check job had 2 or more non-OK results in 15 minutes with no OK. |
| How is it different from the plain URL alert? | It judges by `job_result` containing "OK", fires on 2 runs (`event=2`), and pages. |
| Does the Splunk alert work? | No. It uses the missing `text:jenkins` sourcetype, so it has never matched. |
| PagerDuty | "1", because PagerDuty Enable is visible. The URL was not copied. |
| Shipped state | `enabled = false`, so you check before turning it on. |

## Summary

This is the MyAXA, paging version of the URL alert. It looks at job_result rather than the HTTP code and opens a problem when both recent runs are not OK. It has the same dead sourcetype as seq 45, so it has never paged. The Dynatrace detector ships switched off with `pagerduty.enabled = "1"`. It also adds a MyAXA filter that the Splunk search lacks, so turning it on cannot page for every application.

## Investigation

| What I checked | What I found |
|---|---|
| Sourcetype | `text:jenkins`, which is not in the index (seq 45 screenshot). |
| Name and build URL | The same cleanup as the URL alert. |
| Result field | `list(job_result)`, and OK if any value matches "OK". |
| NG rule | `event=2`, meaning both of the last 2 runs are in the window, and no OK. |
| Application filter | None in the search, even though the title says MyAXA. |
| Time range and cron | Last 15 minutes, every minute. |
| Action | Alert Status Manager, Production, PagerDuty Enable. I did not copy the URL or recipients. |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_url_myaxa` |
| enabled | false |
| Result parse | `LD 'job_result=' WORD:job_result`, which needs to be confirmed |
| Added filter | `cfg.application == "MyAXA"` |
| Fires when | `fails >= 2 and oks == 0` |
| Severity | high |
| pagerduty.enabled | "1" |

### Why the MyAXA filter was added

| Option | What happens |
|---|---|
| Faithful (no filter) | When enabled, it pages for every application in the configuration lookup. |
| With the MyAXA filter (shipped) | It only pages for MyAXA jobs, which matches the alert title. |

## Data flow map

```
Splunk: sourcetype=text:jenkins → 0 events → never paged
Dynatrace: Jenkins console (ceaa2099) → "[HTTP Monitor]" → job_result
  → lookup configuration → application == "MyAXA"
  → per job: fails >= 2, oks == 0 → problem (high, PagerDuty)   [disabled until checked]
  → next OK → closes
```

## Related files

| File | What it is |
|---|---|
| `46-application-monitoring-url-myaxa-tf.tf` | The detector, disabled |
| `46-application-monitoring-url-myaxa-tf-check.dql` | Line format, MyAXA lookup rows, and what would fire now |
| `46-application-monitoring-url-myaxa-tf.spl` | Sourcetype proof, scheduler result count, and lookup rows |
| `46.sh` | Commands |

## Commands

These are in `46.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/46-application-monitoring-url-myaxa-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
