# NBWF Already Migrated

## Decision tree

```
Prod_Life_NBWF_RealTimeAndFunctionalCheck_NG (seen again)
 search changed? → no (application "NBWF", 2h, */1)
 new info? → Alert Status Manager email mode = Production (seq 32 could not see it)
 tf already final? → yes, seq 32 (has the audit_trail filter, severity high)
 → nothing to change; apply seq 32 (or this identical copy) from ONE folder
 PagerDuty Enable in Splunk? → set "1"; still not visible → "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is anything new? | Only a confirmation: the email mode is Production. |
| Which tf to use? | Seq 32. The tf in this folder is an identical copy. |
| Severity | high, now confirmed by the Production email. |
| PagerDuty | "0". The switch is still not visible. |

## Summary

NBWF's search and schedule match seq 32. The new screenshot shows the Alert Status Manager sends to Production, which supports severity high. The tf needs no change.

## Investigation

| What I checked | What I found |
|---|---|
| Application filter | `where application="NBWF"` |
| Time range and cron | Last 2 hours, every minute |
| Action | Alert Status Manager, Email Notification Mode Production |
| PagerDuty | Below the visible area |
| Seq 32 tf | Final, with the filter |

## Result

| Setting | Value |
|---|---|
| Resource | `nbwf_realtime_functional_ng` |
| tf | `42-nbwf-already-migrated-confirm.tf`, which is the same as seq 32 |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics → job_duration only, no audit_trail
  → lookup configuration → application == "NBWF"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high) → SUCCESS closes
```

## Related files

| File | What it is |
|---|---|
| `42-nbwf-already-migrated-confirm.tf` | A copy of the seq 32 detector |
| `42-nbwf-already-migrated-confirm-check.dql` | A copy of the seq 32 checks |
| `42-nbwf-already-migrated-confirm.spl` | A copy of the seq 32 Splunk checks |
| `42.sh` | Commands |

## Commands

These are in `42.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/32-nbwf-realtime-functional-ng-tf"
terraform init
terraform plan
terraform apply
```
