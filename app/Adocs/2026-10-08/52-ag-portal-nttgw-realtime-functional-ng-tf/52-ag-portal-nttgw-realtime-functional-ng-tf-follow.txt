# AG Portal NTTGW Check NG

## Decision tree

```
Prod_Life_AGPortalNTTGW_RealTimeAndFunctionalCheck_NG
 data alive? → index=jenkins source=jenkins/test → 168,553 events since 10/1 → yes
 template? → jenkins/test (same as seq 29 HPM_Sales_Portal)
 application? → "AG Portal NTTGW" (check exact spelling in lookup, check.dql 1)
 window? → Last 30 minutes, cron */30 → from:now()-30m
   jobs run < 2 times per 30m? → widen to 60m
 trigger actions visible? → no → pagerduty "0", severity high (CONFIRM)
   PagerDuty Enable → "1"
 → detector: per application+name, fails >= 2 and oks == 0 (FAILURE/ABORTED excluded like Splunk)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | AG Portal NTTGW Jenkins checks (Real Time and Functional) in `index=jenkins source=jenkins/test`. |
| Is the data alive? | Yes. There are 168,553 events since 10/1 from host `ceaa2099.prprivmgmt.intraxa`. |
| When does it open a problem? | When a counted job has 2 or more non-SUCCESS results in 30 minutes and no SUCCESS. |
| Resource | `ag_portal_nttgw_realtime_functional_ng` |
| Severity and PagerDuty | high and "0", both to confirm because the actions were not visible |

## Summary

This alert uses the same `jenkins/test` template as HPM_Sales_Portal (seq 29). Only the application name, the 30-minute window and the `*/30` cron are different. The data source is alive. Before applying, check that the lookup spells the application exactly "AG Portal NTTGW", and that each job runs at least twice in 30 minutes.

## Investigation

### What the Splunk search does

| Step | What it does |
|---|---|
| `job_result!=ABORTED job_result!=FAILURE` | Drops aborted and hard-failed builds. |
| `rename testsuite.*` | Pulls test case names, statuses and durations from the JUnit results. |
| Functional jobs get `job_result=""` | App-Ops Functional jobs do not decide OK or NG. |
| Real Time Check renamed to Functional | Both jobs end up under one project name. |
| `replace "job/"`, `%20`, `/$` | Builds a clean `name` for the lookup. |
| `lookup configuration` and `where application="AG Portal NTTGW"` | Keeps only this application. |
| `streamstats ... index<=2` | Uses the last 2 runs per job. |
| `status=OK` if any SUCCESS | Otherwise the status is NG. |
| `search event=2 OR (status="OK" AND prev_status="NG")` | Mails when 2 runs failed, and again on recovery. |

### Data source (third screenshot)

| Field | Value |
|---|---|
| index and source | `jenkins`, `jenkins/test` |
| sourcetype | `jenkins:build_report` |
| host | `ceaa2099.prprivmgmt.intraxa` |
| event_tag | `build_report`, which the detector filters on |
| Example job names | `group-jobs/realtime/bank-account/bank-account`, `applications/bank-account/functional-check` |

### Things to be aware of

| Point | What it means |
|---|---|
| FAILURE is excluded | NG only comes from other non-SUCCESS results, such as UNSTABLE. A job that hard-fails every time is invisible, the same as in Splunk. Check query 3 shows which results exist. |
| 30-minute window | Splunk needs 2 runs. If a job runs less than twice in 30 minutes, it can never reach `fails >= 2`. |
| Actions not visible | The screenshot ends at Trigger Actions, so PagerDuty and the email mode are unknown. |

## Result

| Setting | Value |
|---|---|
| Resource | `ag_portal_nttgw_realtime_functional_ng` |
| Window | `from:now()-30m` |
| Filter | `cfg.application == "AG Portal NTTGW"` |
| Opens when | `fails >= 2 and oks == 0` |
| Identity | application, name |
| Severity | high (CONFIRM) |
| pagerduty.enabled | "0" (set it to "1" if PagerDuty is Enable) |

## Data flow map

```
Jenkins (ceaa2099) build_report JSON (source jenkins/test)
  → drop ABORTED / FAILURE, drop events with job_duration (statistics events)
  → App-Ops Real Time Check renamed to Functional project; Functional runs not judged
  → name cleanup (job/, %20, trailing /)
  → lookup /lookups/jenkins/configuration → application == "AG Portal NTTGW"
  → per application+name in 30m: fails >= 2 and oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `52-ag-portal-nttgw-realtime-functional-ng-tf.tf` | Detector |
| `52-ag-portal-nttgw-realtime-functional-ng-tf-check.dql` | Lookup rows, runs per job, job_result values |
| `52-ag-portal-nttgw-realtime-functional-ng-tf.spl` | Lookup, result values, saved search actions, scheduler history |
| `52.sh` | Commands |

## Commands

These are in `52.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/52-ag-portal-nttgw-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
