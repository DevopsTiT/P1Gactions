# FCR Check NG Reconfirm

## Decision tree

```
Prod_Life_FCR_RealTimeAndFunctionalCheck_NG (shown again)
 search same as seq 26/39? → yes (jenkins_statistics template, application="FCR")
 window / cron? → Last 2 hours, */1 → same
 action? → Alert Status Manager, Production → severity high
 PagerDuty radio visible? → no → pagerduty "0" (CONFIRM)
 → no tf change: reuse seq 26/39 tf (audit_trail filter included)
 → same resource name fcr_realtime_functional_ng → apply from ONE folder only
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 26 and 39. |
| Anything changed? | No. The search, the 2-hour window, the `*/1` cron and Alert Status Manager on Production all match. |
| Which tf to use? | The seq 26/39 tf, unchanged. |
| Severity and PagerDuty | high and "0" (PagerDuty still not visible, so CONFIRM) |

## Summary

These screenshots show the FCR Real Time and Functional check again, with nothing new. The tf opens one problem per project when the Real Time (group-jobs) run has 2 or more non-SUCCESS results in 2 hours with no SUCCESS.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index=jenkins_statistics sourcetype="json:jenkins:old"`, `applications*` or `group-jobs*`. Same. |
| Application | `where application="FCR"`. Same. |
| Remarks | `OKメンテナンス中` rex. Kept as `remarks`. |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")`. Same. |
| Schedule | `*/1`, last 2 hours, expires 24 hours, for each result, no throttle. |
| Action | Alert Status Manager, Production. I did not copy the recipients. PagerDuty is not visible. |

## Result

| Setting | Value |
|---|---|
| Resource | `fcr_realtime_functional_ng` (same as seq 26/39) |
| Opens when | `rt_fails >= 2 and rt_oks == 0` in 2 hours |
| Severity | high |
| pagerduty.enabled | "0" (CONFIRM with `.spl` line 3) |

## Data flow map

```
Jenkins (ceaa2099) build stats JSON (job_duration), audit_trail dropped
  → applications* / group-jobs* → name from "Building <tempname>"
  → lookup configuration → application == "FCR"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `59-fcr-ng-reconfirm.tf` | Copy of the seq 39 tf |
| `59-fcr-ng-reconfirm-check.dql` | audit_trail share, kept build events, FCR lookup rows |
| `59-fcr-ng-reconfirm.spl` | Event sources and saved search actions |
| `59.sh` | Commands |

## Commands

These are in `59.sh`. Nothing has been run. Apply from one folder only (26, 39 or 59).

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/59-fcr-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
