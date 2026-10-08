# Compass NG Audit Trail Filter

## Decision tree

```
Prod_Life_Compass_RealTimeAndFunctionalCheck_NG (seen again)
 already migrated? → yes, seq 24
 what changed? → nothing in Splunk; seq 24 lacks the audit_trail filter from seq 26
 → seq 38 = seq 24 + filter, same resource name → in-place update
 applied seq 24 already? → paste the 2 filter lines into seq 24's tf, or apply only from seq 38
 confused with Compass PB? → different alert ("Compass AG", jenkins/test, seq 27)
 PagerDuty Enable in Splunk? → set pagerduty "1"
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same Compass alert as seq 24. |
| What is new? | The tf adds the audit_trail filter. |
| Will it create a second detector? | No. The resource name `compass_realtime_functional_ng` is the same. |
| What did the screenshot confirm? | Application "Compass", 2 hours, every minute, Alert Status Manager email Production. |
| PagerDuty? | Still not visible, so it stays "0". |

## Summary

The Splunk alert matches seq 24. Like Cockpit360 in seq 37, the only change is the Dynatrace query: it now keeps only build lines with `job_duration` and drops `audit_trail` lines before parsing. With this, all jenkins_statistics detectors have the filter.

## Investigation

| What I checked | What I found |
|---|---|
| Alert name | Prod_Life_Compass_RealTimeAndFunctionalCheck_NG, the same as seq 24. |
| Application filter | `where application="Compass"`. |
| Time range and cron | Last 2 hours, every minute. |
| Action | Alert Status Manager, Email Notification Mode Production. |
| PagerDuty | Below the visible area. |
| Seq 24 query | No audit_trail filter. |

## Result

| Setting | Value |
|---|---|
| Resource | `compass_realtime_functional_ng` (unchanged) |
| Query change | Added the job_duration and audit_trail filters |
| Severity | high |
| pagerduty.enabled | "0", pending confirmation |

### Status of the jenkins_statistics family

| Alert | Folder with the filter |
|---|---|
| Cockpit360 | Seq 37 |
| Compass | Seq 38 |
| FCR | Seq 26 |
| Claims ICM | Seq 30 |
| MyAXA | Seq 31 |
| NBWF | Seq 32 |
| PDWF | Seq 33 |
| Application Monitoring Alert - function | Seq 36 |

## Data flow map

```
Jenkins (ceaa2099) → jenkins_statistics logs (mostly audit_trail)
  → keep job_duration lines, drop audit_trail   ← new in seq 38
  → lookup configuration → application == "Compass"
  → rt_fails >= 2 and rt_oks == 0 → Davis problem (high)
  → next SUCCESS → closes
```

## Related files

| File | What it is |
|---|---|
| `38-compass-ng-audit-trail-filter-tf.tf` | The updated detector |
| `38-compass-ng-audit-trail-filter-tf-check.dql` | Lookup rows and build events |
| `38-compass-ng-audit-trail-filter-tf.spl` | Splunk lookup and action checks |
| `38.sh` | Commands |

## Commands

These are in `38.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/38-compass-ng-audit-trail-filter-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
