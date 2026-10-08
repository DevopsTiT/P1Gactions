# Compass Check NG Reconfirm

## Decision tree

```
Prod_Life_Compass_RealTimeAndFunctionalCheck_NG (shown again)
 search same as seq 24/38? → yes (jenkins_statistics template, application="Compass")
 window / cron? → Last 2 hours, */1 → same
 action? → Alert Status Manager, Production → severity high
 PagerDuty radio visible? → no (below the visible area) → pagerduty "0" (CONFIRM)
 → no tf change: reuse seq 38 tf (audit_trail filter included)
 → same resource name compass_realtime_functional_ng → apply from ONE folder only
 not the same as CompassPB ("Compass AG", jenkins/test, seq 23/27/56)
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 24 and 38. |
| Anything changed? | No. The search, the 2-hour window, the `*/1` cron and Alert Status Manager on Production all match. |
| Which tf to use? | The seq 38 tf, unchanged. |
| Severity and PagerDuty | high and "0" (PagerDuty still not visible, so CONFIRM) |
| Easy to confuse with | CompassPB, which is application "Compass AG" on `jenkins/test` data, a separate detector |

## Summary

These screenshots show the Compass Real Time and Functional check again, with nothing new. The seq 38 tf already has the audit_trail filter. It opens one problem per project when the Real Time (group-jobs) run has 2 or more non-SUCCESS results in 2 hours with no SUCCESS.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index=jenkins_statistics sourcetype="json:jenkins:old"`, `applications*` or `group-jobs*`. This matches seq 38. |
| Functional results emptied | `job_result=if(match(job_name,"applications/"),"",job_result)`, so only Real Time results decide OK or NG. |
| `rex ... OKメンテナンス中` | Kept as `remarks`. |
| Application | `where application="Compass"`. |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")`. |
| Schedule | `*/1`, last 2 hours, expires 24 hours, for each result, no throttle. |
| Action | Alert Status Manager, Production email. I did not copy the recipients. The PagerDuty radio is below the visible area. |

## Result

| Setting | Value |
|---|---|
| Resource | `compass_realtime_functional_ng` (same as seq 24/38, an in-place update) |
| Opens when | `rt_fails >= 2 and rt_oks == 0` in 2 hours |
| Identity | application, name |
| Severity | high |
| pagerduty.enabled | "0" (CONFIRM with `.spl` line 2) |

## Data flow map

```
Jenkins (ceaa2099) build stats JSON (job_duration), audit_trail dropped
  → applications* / group-jobs*
  → name from "Building <tempname>" (» → /), remark OKメンテナンス中
  → lookup /lookups/jenkins/configuration → application == "Compass"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `57-compass-ng-reconfirm.tf` | Copy of the seq 38 tf, unchanged |
| `57-compass-ng-reconfirm-check.dql` | Lookup rows and Compass build events |
| `57-compass-ng-reconfirm.spl` | Lookup and saved search actions (PagerDuty) |
| `57.sh` | Commands |

## Commands

These are in `57.sh`. Nothing has been run. Apply from one folder only (24, 38 or 57).

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/57-compass-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
