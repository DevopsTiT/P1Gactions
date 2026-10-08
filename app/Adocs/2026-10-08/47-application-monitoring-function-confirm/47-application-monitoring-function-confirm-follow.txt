# Application Monitoring Function Confirm

## Decision tree

```
Application Monitoring Alert - function (seen again)
 search changed? → no (pager_duty="0", Functional results, console maintenance join)
 affected by the dead "text:jenkins" sourcetype (seq 45)? → no, the join subsearch has no sourcetype filter
 console source format? → job/.../<build>/console (confirmed in seq 45) → build_url join works
 tf already final? → yes, seq 36 → apply from ONE folder
```

## Short takeaway

| Question | Answer |
|---|---|
| Is anything new? | No. The screenshots match seq 36. |
| Does the seq 45 sourcetype problem affect it? | No. The jenkins_console subsearch has no sourcetype filter. |
| Which tf? | Seq 36. This folder holds an identical copy. |
| Severity and PagerDuty | high and "0", because it covers only apps with pager_duty "0". |

## Summary

The function alert is unchanged from seq 36. The seq 45 finding (no `text:jenkins` sourcetype) does not affect it, because its maintenance join searches jenkins_console without a sourcetype. The console path format seen in seq 45 matches the build_url logic.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | jenkins_statistics template with Real Time results emptied. |
| Scope | `where pager_duty="0"`. |
| Maintenance join | `index=jenkins_console source="job/applications/job/*" "Application is in mantenance"`, with no sourcetype filter. |
| Time range and cron | Last 120 minutes, every minute. |
| Action | Alert Status Manager, Production. |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_function` |
| tf | `47-application-monitoring-function-confirm.tf`, which is the same as seq 36 |
| Severity | high |
| pagerduty.enabled | "0" |

## Data flow map

```
jenkins_statistics build events + jenkins_console maintenance lines (no sourcetype filter)
  → join on build_url → configuration pager_duty == "0"
  → Functional fn_fails >= 2, fn_oks == 0 → problem (high, no page) → SUCCESS closes
```

## Related files

| File | What it is |
|---|---|
| `47-application-monitoring-function-confirm.tf` | A copy of the seq 36 detector |
| `47-application-monitoring-function-confirm-check.dql` | A copy of the seq 36 checks |
| `47-application-monitoring-function-confirm.spl` | A copy of the seq 36 Splunk checks |
| `47.sh` | Commands |

## Commands

These are in `47.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/36-application-monitoring-alert-function-tf"
terraform init
terraform plan
terraform apply
```
