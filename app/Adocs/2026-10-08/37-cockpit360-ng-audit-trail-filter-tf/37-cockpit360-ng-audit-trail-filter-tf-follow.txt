# Cockpit360 NG Audit Trail Filter

## Decision tree

```
Prod_Life_Cockpit360ALL_RealTimeAndFunctionalCheck_NG (seen again)
 already migrated? → yes, seq 22
 what changed? → nothing in Splunk; seq 22 lacks the audit_trail filter from seq 26
 → seq 37 = seq 22 + filter, same resource name → in-place update
 applied seq 22 already? → apply seq 37 from its folder (state must be the same) or edit seq 22's tf
 PagerDuty Enable in Splunk? → set pagerduty "1"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same Cockpit360ALL alert as seq 22. |
| What is new? | The tf adds the audit_trail filter, so the detector skips millions of audit lines. |
| Will applying it create a second detector? | No. The resource name is the same, so it updates the existing one in place. |
| What did the screenshot confirm? | Application "Cockpit360", 2 hours, every minute, Alert Status Manager email Production. |
| PagerDuty? | Still not visible, so it stays "0". |

## Summary

The Splunk alert is unchanged from seq 22. The only update is on the Dynatrace side: the jenkins_statistics index is mostly audit_trail noise, so the seq 26 filter (`contains job_duration`, `not contains audit_trail`) is now in the Cockpit360 query too. The same filter is recommended for Compass (seq 24).

## Investigation

| What I checked | What I found |
|---|---|
| Alert name | Prod_Life_Cockpit360ALL_RealTimeAndFunctionalCheck_NG, the same as seq 22. |
| Application filter | `where application="Cockpit360"`. |
| Time range and cron | Last 2 hours, every minute. |
| Action | Alert Status Manager, Email Notification Mode Production. |
| PagerDuty | Below the visible area. |
| Seq 22 query | Starts with `parse content` and no audit_trail filter. |

## Result

| Setting | Value |
|---|---|
| Resource | `cockpit360_realtime_functional_ng` (unchanged) |
| Query change | Added `filter contains(content, "job_duration")` and `filter not contains(content, "audit_trail")` |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

Apply from one folder only. Terraform state lives per folder, so if seq 22 was already applied from its own folder, either copy seq 22's state or just paste these two filter lines into seq 22's tf.

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics logs (mostly audit_trail)
  → keep job_duration lines, drop audit_trail   ← new in seq 37
  → lookup configuration → application == "Cockpit360"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high)
  → next SUCCESS → closes
```

## Related files

| File | What it is |
|---|---|
| `37-cockpit360-ng-audit-trail-filter-tf.tf` | The updated detector |
| `37-cockpit360-ng-audit-trail-filter-tf-check.dql` | Lookup rows and build events |
| `37-cockpit360-ng-audit-trail-filter-tf.spl` | Splunk lookup and action checks |
| `37.sh` | Commands |

## Commands

These are in `37.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/37-cockpit360-ng-audit-trail-filter-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
