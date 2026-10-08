# PDWF Already Migrated

## Decision tree

```
Prod_Life_PDWF_RealTimeAndFunctionalCheck_NG (seen again)
 search changed? → no (application "PDWF", 2h, */1)
 actions changed? → no (Alert Status Manager, email Production)
 tf already final? → yes, seq 33 (has the audit_trail filter)
 → nothing to change; apply seq 33 (or this identical copy) from ONE folder
 PagerDuty Enable in Splunk? → set "1"; still not visible → "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is anything new? | No. The screenshots match seq 33. |
| Which tf to use? | Seq 33. The tf in this folder is an identical copy. |
| Severity | high |
| PagerDuty | "0". The switch is still not visible. |

## Summary

PDWF's search, schedule and action all match seq 33, and the seq 33 tf already has the audit_trail filter. No change is needed.

## Investigation

| What I checked | What I found |
|---|---|
| Application filter | `where application="PDWF"` |
| Time range and cron | Last 2 hours, every minute |
| Action | Alert Status Manager, email Production |
| PagerDuty | Below the visible area |
| Seq 33 tf | Final, with the filter |

## Result

| Setting | Value |
|---|---|
| Resource | `pdwf_realtime_functional_ng` |
| tf | `43-pdwf-already-migrated-confirm.tf`, which is the same as seq 33 |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics → job_duration only, no audit_trail
  → lookup configuration → application == "PDWF"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high) → SUCCESS closes
```

## Related files

| File | What it is |
|---|---|
| `43-pdwf-already-migrated-confirm.tf` | A copy of the seq 33 detector |
| `43-pdwf-already-migrated-confirm-check.dql` | A copy of the seq 33 checks |
| `43-pdwf-already-migrated-confirm.spl` | A copy of the seq 33 Splunk checks |
| `43.sh` | Commands |

## Commands

These are in `43.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/33-pdwf-realtime-functional-ng-tf"
terraform init
terraform plan
terraform apply
```
