# PDWF Real Time NG Detector

## Decision tree

```
Prod_Life_PDWF_RealTimeAndFunctionalCheck_NG
 template? → jenkins_statistics (group-jobs + applications) → reuse FCR / MyAXA / NBWF query
 application? → "PDWF" → check the lookup spells it exactly like that
 actions? → Alert Status Manager, email Production → severity high
 PagerDuty cut off? → pagerduty "0" for now → Enable in Splunk → set "1"
 lookup has no PDWF rows? → detector never fires → fix lookup first
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | A PDWF Real Time job returned 2 or more non-SUCCESS results in 2 hours, with no SUCCESS. |
| Which template? | jenkins_statistics, the same as FCR, MyAXA and NBWF. |
| What changed? | Only the application filter, which is now "PDWF". |
| PagerDuty? | "0" for now. The setting is cut off in the screenshot. |
| Severity? | high, because Alert Status Manager emails Production. |

## Summary

PDWF uses the same Real Time and Functional check as NBWF and MyAXA, filtered to application "PDWF". Splunk runs it every minute over 2 hours and sends it to Alert Status Manager in Production mode. The PagerDuty switch is not visible, so the tf uses "0" until you confirm it.

## Investigation

| What I checked | What I found |
|---|---|
| index and sourcetype | jenkins_statistics with json:jenkins:old. |
| Application filter | `where application="PDWF"`. |
| Time range | Last 2 hours. |
| Cron | `*/1 * * * *`, every minute. |
| Trigger | Number of results greater than 0, for each result, no throttle. |
| Action | Alert Status Manager, Email Notification Mode set to Production. |
| PagerDuty | Not visible. |

## Result

| Setting | Value |
|---|---|
| Resource | `pdwf_realtime_functional_ng` |
| Query window | `from:now()-2h` |
| Identity | application and name |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics logs → Dynatrace Grail
  → keep lines with job_duration, drop audit_trail
  → group-jobs = Real Time, applications = Functional
  → lookup configuration → application == "PDWF"
  → summarize per project: rt_fails, rt_oks
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high)
  → next SUCCESS → problem closes
```

## Related files

| File | What it is |
|---|---|
| `33-pdwf-realtime-functional-ng-tf.tf` | The detector |
| `33-pdwf-realtime-functional-ng-tf-check.dql` | Dynatrace checks for the lookup and build events |
| `33-pdwf-realtime-functional-ng-tf.spl` | Splunk checks for the lookup and alert actions |
| `33.sh` | Commands |

## Commands

These are in `33.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/33-pdwf-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
