# MyAXA Already Migrated

## Decision tree

```
Prod_Life_MyAXA_RealTimeAndFunctionalCheck_NG (seen again)
 search changed? → no (application "MyAXA", 2h, */1)
 actions changed? → no (Alert Status Manager, email Production)
 tf already final? → yes, seq 31 (has the audit_trail filter)
 → nothing to change; apply seq 31 (or this identical copy) from ONE folder
 PagerDuty Enable in Splunk? → set "1"; still not visible → "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is anything new? | No. The screenshots match seq 31. |
| Which tf to use? | Seq 31. The tf in this folder is an identical copy. |
| Severity | high |
| PagerDuty | "0". The Alert Status Manager PagerDuty switch is still not visible. |

## Summary

MyAXA's search, schedule and action all match seq 31, and the seq 31 tf already has the audit_trail filter. No change is needed. Only the PagerDuty switch is still unconfirmed.

## Investigation

| What I checked | What I found |
|---|---|
| Application filter | `where application="MyAXA"` |
| Time range and cron | Last 2 hours, every minute |
| Action | Alert Status Manager, email Production |
| PagerDuty | Below the visible area |
| Seq 31 tf | Final, with the filter |

## Result

| Setting | Value |
|---|---|
| Resource | `myaxa_realtime_functional_ng` |
| tf | `41-myaxa-already-migrated-confirm.tf`, which is the same as seq 31 |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics → job_duration only, no audit_trail
  → lookup configuration → application == "MyAXA"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high) → SUCCESS closes
```

## Related files

| File | What it is |
|---|---|
| `41-myaxa-already-migrated-confirm.tf` | A copy of the seq 31 detector |
| `41-myaxa-already-migrated-confirm-check.dql` | A copy of the seq 31 checks |
| `41-myaxa-already-migrated-confirm.spl` | A copy of the seq 31 Splunk checks |
| `41.sh` | Commands |

## Commands

These are in `41.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/31-myaxa-realtime-functional-ng-tf"
terraform init
terraform plan
terraform apply
```
