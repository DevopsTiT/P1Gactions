# NBWF NG Reconfirm

## Decision tree

```
Edit Alert: Prod_Life_NBWF_RealTimeAndFunctionalCheck_NG
 search = jenkins_statistics template, where application="NBWF"? → yes
 every minute, last 2 hours, Alert Status Manager? → yes, same as seq 32/42
 new detail → email mode Production (seq 42 could not see it) → severity high confirmed
 tf change? → none
 PagerDuty visible? → no, cut off below Recipients → keep "0"
   scroll down → PagerDuty Enable? → set "1" before apply
 → same resource nbwf_realtime_functional_ng → apply from ONE folder only (32, 42 or 67)
```

## Short takeaway

| Question | Answer |
|---|---|
| Which alert is this? | Prod_Life_NBWF_RealTimeAndFunctionalCheck_NG |
| Is it new? | No. It is the same as seq 32 and seq 42. |
| What is new in the screenshots? | The email mode is visible now, and it is Production. |
| What changed in the tf? | Nothing. Production email matches the high severity already set. |
| PagerDuty | "0" until you scroll below Recipients and check. |

## Summary

The NBWF search and settings match seq 42 line for line. The Production email mode confirms the high severity. The Terraform does not change, and the PagerDuty setting is the only open point.

## Investigation

| What I checked | What I found |
|---|---|
| Search head | `index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)` |
| Application filter | `where application="NBWF"` |
| Judgement | `streamstats ... where index<=2`, OK if any SUCCESS, else NG |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")` |
| Schedule | Cron `*/1`, last 2 hours, expires 24 hours |
| Trigger | Number of results greater than 0, once, for each result, no throttle |
| Action | Alert Status Manager, Production email. I did not copy the recipients. |
| PagerDuty | Not visible |

## Result

| Setting | Value |
|---|---|
| Resource | `nbwf_realtime_functional_ng` |
| Change | None |
| Severity | high |
| pagerduty.enabled | "0" (CONFIRM) |
| Apply | One folder only: 32, 42 or 67 |

## Data flow map

```
Jenkins (ceaa2099) statistics JSON (job_duration present, audit_trail dropped)
  → applications* = Functional, group-jobs* = Real Time
  → name = "Building ..." with " » " → "/"
  → lookup configuration → application == "NBWF"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `67-nbwf-ng-reconfirm.tf` | Detector, same as seq 42 |
| `67-nbwf-ng-reconfirm-check.dql` | Template shape and NBWF lookup rows |
| `67-nbwf-ng-reconfirm.spl` | Saved search actions, including PagerDuty |
| `67.sh` | Commands |

## Commands

These are in `67.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/67-nbwf-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
