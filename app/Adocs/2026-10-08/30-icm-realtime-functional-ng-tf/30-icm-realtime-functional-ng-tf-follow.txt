# Claims ICM Real Time NG Detector

## Decision tree

```
Prod_Life_ICM_RealTimeAndFunctionalCheck_NG
 template? → jenkins_statistics (group-jobs + applications) → reuse FCR seq 26 query
 application? → "Claims ICM" (with the space) → check lookup has it
 actions? → only Add to Triggered Alerts → pagerduty "0", severity medium
 should it page? → yes → pagerduty "1", severity high
 lookup has no "Claims ICM"? → detector never fires → fix lookup first
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | A Claims ICM Real Time job returned 2 or more non-SUCCESS results in 2 hours, with no SUCCESS. |
| Which template? | jenkins_statistics, the same as FCR in seq 26. |
| What changed from FCR? | The application filter is "Claims ICM". |
| PagerDuty? | "0". Splunk only adds the alert to Triggered Alerts. |
| Severity? | medium, because nobody is notified today. |

## Summary

This alert is a copy of the FCR detector with the application changed to "Claims ICM". The Splunk alert runs every 3 minutes over the last 2 hours, and its only action is "Add to Triggered Alerts", so nobody gets an email or a page. The Dynatrace detector therefore uses PagerDuty "0" and severity medium.

## Investigation

| What I checked | What I found |
|---|---|
| index and sourcetype | jenkins_statistics with json:jenkins:old, the same as FCR, Compass and Cockpit360. |
| Application filter | `where application="Claims ICM"`. |
| Time range | Last 2 hours. |
| Cron | `*/3 * * * *`, every 3 minutes. |
| Trigger | Number of results greater than 0, for each result. |
| Actions | Only "Add to Triggered Alerts". There is no email and no PagerDuty. |

## Result

| Setting | Value |
|---|---|
| Resource | `icm_realtime_functional_ng` |
| Query window | `from:now()-2h` |
| Identity | application and name |
| Severity | medium |
| pagerduty.enabled | "0" |

The full tf is in `30-icm-realtime-functional-ng-tf.tf`. The check queries are in `30-icm-realtime-functional-ng-tf-check.dql`, and the Splunk queries are in `30-icm-realtime-functional-ng-tf.spl`.

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics logs → Dynatrace Grail
  → keep lines with job_duration, drop audit_trail
  → group-jobs = Real Time, applications = Functional
  → lookup configuration → application == "Claims ICM"
  → summarize per project: rt_fails, rt_oks
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (medium, no page)
  → next SUCCESS → problem closes
```

## Related files

| File | What it is |
|---|---|
| `30-icm-realtime-functional-ng-tf.tf` | The detector |
| `30-icm-realtime-functional-ng-tf-check.dql` | Dynatrace checks for the lookup and build events |
| `30-icm-realtime-functional-ng-tf.spl` | Splunk checks for the lookup and alert actions |
| `30.sh` | Commands |

## Commands

These are in `30.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/30-icm-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
