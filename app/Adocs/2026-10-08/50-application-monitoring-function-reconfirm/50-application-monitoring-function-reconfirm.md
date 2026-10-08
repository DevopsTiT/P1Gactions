# Application Monitoring Function Reconfirm

## Decision tree

```
Application Monitoring Alert - function (shown again)
 search same as seq 36/47? → yes
 time range / cron? → Last 120 minutes, */1 → same
 action? → Alert Status Manager, Production → severity high, pagerduty "0"
 where pager_duty="0"? → yes → covers every non-PagerDuty app
 sourcetype="json:jenkins:old" on jenkins_statistics alive?
   → Splunk line 1 (.spl) → has events → Splunk alert works
   → 0 events → Splunk alert is silent like the URL alert (Dynatrace has no sourcetype filter, so tf unaffected)
 → no tf change: reuse seq 36/47 tf (enabled = true)
 → same resource name application_monitoring_alert_function → apply from ONE folder only
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 36 and 47. |
| Anything changed? | No. The search, the 120-minute window, the `*/1` cron and the Alert Status Manager action all match. |
| Which tf to use? | The seq 47 tf, unchanged. |
| Severity and PagerDuty | high and "0" |
| One thing to verify | That `json:jenkins:old` still has events in `jenkins_statistics` (Splunk side only). |

## Summary

These screenshots show the same function alert again, so the tf stays as it was. The Dynatrace detector opens one problem per application and job when a Functional Jenkins job has 2 or more non-SUCCESS results in 2 hours with no SUCCESS, for apps whose configuration has `pager_duty = "0"`. The only open question is on the Splunk side: whether the `json:jenkins:old` sourcetype is still alive in `jenkins_statistics`. In `jenkins_console` that sourcetype is only 0.245% of events, which suggests it is a legacy name. That doesn't affect the Dynatrace tf.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index=jenkins_statistics sourcetype="json:jenkins:old"`, job_name `applications*` or `group-jobs*`. This matches seq 47. |
| Maintenance subsearch | `jenkins_console`, source `job/applications/job/*`, "Application is in mantenance" (Splunk's spelling). It is joined on build_url and has no sourcetype filter, so it still works. |
| Lookup filter | `where pager_duty="0"`, so no application filter. |
| Last line | `search event > 0 OR (status="OK" AND prev_status="NG")`. |
| What `event > 0` means | `event` is the number of job results, so it is true for almost every job. Splunk emits a row per job every minute, and Alert Status Manager decides from the status whether to mail. |
| Dynatrace equivalent | It opens a problem when the check is NG and closes it when a SUCCESS returns, so there is no per-minute noise. |
| Schedule | `*/1`, last 120 minutes, expires 24 hours, for each result, no throttle. |
| Action | Alert Status Manager, Production email. I did not copy the recipients. |

## Result

| Setting | Value |
|---|---|
| Resource | `application_monitoring_alert_function` (same as seq 36/47, an in-place update) |
| enabled | true |
| Identity | application, name |
| Opens when | `fn_fails >= 2 and fn_oks == 0` in 120 minutes |
| Maintenance note | `remarks` and `in_maintenance` are shown on the problem but not filtered, the same as in Splunk |
| Severity | high |
| pagerduty.enabled | "0" |

## Data flow map

```
Jenkins (ceaa2099) build stats JSON (job_duration, job_name, job_result, build_url)
  → filter applications* / group-jobs*, drop audit_trail
  → lookup: jenkins_console "Application is in mantenance" by build_url → maintenance_note
  → name from "Building <tempname>" (» → /)
  → lookup /lookups/jenkins/configuration → application, pager_duty
  → keep pager_duty == "0"
  → per application+name: fn_fails >= 2 and fn_oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `50-application-monitoring-function-reconfirm.tf` | Copy of the seq 47 tf, unchanged |
| `50-application-monitoring-function-reconfirm-check.dql` | build_url, maintenance lines, pager_duty 0 apps |
| `50-application-monitoring-function-reconfirm.spl` | Sourcetype check (new first two lines) plus the earlier checks |
| `50.sh` | Commands |

## Commands

These are in `50.sh`. Nothing has been run. Apply from one folder only.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/50-application-monitoring-function-reconfirm"
terraform init
terraform validate
terraform plan
terraform apply
```
