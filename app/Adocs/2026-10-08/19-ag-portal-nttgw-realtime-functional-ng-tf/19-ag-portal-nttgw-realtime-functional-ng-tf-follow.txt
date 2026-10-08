# AG Portal NTTGW Real Time And Functional NG TF

## Decision tree

```
Jenkins build_report on ceaa2099 (source jenkins/test)
  job_result ABORTED or FAILURE? -> dropped (same as Splunk)
  Real Time Check or Functional job under App-Ops-OpenOps?
    no  -> ignored
    yes -> map both to one project "name"
           -> configuration lookup: application == "AG Portal NTTGW"?
                no  -> ignored
                yes -> Real Time: 2+ non-SUCCESS and 0 SUCCESS in 30 min?
                         yes -> problem per project (high, PagerDuty on)
                         no  -> healthy; an open problem closes on the next SUCCESS
Never fires?
  -> check.dql query 1 (job_name values) and query 2 (configuration rows)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | AG Portal NTTGW Jenkins checks: the Real Time job and its Functional job. |
| When does it fire? | The Real Time job returned 2 or more non-SUCCESS results with no SUCCESS in 30 minutes. |
| Identity | `application` and `name` (the project), so one problem per project. |
| Severity | high. |
| PagerDuty | "1", because Alert Status Manager has PagerDuty Enable. URL not copied. |
| Recovery mail | Not needed. Dynatrace closes the problem on the next SUCCESS. |
| Data source | Host ceaa2099.prprivmgmt.intraxa, source jenkins/test, sourcetype jenkins:build_report (from your screenshot). |

## Summary

Splunk joins each Real Time Check run with its Functional job under one project name, keeps the last 2 runs, and sends NG when no SUCCESS is left, plus an OK mail when it recovers. The Dynatrace detector does the same grouping, counts Real Time results in the 30-minute window, and opens a problem when there are 2 or more NG results and no SUCCESS. Dynatrace closes the problem by itself when a SUCCESS arrives.

## Splunk to Dynatrace mapping

| Splunk piece | What it means | Dynatrace |
|---|---|---|
| `index="jenkins" source="jenkins/test"` | Jenkins build reports | `matchesValue(host.name, "ceaa2099*")`, `parse content, "JSON:j"` |
| `job_result!=ABORTED job_result!=FAILURE` | Drop aborted and failed builds | `filter job_result != "ABORTED" and job_result != "FAILURE"` |
| Functional job: job_result emptied | Functional runs don't decide OK or NG | `is_functional` rows are counted only as `functional_runs` |
| Real Time job: renamed to the Functional project | Both kinds share one name | `project = replaceString(..., "Real Time Check/", "Functional/")` |
| `name` without `job/`, `%20` and trailing `/` | Clean project name | Same `replaceString` and `substring` steps |
| `lookup configuration`, application "AG Portal NTTGW" | Only this application | `lookup /lookups/jenkins/configuration`, `filter cfg.application == "AG Portal NTTGW"` |
| `streamstats ... where index<=2` | Last 2 runs | 2 or more NG in the 30-minute window |
| `status = OK if any SUCCESS, else NG` | Any SUCCESS means healthy | `rt_oks == 0` |
| `search event=2 OR (status=OK AND prev_status=NG)` | NG mail, or recovery mail | Problem opens on NG; closes on SUCCESS |
| `check_maintenance_window`, `add_alert_info` | Splunk macros | Not migrated; `.spl` prints their definitions |
| Last 30 minutes, cron */30 | Every 30 minutes | `from:now()-30m`; detector runs every minute |
| Alert Status Manager, PagerDuty Enable | Pages on NG | `pagerduty.enabled = "1"`, severity high |

## What is not migrated

| Item | Why | What to do |
|---|---|---|
| Failed Functional test names | `testsuite.testcase{}` is an array; expanding it would break the counts | Look at check query 3 or the Jenkins build report |
| Maintenance macro | Its definition is not on the screen | Run the `.spl` macro query, then add a maintenance lookup filter like seq 18 |
| PagerDuty URL | Secret from the screenshot | Keep it in the Dynatrace PagerDuty connection, not in tf |

## Terraform

Full file: `19-ag-portal-nttgw-realtime-functional-ng-tf.tf`. Query:

```
fetch logs, from:now()-30m
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(content, "App-Ops-OpenOps")
| parse content, "JSON:j"
| fieldsAdd job_name, job_result
| filter job_result != "ABORTED" and job_result != "FAILURE"
| fieldsAdd is_functional, is_realtime
| filter is_functional or is_realtime
| fieldsAdd project, name   (Real Time renamed to the Functional project)
| lookup /lookups/jenkins/configuration -> application
| filter cfg.application == "AG Portal NTTGW"
| summarize rt_fails, rt_oks, functional_runs, last_seen, by:{ application, name }
| filter rt_fails >= 2 and rt_oks == 0
```

## Data flow

```
Jenkins (Real Time Check + Functional jobs)
  -> build_report JSON on ceaa2099 (source jenkins/test)
  -> Dynatrace Grail
  -> Records detector (every minute, last 30 min)
       + configuration lookup (AG Portal NTTGW)
  -> 2+ NG, 0 SUCCESS -> problem per project (high)
  -> workflow -> PagerDuty + email
  -> next SUCCESS -> problem closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index="jenkins" source="jenkins/test"`, ABORTED and FAILURE excluded. |
| Screenshot 4 | 471,765 events, one host ceaa2099.prprivmgmt.intraxa, sourcetype jenkins:build_report, JSON with build_number, build_url, job_name, job_result, testsuite. |
| Job pairing | Real Time Check job renamed to the Functional project so both group under one name. |
| Trigger | event=2 (NG) or OK after NG (recovery), results > 0, Once, no throttle. |
| Action | Alert Status Manager, Production email, PagerDuty Enable. |
| Schedule | cron */30, Last 30 minutes. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. Confirm the Real Time and Functional `job_name` values contain the strings in the tf. |
| 2 | Run query 2. Confirm configuration has the project names with application "AG Portal NTTGW". |
| 3 | Run the `.spl` macro query. If maintenance matters, add the maintenance lookup filter. |
| 4 | `terraform plan` and `terraform apply` from `19.sh`. |

## Related files

| File | What it is |
|---|---|
| `19-ag-portal-nttgw-realtime-functional-ng-tf.tf` | The detector |
| `19-ag-portal-nttgw-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `19-ag-portal-nttgw-realtime-functional-ng-tf.spl` | Splunk checks and macro definitions |
| `19.sh` | Commands |
| `../12-jenkins-function-monitor-alert-tf/` | Generic function alert using the same pattern |

## Commands

From `19.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/19-ag-portal-nttgw-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
