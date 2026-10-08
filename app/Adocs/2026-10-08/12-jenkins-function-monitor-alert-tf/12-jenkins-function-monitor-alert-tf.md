# Jenkins Function Monitor Alert

## Decision tree

```
Splunk: Application Monitoring Alert - function (generic)
 Source: jenkins_statistics json:jenkins:old, job_name applications* or group-jobs*
  host fixed → ceaa2099
 Which apps? → lookup configuration → where pager_duty = "0"
  (apps with paging have their own "function for X" alerts)
 Logic: last 2 runs per job → NG if no SUCCESS → alert; OK after NG → recovery
  Dynatrace: fails >= 2 and no SUCCESS in 120 min → problem per application + job
             first SUCCESS → problem closes
 Action: Alert Status Manager, email Production, PagerDuty Disable → pagerduty "0"
 Maintenance join + macros → definitions unknown → not migrated (check query 4)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | Jenkins functional test jobs (applications and Real Time group jobs) |
| Which applications? | Only those with `pager_duty = 0` in the configuration lookup |
| When does it fire? | The job failed 2 or more times in 120 minutes with no SUCCESS |
| One problem per | Application and job |
| Recovery | Closes on the first SUCCESS |
| PagerDuty | `"0"` (Splunk shows PagerDuty Notification Disable) |
| Host | Fixed: ceaa2099 |
| Open questions | JSON keys in Dynatrace, group-jobs result field, maintenance macro |

## Summary

This is the catch-all functional alert for applications that do not page. It reads Jenkins job statistics, keeps the last two runs per job, and emails when both failed, plus a recovery when a run succeeds again. The Dynatrace detector does the same with counts over 120 minutes and closes the problem on the first success.

## Splunk query line by line

| Splunk part | What it means | DQL |
|---|---|---|
| `index=jenkins_statistics sourcetype="json:jenkins:old"` | Jenkins job statistics as JSON | `matchesValue(host.name, "ceaa2099*")`, `contains(content, "job_name")`, `parse content, "JSON:j"` |
| `(job_name=applications* OR job_name=group-jobs*)` | Application jobs and Real Time group jobs | `matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")` |
| `where isnotnull(job_duration)` | Only finished builds | `filter isNotNull(job_duration)` |
| `join type=left build_url [ ... "Application is in mantenance" ... ]` | Mark builds where the app was in maintenance | Not migrated; check query 4 |
| `rex ... testname` | Test name for group jobs | Not used; problem shows job_name |
| `lookup configuration ... OUTPUT application, pager_duty` | Map job to application | `lookup [ load "/lookups/jenkins/configuration" ]` |
| `where pager_duty="0"` | Only non-paging applications | `filter toString(cfg.pager_duty) == "0"` |
| `streamstats ... where index<=2` | Last 2 runs per job | Counting in the 120-minute window |
| `status=if(... "SUCCESS" ...,"OK","NG")` | NG when no success | `countIf(job_result != "SUCCESS")` |
| `search event > 0 OR (status="OK" AND prev_status="NG")` | Alert or recovery | Problem opens; closes on SUCCESS |

## Terraform

File: `12-jenkins-function-monitor-alert-tf.tf`

```hcl
resource "dynatrace_davis_anomaly_detectors" "jenkins_function_monitor" {
  title   = "Application Monitoring Alert - function"
  enabled = true
  source  = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-120m
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "job_name")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), job_duration = j[job_duration]
          | filter matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")
          | filter isNotNull(job_duration)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:job_name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter toString(cfg.pager_duty) == "0"
          | fieldsAdd application = coalesce(cfg.application, "-")
          | summarize fails = countIf(job_result != "SUCCESS"), oks = countIf(job_result == "SUCCESS"),
                      last_result = takeLast(job_result), last_seen = max(timestamp),
                      by:{ application, job_name }
          | filter fails >= 2 and oks == 0
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "application"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "job_name"
      }
    }
  }
  # event_template: CUSTOM_ALERT, severity high, app.name Jenkins Functional Monitor, pagerduty.enabled "0"
}
```

## What is not migrated

| Splunk piece | Why | What to do |
|---|---|---|
| Maintenance join (`Application is in mantenance` in console) | Builds in maintenance are only labelled in Splunk; the macro probably suppresses them | Get the `check_maintenance_window` definition; check query 4 shows such builds |
| Test-level result for group-jobs | Real Time group jobs may not set `job_result` | Check query 3; if empty, add a test-status branch |
| `add_alert_info` macro | Definition not shown | Ask the owner |

## Data flow

```
Jenkins ceaa2099 → job statistics JSON → Dynatrace logs
 → detector every minute (120 min)
   → applications* or group-jobs*, finished builds
   → lookup application, keep pager_duty 0
   → per application + job: fails >= 2, no SUCCESS → problem → email (no PagerDuty)
   → first SUCCESS → problem closes
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 and 2 (search) | Full search above; `where pager_duty="0"`; ends with `search event > 0 OR (status="OK" AND prev_status="NG")` |
| 2 and 3 (settings) | `*/1`, Last 120 minutes, > 0, Once, no throttle; Alert Status Manager, email Production, PagerDuty Disable |
| 4 (index search) | `jenkins_statistics json:jenkins:old` has 844,158 events; host ceaa2099; many are audit_trail events, not job results |
| Earlier version | 2026-10-05 seq 34 mapped the function family with makeTimeseries |

## Result

| Step | What to do |
|---|---|
| 1 | Run check queries 1 and 2 to confirm the job events and JSON keys |
| 2 | Run check query 3 for group-jobs results |
| 3 | Upload `/lookups/jenkins/configuration` |
| 4 | Ask for `check_maintenance_window` and `add_alert_info` definitions |
| 5 | If seq 34 was applied, remove its `jenkins_functional_check_failed` entry first |

## Related files

| File | Purpose |
|---|---|
| `12-jenkins-function-monitor-alert-tf.tf` | Detector |
| `12-jenkins-function-monitor-alert-tf-check.dql` | Check queries |
| `12.sh` | Commands |

## Commands

See `12.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/12-jenkins-function-monitor-alert-tf"
terraform init
terraform validate
terraform plan
```
