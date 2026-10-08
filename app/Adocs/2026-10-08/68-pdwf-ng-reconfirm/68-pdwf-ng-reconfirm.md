# PDWF NG Reconfirm

## Decision tree

```
Edit Alert: Prod_Life_PDWF_RealTimeAndFunctionalCheck_NG
 search = jenkins_statistics template, where application="PDWF"? → yes
 every minute, last 2 hours, Alert Status Manager, Production? → yes, same as seq 33/43
 tf change? → none
 PagerDuty visible? → no, cut off below Recipients → keep "0"
   scroll down → PagerDuty Enable? → set "1" before apply
 → same resource pdwf_realtime_functional_ng → apply from ONE folder only (33, 43 or 68)
```

## Short takeaway

| Question | Answer |
|---|---|
| Which alert is this? | Prod_Life_PDWF_RealTimeAndFunctionalCheck_NG |
| Is it new? | No. It is the same as seq 33 and seq 43. |
| What changed in the tf? | Nothing. |
| Severity | high, because the alert goes to the Alert Status Manager with Production email. |
| PagerDuty | "0" until you scroll below Recipients and check. |

## Summary

The PDWF search and settings match seq 43 line for line, so the Terraform does not change. The PagerDuty setting is the only open point.

## Investigation

| What I checked | What I found |
|---|---|
| Search head | `index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)` |
| Application filter | `where application="PDWF"` |
| Judgement | `streamstats ... where index<=2`, OK if any SUCCESS, else NG |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")` |
| Schedule | Cron `*/1`, last 2 hours, expires 24 hours |
| Trigger | Number of results greater than 0, once, for each result, no throttle |
| Action | Alert Status Manager, Production email. I did not copy the recipients. |
| PagerDuty | Not visible |

## Result

| Setting | Value |
|---|---|
| Resource | `pdwf_realtime_functional_ng` |
| Change | None |
| Severity | high |
| pagerduty.enabled | "0" (CONFIRM) |
| Apply | One folder only: 33, 43 or 68 |

## Data flow map

```
Jenkins (ceaa2099) statistics JSON (job_duration present, audit_trail dropped)
  → applications* = Functional, group-jobs* = Real Time
  → name = "Building ..." with " » " → "/"
  → lookup configuration → application == "PDWF"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `68-pdwf-ng-reconfirm.tf` | Detector, same as seq 43 |
| `68-pdwf-ng-reconfirm-check.dql` | Template shape and PDWF lookup rows |
| `68-pdwf-ng-reconfirm.spl` | Saved search actions, including PagerDuty |
| `68.sh` | Commands |

## Commands

These are in `68.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/68-pdwf-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
