# FCR Already Migrated

## Decision tree

```
Prod_Life_FCR_RealTimeAndFunctionalCheck_NG (seen a third time)
 Splunk search changed? → no, still where application="FCR"
 tf already final? → yes, seq 26 (has the audit_trail filter)
 → nothing to change; apply seq 26 (or this identical copy) from ONE folder
 PagerDuty Enable in Splunk? → set pagerduty "1"; still not visible → "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is anything new? | Only a confirmation: the action is Alert Status Manager, email Production. |
| Which tf to use? | Seq 26. The tf in this folder is an identical copy. |
| Does the tf need changes? | No. |
| PagerDuty? | Still not visible, so it stays "0". |

## Summary

The FCR alert matches what seq 25 and seq 26 already migrated. Seq 26 already has the audit_trail filter, so the detector is final. This folder only records the Production email confirmation.

## Investigation

| What I checked | What I found |
|---|---|
| Application filter | `where application="FCR"`, unchanged. |
| Time range and cron | Last 2 hours, every minute, unchanged. |
| Action | Alert Status Manager, Email Notification Mode Production. |
| PagerDuty | Below the visible area. |
| Seq 26 tf | Already has the job_duration and audit_trail filters. |

## Result

| Setting | Value |
|---|---|
| Resource | `fcr_realtime_functional_ng` |
| tf | `39-fcr-already-migrated-confirm.tf`, which is the same as seq 26 |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

Apply from one folder only. Seq 26 and this folder declare the same resource.

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics → job_duration only, no audit_trail
  → lookup configuration → application == "FCR"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high) → SUCCESS closes
```

## Related files

| File | What it is |
|---|---|
| `39-fcr-already-migrated-confirm.tf` | A copy of the seq 26 detector |
| `39-fcr-already-migrated-confirm-check.dql` | A copy of the seq 26 checks |
| `39-fcr-already-migrated-confirm.spl` | A copy of the seq 26 Splunk checks |
| `39.sh` | Commands |

## Commands

These are in `39.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/26-fcr-ng-audit-trail-filter-tf"
terraform init
terraform plan
terraform apply
```
