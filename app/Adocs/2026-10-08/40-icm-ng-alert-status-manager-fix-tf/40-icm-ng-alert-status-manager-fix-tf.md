# Claims ICM Alert Status Manager Fix

## Decision tree

```
Prod_Life_ICM_RealTimeAndFunctionalCheck_NG (seen again)
 search changed? → no (application "Claims ICM", 2h, */3)
 actions? → Add to Triggered Alerts (Severity Medium) + Alert Status Manager
   → seq 30 said "Triggered Alerts only" → wrong → seq 40 fixes the notes
 severity? → medium (the Severity Splunk sets)
 PagerDuty Enable on Alert Status Manager? → set "1"; not visible → "0"
 apply → one folder only (same resource as seq 30)
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | There is a second action, Alert Status Manager, that seq 30 missed. |
| Does the query change? | No. |
| Severity? | Stays medium, because Splunk sets Severity Medium on the triggered alert. |
| PagerDuty? | "0" until you see the Alert Status Manager PagerDuty switch. |
| Resource | `icm_realtime_functional_ng`, the same as seq 30, so it is an in-place update. |

## Summary

The Claims ICM search is unchanged. Seq 30 concluded nobody was notified because only "Add to Triggered Alerts" was visible. This screenshot shows an Alert Status Manager action under it, so the team does get notified. The tf query and severity stay the same. The notes and the confirmation step now point at the Alert Status Manager PagerDuty setting.

## Investigation

| What I checked | What I found |
|---|---|
| Application filter | `where application="Claims ICM"`, unchanged. |
| Time range and cron | Last 2 hours, `*/3`, unchanged. |
| Action 1 | Add to Triggered Alerts, Severity Medium. |
| Action 2 | Alert Status Manager. Its settings are below the visible area. |
| Seq 30 claim | "Only Add to Triggered Alerts", which is corrected here. |

## Result

| Setting | Value |
|---|---|
| Resource | `icm_realtime_functional_ng` |
| Query | Unchanged from seq 30, already has the audit_trail filter |
| Severity | medium |
| pagerduty.enabled | "0", pending the Alert Status Manager check |

Apply from one folder only (seq 30 or seq 40).

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics → job_duration only, no audit_trail
  → lookup configuration → application == "Claims ICM"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (medium)
  → next SUCCESS → closes
```

## Related files

| File | What it is |
|---|---|
| `40-icm-ng-alert-status-manager-fix-tf.tf` | The detector with corrected notes |
| `40-icm-ng-alert-status-manager-fix-tf-check.dql` | Lookup and build event checks |
| `40-icm-ng-alert-status-manager-fix-tf.spl` | Splunk lookup and action checks |
| `40.sh` | Commands |

## Commands

These are in `40.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/40-icm-ng-alert-status-manager-fix-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
