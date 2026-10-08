# ICM NG Title Confirmed

## Decision tree

```
Edit Alert: Prod_Life_ICM_RealTimeAndFunctionalCheck_NG (title now visible)
 head = jenkins_statistics json:jenkins:old, applications* OR group-jobs*? → yes, same template
 where application="Claims ICM"? → yes → cfg.application == "Claims ICM"
 */3, 2 hours, Medium + Alert Status Manager? → yes, same as seq 40/64
 tf change? → none
 PagerDuty visible? → no → keep "0"; expand Alert Status Manager → Enable? → set "1"
 → apply from ONE folder only (40, 64 or 65)
```

## Short takeaway

| Question | Answer |
|---|---|
| Which alert is this? | Prod_Life_ICM_RealTimeAndFunctionalCheck_NG. The title is visible now. |
| Was the seq 64 guess right? | Yes. |
| What changed in the tf? | Nothing. |
| Severity | medium |
| PagerDuty | "0" until you check the Alert Status Manager row. |

## Summary

The first screenshot shows the title and the full head of the search, which confirms the match made in seq 64. The Terraform is the same as seq 40. Only the PagerDuty setting is still open.

## Investigation

| Splunk line | Dynatrace equivalent |
|---|---|
| `index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)` | `contains(content,"job_duration")`, then `applications*` or `group-jobs*` |
| `where isnotnull(job_duration)` | `filter isNotNull(job_duration)` |
| `rex "Building <tempname>"` | `parse content, ... LD:tempname` |
| `rex remarks "OKメンテナンス中"` | `remark` field |
| Empty `job_result` for Functional jobs | Only `is_realtime` runs are counted |
| `replace(tempname," » ","/")` | `replaceString(tempname, " » ", "/")` |
| `lookup configuration job_name as name OUTPUT application, pager_duty` | `lookup /lookups/jenkins/configuration` |
| `where application="Claims ICM"` | `filter cfg.application == "Claims ICM"` |
| `streamstats ... where index<=2` | 2-hour window with `rt_fails >= 2 and rt_oks == 0` |
| `search event > 0 OR (status="OK" AND prev_status="NG")` | The problem opens on NG and closes on the first SUCCESS |
| Cron `*/3`, last 2 hours, expires 24 hours | The detector runs every minute over 2 hours |
| Triggered Alerts Medium and Alert Status Manager | `alert.severity` medium |

## Result

| Setting | Value |
|---|---|
| Resource | `icm_realtime_functional_ng` |
| Change | None |
| pagerduty.enabled | "0" (CONFIRM) |
| Apply | One folder only: 40, 64 or 65 |

## Data flow map

```
Jenkins (ceaa2099) statistics JSON (job_duration present, audit_trail dropped)
  → applications* = Functional, group-jobs* = Real Time
  → name = "Building ..." with " » " → "/"
  → lookup configuration → application == "Claims ICM"
  → per application+name in 2h: rt_fails >= 2 and rt_oks == 0
  → problem (medium, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `65-icm-ng-title-confirmed.tf` | Detector, same as seq 40 |
| `65-icm-ng-title-confirmed-check.dql` | Template shape and Claims ICM lookup rows |
| `65-icm-ng-title-confirmed.spl` | Saved search actions, including PagerDuty |
| `65.sh` | Commands |

## Commands

These are in `65.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/65-icm-ng-title-confirmed"
terraform init
terraform validate
terraform plan
terraform apply
```
