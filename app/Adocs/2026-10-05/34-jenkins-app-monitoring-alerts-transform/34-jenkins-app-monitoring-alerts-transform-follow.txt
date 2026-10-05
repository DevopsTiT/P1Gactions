# Jenkins App Monitoring Alerts Transform

## Decision tree

```
10 Splunk "Application Monitoring Alert" variants (Jenkins checks)
 what do they share?
   last 2 results per check (streamstats index<=2)
   alert when both NG, send recovery when OK follows NG
   Alert Status Manager → email + PagerDuty per app
 → that is a Dynatrace problem: open on failure, close on recovery
 two kinds of check
   URL check ([HTTP Monitor], response code)       → detector 1, split by application + check
   functional test (jenkins/test, testcase status) → detector 2, split by application + test
 8 function alerts differ only by application name → one detector, split by application
 per-app PagerDuty keys                            → not copied; standard flow + pagerduty.enabled property
 maintenance (check_maintenance_window macro)      → need the macro, then Dynatrace maintenance windows
```

## Short takeaway

| Question | Answer |
|---|---|
| How many Dynatrace resources? | 2 detectors replace all 10 Splunk alerts |
| Why so few? | The 8 "function for X" alerts are the same search with a different `application` filter |
| How is "2 failures in a row" kept? | In the look-back window (15 minutes for URL, 2 hours for functional), at least 2 failed runs and no OK run |
| How does recovery work? | The first OK run closes the problem, like Splunk's "OK after NG" email |
| PagerDuty | Keys seen in the screenshots were not copied. Paging goes through the standard flow, with a `pagerduty.enabled` property for apps that should not page |
| Biggest unknowns | Two Splunk macros (`check_maintenance_window`, `add_alert_info`) and the "configuration" lookup |

## Summary

All ten alerts are one idea: a Jenkins check (URL or functional test) failed twice in a row, so alert, and when it passes again, send a recovery. Splunk needed streamstats, a state macro and the Alert Status Manager app to do that. A Dynatrace detector does it natively, so two detectors (URL checks and functional tests), split by application, replace all ten.

## Mapping

| # | Splunk alert | Application filter | PagerDuty in Splunk | Dynatrace |
|---|---|---|---|---|
| 1 | Application Monitoring Alert - URL | none | Disabled | URL detector |
| 2 | Application Monitoring Alert - URL for MyAXA | none visible | Enabled | URL detector |
| 3 | Application Monitoring Alert - function | apps with pager_duty = 0 | Disabled | Functional detector |
| 4 | ... - function for AG Portal | AG Portal NTTGW | Enabled | Functional detector |
| 5 | ... - function for BancaPotal | Banca Portal | Enabled | Functional detector |
| 6 | ... - function for Cockpit360 | Cockpit360 | Enabled | Functional detector |
| 7 | ... - function for Compass | Compass | Enabled | Functional detector |
| 8 | ... - function for Compass PB | Compass AG | Enabled | Functional detector |
| 9 | ... - function for FCR | FCR | Enabled | Functional detector |
| 10 | ... - function for ICM | Claims ICM | Enabled (cron every 3 minutes) | Functional detector |

## How the Splunk logic maps

| Splunk step | What it does | Dynatrace |
|---|---|---|
| `job_result!=ABORTED job_result!=FAILURE` | Ignore broken builds; only judge real test results | Same filter |
| `rename testsuite.testcase{}.status as teststatus` | One status per test case | `parse content, "JSON:j"` then `expand tc = j[testsuite][testcase]` |
| Rename "Real Time Check" jobs to the Functional path | Treat both job types as one check | `replaceString(...)` on job_name |
| `lookup configuration ... OUTPUT application, pager_duty` | Map job to application and paging flag | `lookup [ load "/lookups/jenkins/configuration" ]` |
| `streamstats count by name, where index<=2` | Keep the last 2 results | Look-back window: at least 2 failed runs and no OK run |
| `status=if(mvcount(mvfilter(match(...,"OK")))>0,"OK","NG")` | NG only if none of the last results passed | `ok_n == 0` |
| `search event=2 OR (status="OK" AND prev_status="NG")` | Alert on 2 NG, recover on OK after NG | Problem opens on `consecutive_ng = 1`, closes when it drops to 0 |
| `add_alert_info` macro | Remembers the previous status | Not needed; the open problem is the state |
| Alert Status Manager | Sends email and PagerDuty per app | Standard SILVA and PagerDuty flow |
| `check_maintenance_window` macro | Suppresses alerts during maintenance | Dynatrace maintenance window (needs the macro definition) |

## The core of each detector

```
| makeTimeseries fail = sum(failed, default: 0), ok = sum(1 - failed, default: 0),
                 by:{ application, testname, pager_duty }, interval:1m
| fieldsAdd fail_n = arrayMovingSum(fail, 120), ok_n = arrayMovingSum(ok, 120)
| fieldsAdd consecutive_ng = if(fail_n[] >= 2 and ok_n[] == 0, 1, else: 0)
```

