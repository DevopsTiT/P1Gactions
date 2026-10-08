# HPM Sales Portal Real Time And Functional NG TF

## Decision tree

```
jenkins/test build_report on ceaa2099
  ABORTED or FAILURE? -> dropped
  App-Ops Functional -> not counted; App-Ops Real Time -> renamed, counted; applications/* -> counted
  configuration lookup: application == "HPM_Sales_Portal"?
    yes -> 2+ non-SUCCESS and 0 SUCCESS in 2 hours?
             yes -> problem per job (high)
             next SUCCESS -> closes
PagerDuty?
  -> trigger actions not visible; set pagerduty.enabled after checking
```

## Short takeaway

| Question | Answer |
|---|---|
| Template | Same corrected jenkins/test template as HPM Owner Portal (seq 27). |
| Only change | `where application="HPM_Sales_Portal"`. |
| Window | 2 hours, cron every minute. |
| Severity | high. |
| PagerDuty | "0" until the trigger actions are checked. |

## Summary

HPM Sales Portal is the seq 27 HPM Owner Portal detector with the application changed to "HPM_Sales_Portal". It uses the corrected logic: every jenkins/test job counts except App-Ops Functional jobs. The screenshot stops at Trigger Actions, so PagerDuty is off until confirmed.

## Terraform

Full file: `29-hpm-sales-portal-realtime-functional-ng-tf.tf` (includes its own provider block). Change from seq 27:

```
| filter cfg.application == "HPM_Sales_Portal"
```

## Data flow

```
jenkins/test (ceaa2099) -> Grail -> detector (every minute, last 2 hours) + configuration (HPM_Sales_Portal)
  -> 2+ NG, 0 SUCCESS -> problem per job (high) -> email (PagerDuty if enabled)
```

## Investigation

| What I checked | What I found |
|---|---|
| Search body | Same as HPM Owner Portal, except `where application="HPM_Sales_Portal"`. |
| Schedule | cron */1, Last 2 hours, Expires 24 hours. |
| Trigger | event=2 or recovery, results > 0, Once, no throttle. |
| Actions | Not visible. |

## Result

| Step | What to do |
|---|---|
| 1 | Run the `.spl` second query to see the actions. If PagerDuty is Enable, set `pagerduty.enabled` to "1". |
| 2 | Run check.dql query 2 to confirm HPM_Sales_Portal rows. |
| 3 | `terraform plan` and `terraform apply` from `29.sh`. |

## Related files

| File | What it is |
|---|---|
| `29-hpm-sales-portal-realtime-functional-ng-tf.tf` | The detector |
| `29-hpm-sales-portal-realtime-functional-ng-tf-check.dql` | Dynatrace checks |
| `29-hpm-sales-portal-realtime-functional-ng-tf.spl` | Splunk checks |
| `29.sh` | Commands |
| `../27-hpm-owner-portal-ng-and-jenkins-test-fix-tf/` | Corrected template |

## Commands

From `29.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/29-hpm-sales-portal-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
