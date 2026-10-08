# MyAXA NG Reconfirm

## Decision tree

```
Edit Alert: Prod_Life_MyAXA_RealTimeAndFunctionalCheck_NG
 search = jenkins_statistics template, where application="MyAXA"? → yes
 every minute, last 2 hours, Alert Status Manager, Production? → yes, same as seq 31/41
 tf change? → none
 PagerDuty visible? → no, cut off below Recipients → keep "0"
   scroll down → PagerDuty Enable? → set "1" before apply
 → same resource myaxa_realtime_functional_ng → apply from ONE folder only (31, 41 or 66)
```

## Short takeaway

| Question | Answer |
|---|---|
| Which alert is this? | Prod_Life_MyAXA_RealTimeAndFunctionalCheck_NG |
| Is it new? | No. It is the same as seq 31 and seq 41. |
| What changed in the tf? | Nothing. |
| Severity | high, because the alert goes to the Alert Status Manager with Production email. |
| PagerDuty | "0" until you scroll below Recipients and check. |
| Is it the same as "MYAXA NG state for 10min"? | No. That is seq 18, a different alert. |

## Summary

These screenshots show the full MyAXA search and settings. They match seq 41 line for line, so the Terraform does not change. The PagerDuty setting is the only open point.

## Investigation

| What I checked | What I found |
|---|---|
| Search head | `index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)` |
| Application filter | `where application="MyAXA"` |
| Judgement | `streamstats ... where index<=2`, OK if any SUCCESS, else NG |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")` |
| Schedule | Cron `*/1`, last 2 hours, expires 24 hours |
| Trigger | Number of results greater than 0, once, for each result, no throttle |
| Action | Alert Status Manager, Production email. I did not copy the recipients. |
| PagerDuty | Not visible |

## Result

| Setting | Value |
|---|---|
| Resource | `myaxa_realtime_functional_ng` |
| Change | None |
| Severity | high |
| pagerduty.enabled | "0" (CONFIRM) |
| Apply | One folder only: 31, 41 or 66 |

## Data flow map

```
Jenkins (ceaa2099) statistics JSON (job_duration present, audit_trail dropped)
  → applications* = Functional, group-jobs* = Real Time
  → name = "Building ..." with " » " → "/"
  → lookup configuration → application == "MyAXA"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `66-myaxa-ng-reconfirm.tf` | Detector, same as seq 41 |
| `66-myaxa-ng-reconfirm-check.dql` | Template shape and MyAXA lookup rows |
| `66-myaxa-ng-reconfirm.spl` | Saved search actions, including PagerDuty |
| `66.sh` | Commands |

## Commands

These are in `66.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/66-myaxa-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
