# Cockpit360 Check NG Reconfirm

## Decision tree

```
Prod_Life_Cockpit360ALL_RealTimeAndFunctionalCheck_NG (shown again)
 search same as seq 22/37? → yes (jenkins_statistics template, application="Cockpit360")
 window / cron? → Last 2 hours, */1 → same
 action? → Alert Status Manager (PagerDuty still below the visible area)
 → no tf change: reuse seq 37 tf (audit_trail filter included)
 → same resource name cockpit360_realtime_functional_ng → apply from ONE folder only
 PagerDuty Enable seen later? → set pagerduty.enabled "1"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 22 and 37. |
| Anything changed? | No. The search, the 2-hour window, the `*/1` cron and Alert Status Manager all match. |
| Which tf to use? | The seq 37 tf, unchanged. |
| Severity and PagerDuty | high and "0" (PagerDuty still not visible, so CONFIRM) |

## Summary

These screenshots show the Cockpit360 Real Time and Functional check again, with nothing new. The seq 37 tf already has the audit_trail filter. It opens one problem per project when the Real Time (group-jobs) run has 2 or more non-SUCCESS results in 2 hours with no SUCCESS.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index=jenkins_statistics sourcetype="json:jenkins:old"`, `applications*` or `group-jobs*`. This matches seq 37. |
| `job_result=if(match(job_name,"applications/"),"",job_result)` | Functional results are emptied, so only Real Time results decide OK or NG. The detector counts `is_realtime` the same way. |
| `rex ... OKメンテナンス中` | Kept as `remarks`, which are shown but not filtered. |
| `where application="Cockpit360"` | The same filter is in the tf. |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")`. Alert Status Manager decides from the status, and Dynatrace opens and closes the problem instead. |
| Schedule | `*/1`, last 2 hours, expires 24 hours, for each result, no throttle. |
| Action | Alert Status Manager. The PagerDuty radio is below the visible area. |
| Sourcetype | `json:jenkins:old` on `jenkins_statistics` is the same question as seq 50. The new `.spl` line 3 checks it. It doesn't affect the Dynatrace tf. |

## Result

| Setting | Value |
|---|---|
| Resource | `cockpit360_realtime_functional_ng` (same as seq 22/37, an in-place update) |
| Opens when | `rt_fails >= 2 and rt_oks == 0` in 2 hours |
| Identity | application, name |
| Severity | high |
| pagerduty.enabled | "0" (CONFIRM) |

## Data flow map

```
Jenkins (ceaa2099) build stats JSON (job_duration), audit_trail dropped
  → applications* / group-jobs*
  → name from "Building <tempname>" (» → /), remark OKメンテナンス中
  → lookup /lookups/jenkins/configuration → application == "Cockpit360"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `55-cockpit360-ng-reconfirm.tf` | Copy of the seq 37 tf, unchanged |
| `55-cockpit360-ng-reconfirm-check.dql` | Lookup rows and Cockpit360 build events |
| `55-cockpit360-ng-reconfirm.spl` | Lookup, saved search actions (PagerDuty), sourcetype check |
| `55.sh` | Commands |

## Commands

These are in `55.sh`. Nothing has been run. Apply from one folder only (22, 37 or 55).

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/55-cockpit360-ng-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
