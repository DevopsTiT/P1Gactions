# MyAXA Real Time NG Detector

## Decision tree

```
Prod_Life_MyAXA_RealTimeAndFunctionalCheck_NG
 template? → jenkins_statistics (group-jobs + applications) → reuse FCR / ICM query
 application? → "MyAXA" → check the lookup spells it exactly like that
 actions? → Alert Status Manager, email Production → severity high
 PagerDuty cut off? → pagerduty "0" for now → Enable in Splunk → set "1"
 confused with "MYAXA NG state for 10min"? → different alert (seq 18), keep both
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | A MyAXA Real Time job returned 2 or more non-SUCCESS results in 2 hours, with no SUCCESS. |
| Which template? | jenkins_statistics, the same as FCR (seq 26) and Claims ICM (seq 30). |
| What changed? | The application filter is "MyAXA", and the cron runs every minute. |
| PagerDuty? | "0" for now. The setting is cut off in the screenshot. |
| Severity? | high, because Alert Status Manager emails Production. |

## Summary

This is the same Real Time and Functional check as FCR and Claims ICM, filtered to application "MyAXA". Splunk runs it every minute over 2 hours and sends it to Alert Status Manager in Production mode. The PagerDuty switch is below the visible area, so the tf uses "0" until you confirm it.

## Investigation

| What I checked | What I found |
|---|---|
| index and sourcetype | jenkins_statistics with json:jenkins:old. |
| Application filter | `where application="MyAXA"`. |
| Time range | Last 2 hours. |
| Cron | `*/1 * * * *`, every minute. |
| Trigger | Number of results greater than 0, for each result, no throttle. |
| Action | Alert Status Manager, Email Notification Mode set to Production. |
| PagerDuty | Not visible. |
| Related alert | "MYAXA NG state for 10min" (seq 18) reads Login_Check and Function_Check directly. It is a different alert. |

## Result

| Setting | Value |
|---|---|
| Resource | `myaxa_realtime_functional_ng` |
| Query window | `from:now()-2h` |
| Identity | application and name |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics logs → Dynatrace Grail
  → keep lines with job_duration, drop audit_trail
  → group-jobs = Real Time, applications = Functional
  → lookup configuration → application == "MyAXA"
  → summarize per project: rt_fails, rt_oks
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high)
  → next SUCCESS → problem closes
```

## Related files

| File | What it is |
|---|---|
| `31-myaxa-realtime-functional-ng-tf.tf` | The detector |
| `31-myaxa-realtime-functional-ng-tf-check.dql` | Dynatrace checks for the lookup and build events |
| `31-myaxa-realtime-functional-ng-tf.spl` | Splunk checks for the lookup and alert actions |
| `31.sh` | Commands |

## Commands

These are in `31.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/31-myaxa-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