Threshold 0, violating 1, dealerting 1. The URL detector uses a 15-minute window, the functional detector 120 minutes, matching the Splunk time ranges. `fail_n[]` is a DQL iterative expression: it checks every minute in the series.

Full file: `34-jenkins-app-monitoring-alerts-transform.tf`.

## Issues found in the Splunk alerts

| Issue | What it means |
|---|---|
| 8 copies of one search | Any fix must be made 8 times; they have already drifted (Compass has an extra メンテナンス中 rex, ICM runs every 3 minutes) |
| URL and URL for MyAXA look at the same checks | One emails on a single failure, the other pages on two. The same outage can produce both |
| URL alert fires on one failure | No "two in a row" protection, so one slow response alerts |
| 2-hour search every minute | Heavy: each minute re-reads 2 hours of Jenkins logs for 8 alerts |
| PagerDuty keys typed into each alert | Keys are visible to anyone who can edit the alert. Not copied here |
| State kept by a macro | Logic is hidden in `add_alert_info`; nobody can see it from the alert |
| "function" reads `json:jenkins:old` | An old data format. It may no longer be written |

## Decisions and asks

| Item | Why |
|---|---|
| Send the two macro definitions (Settings, Advanced search, Search macros) | Needed to rebuild maintenance handling exactly |
| Export the "configuration" lookup as CSV | Becomes `/lookups/jenkins/configuration` with job_name, application, pager_duty |
| Add a rule to the standard flow: skip PagerDuty when `pagerduty.enabled` is 0 | Keeps today's behaviour for apps that only email. Do it in a new flow version, not in old folders |
| Add an application-to-SILVA-group fallback in the standard flow | These problems have no host tags, so routing needs `app.name` |
| Confirm run frequency (check.dql query 4) | The 2-hour window must hold at least 2 runs |

## Data flow

```
Jenkins jobs (URL monitors, functional tests) → console logs + jenkins/test JSON → Grail
   → detector (every minute, per application + check)
        2 failed runs, no OK in window → problem opens (app.name, pagerduty.enabled)
        first OK run                   → problem closes (recovery)
   → standard flow → SILVA ticket + PagerDuty (skip when pagerduty.enabled = 0)
configuration CSV → /lookups/jenkins/configuration → application + pager_duty
```

## Investigation

| Screenshots | Alert | Range and schedule | Action |
|---|---|---|---|
| 1 and 2 | URL | Last 15 min, every minute | Alert Status Manager, email production, PagerDuty disabled |
| 3 and 4 | URL for MyAXA | Last 15 min, every minute | Alert Status Manager, PagerDuty enabled with key |
| 5 to 7 | function | Last 120 min, every minute, `pager_duty="0"` | Alert Status Manager, PagerDuty disabled |
| 8 to 10 | function for AG Portal | Last 2 hours, every minute | PagerDuty enabled with key |
| 11 to 13 | function for BancaPotal | Last 2 hours, every minute | PagerDuty enabled with key |
| 14 to 16 | function for Cockpit360 | Last 2 hours, every minute | PagerDuty enabled with key |
| 17 to 19 | function for Compass | Last 2 hours, every minute, extra メンテナンス中 rex | PagerDuty enabled with key |
| 20 to 22 | function for Compass PB | Last 2 hours, every minute, application Compass AG | PagerDuty enabled with key |
| 23 to 25 | function for FCR | Last 2 hours, every minute | PagerDuty enabled with key |
| 26 to 28 | function for ICM | Last 2 hours, every 3 minutes, application Claims ICM | PagerDuty enabled with key |

Debug recipients seen: application services open info list, an aog oo list and an aog to list. PagerDuty keys were not copied.

## Result

| Step | Action |
|---|---|
| 1 | Run `check.dql` queries 1 to 3 and fix the source filters and the two parse patterns |
| 2 | Upload the configuration lookup, then run query 5 |
| 3 | Run query 4 to confirm run frequency fits the windows |
| 4 | Run query 6; if the old source is alive, add it to the functional query |
| 5 | Open each detector in the Anomaly Detection app and use the preview to confirm it opens on two failures and closes on one OK |
| 6 | Plan the standard-flow changes (skip by `pagerduty.enabled`, route by `app.name`) |
| 7 | `terraform plan` should show 2 detectors |

## Related files

| File | Purpose |
|---|---|
| `34-jenkins-app-monitoring-alerts-transform.tf` | 2 detectors |
| `34-jenkins-app-monitoring-alerts-transform-check.dql` | Source, format, frequency, lookup and dry-run checks |
| `34.sh` | Commands |

## Commands

See `34.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
