# FCR Real Time And Functional NG TF

## Decision tree

```
jenkins_statistics build event (ceaa2099, json:jenkins:old) with job_duration
  group-jobs = Real Time, applications = Functional, name from "Building a » b » c"
  configuration lookup: application == "FCR"?
    yes -> Real Time 2+ non-SUCCESS and 0 SUCCESS in 2 hours?
             yes -> problem per project (high)
             next SUCCESS -> closes
PagerDuty?
  -> cut off in the screenshot; check and set pagerduty.enabled
```

## Short takeaway

| Question | Answer |
|---|---|
| Template | Same as Cockpit360 ALL (seq 22) and Compass (seq 24). |
| Only change | `where application="FCR"`. |
| Window | 2 hours, cron every minute. |
| Severity | high. |
| PagerDuty | "0" for now; the setting is cut off in the screenshot. |

## Summary

FCR is the third alert on the `jenkins_statistics` Real Time and Functional template. The search is identical to Cockpit360 ALL and Compass except for `where application="FCR"`, so the detector only changes the application filter, title and app name.

## The jenkins_statistics family so far

| Seq | Alert | Application |
|---|---|---|
| 22 | Prod_Life_Cockpit360ALL_RealTimeAndFunctionalCheck_NG | Cockpit360 |
| 24 | Prod_Life_Compass_RealTimeAndFunctionalCheck_NG | Compass |
| 25 | Prod_Life_FCR_RealTimeAndFunctionalCheck_NG | FCR |

If more of these arrive, they can be merged into one `for_each` resource keyed by application.

## Terraform

Full file: `25-fcr-realtime-functional-ng-tf.tf`. Only change from seq 24:

```
| filter cfg.application == "FCR"
```

## Data flow

```
Jenkins group-jobs (Real Time) + applications (Functional)
  -> json:jenkins:old on ceaa2099 -> Grail
  -> Records detector (every minute, last 2 hours) + configuration lookup (FCR)
  -> 2+ NG, 0 SUCCESS -> problem per project (high) -> email (PagerDuty if enabled)
  -> next SUCCESS -> closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as seq 22 and 24, except `where application="FCR"`. |
| Schedule | cron */1, Last 2 hours. |
| Trigger | event > 0 or recovery, results > 0, Once, no throttle. |
| Action | Alert Status Manager, Production. PagerDuty line not visible. |

## Result

| Step | What to do |
|---|---|
| 1 | Scroll down in Splunk. If PagerDuty is Enable, set `pagerduty.enabled` to "1". |
| 2 | Run check.dql query 1 to confirm FCR rows exist in configuration. |
| 3 | Run query 2 to see FCR runs and results from the last day. |
| 4 | `terraform plan` and `terraform apply` from `25.sh`. |

## Related files

| File | What it is |
|---|---|
| `25-fcr-realtime-functional-ng-tf.tf` | The detector |
| `25-fcr-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `25-fcr-realtime-functional-ng-tf.spl` | Splunk checks, including the alert's action settings |
| `25.sh` | Commands |
| `../22-cockpit360-realtime-functional-ng-tf/` | Same template for Cockpit360 |
| `../24-compass-realtime-functional-ng-tf/` | Same template for Compass |

## Commands

From `25.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/25-fcr-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
