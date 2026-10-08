# Compass Real Time And Functional NG TF

## Decision tree

```
jenkins_statistics build event (ceaa2099, json:jenkins:old) with job_duration
  group-jobs = Real Time, applications = Functional, name from "Building a » b » c"
  configuration lookup: application == "Compass"?
    yes -> Real Time 2+ non-SUCCESS and 0 SUCCESS in 2 hours?
             yes -> problem per project (high)
             next SUCCESS -> closes
PagerDuty?
  -> cut off in the screenshot; check and set pagerduty.enabled
```

## Short takeaway

| Question | Answer |
|---|---|
| Template | Same as Cockpit360 ALL (seq 22). |
| Only change | `where application="Compass"`. |
| Not the same as Compass PB | Compass PB (seq 23) is on jenkins/test with application "Compass AG". |
| Window | 2 hours, cron every minute. |
| Severity | high. |
| PagerDuty | "0" for now; the setting is cut off in the screenshot. |

## Summary

This alert is the seq 22 Cockpit360 detector with the application filter changed to "Compass". It reads the `jenkins_statistics` data, so it covers different jobs from Compass PB (seq 23), which reads `jenkins/test` and filters "Compass AG". Both can exist side by side.

## Compass vs Compass PB vs Cockpit360

| Setting | Cockpit360 ALL (seq 22) | Compass PB (seq 23) | Compass (this one) |
|---|---|---|---|
| Data | jenkins_statistics | jenkins/test | jenkins_statistics |
| Application | Cockpit360 | Compass AG | Compass |
| Real Time job | group-jobs* | Real Time Check | group-jobs* |
| Window | 2 hours | 2 hours | 2 hours |
| PagerDuty | Not visible | Enable | Not visible |

## Terraform

Full file: `24-compass-realtime-functional-ng-tf.tf`. Only change from seq 22:

```
| filter cfg.application == "Compass"
```

## Data flow

```
Jenkins group-jobs (Real Time) + applications (Functional)
  -> json:jenkins:old on ceaa2099 -> Grail
  -> Records detector (every minute, last 2 hours) + configuration lookup (Compass)
  -> 2+ NG, 0 SUCCESS -> problem per project (high) -> email (PagerDuty if enabled)
  -> next SUCCESS -> closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as seq 22 line by line, except `where application="Compass"`. |
| Schedule | cron */1, Last 2 hours. |
| Trigger | event > 0 or recovery, results > 0, Once, no throttle. |
| Action | Alert Status Manager, Production. PagerDuty line not visible. |

## Result

| Step | What to do |
|---|---|
| 1 | Scroll down in Splunk. If PagerDuty is Enable, set `pagerduty.enabled` to "1". |
| 2 | Run check.dql query 2 to confirm configuration really uses "Compass" for these jobs. |
| 3 | `terraform plan` and `terraform apply` from `24.sh`. |

## Related files

| File | What it is |
|---|---|
| `24-compass-realtime-functional-ng-tf.tf` | The detector |
| `24-compass-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `24-compass-realtime-functional-ng-tf.spl` | Splunk checks, including the alert's action settings |
| `24.sh` | Commands |
| `../22-cockpit360-realtime-functional-ng-tf/` | Same template for Cockpit360 |
| `../23-compass-pb-realtime-functional-ng-tf/` | Compass PB on jenkins/test |

## Commands

From `24.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/24-compass-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
