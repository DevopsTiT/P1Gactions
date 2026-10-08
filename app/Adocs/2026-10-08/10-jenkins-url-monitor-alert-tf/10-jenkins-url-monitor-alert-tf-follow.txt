# Jenkins URL Monitor Alert

## Decision tree

```
Splunk: Application Monitoring Alert - URL
 Source: Jenkins console logs, lines with "[HTTP Monitor]"
  name = Jenkins job path (source without "job/" and build number)
  responsecode = HTTP status from the line
  application = lookup configuration (job_name → application, pager_duty)
 Splunk logic: last 2 runs per check → status NG if not 200
  NG twice              → alert
  OK after NG           → recovery email
 Dynatrace (Records detector, last 15 min):
  fails >= 2 and no 200 → problem per application + name
  first 200 arrives     → oks > 0 → row disappears → problem closes (= recovery)
 Paging: configuration.pager_duty
  0      → no_page detector (pagerduty "0")
  other  → page detector (pagerduty "1")
 Macros check_maintenance_window, add_alert_info → definitions unknown → not migrated
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | Jenkins jobs that call application URLs every minute and log the HTTP status |
| When does it fire? | A URL check failed at least twice in the last 15 minutes and never returned 200 |
| One problem per | Application and check name |
| Recovery | The problem closes on the first 200 response |
| Why two keys in the file? | To split paging by the `pager_duty` column in the configuration lookup |
| Changed from 2026-10-05 seq 34 | Records analyzer instead of `makeTimeseries`, own file, paging split without placeholders |
| Severity | high |

## Summary

Jenkins jobs ping application URLs and write `[HTTP Monitor]` lines with the response code. The Splunk alert keeps the last two results per check and alerts when both failed, then sends a recovery when an OK follows. The Dynatrace detector counts failed and OK results per check over 15 minutes and opens a problem when there are two or more failures and no success.

## Splunk query line by line

| Splunk part | What it means | DQL |
|---|---|---|
| `index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]"` | Jenkins console lines from URL checks | `contains(log.source, "/console")` and `contains(content, "[HTTP Monitor]")` |
| `eval name=replace(source,"job/","")`, `replace(name,"%20"," ")`, `replace(name,"/\d+/console","")` | Job path without "job/", spaces fixed, build number removed | `replaceString` twice, then `parse src, "LD:name '/' INT '/console'"` |
| `rename status as responsecode` | HTTP status of the check | `parse content, "LD 'status' LD INT:responsecode"` |
| `lookup configuration job_name as name OUTPUT application` | Map job to application and paging flag | `lookup [ load "/lookups/jenkins/configuration" ] ...` |
| `streamstats count as index by name \| where index<=2` | Keep the last 2 runs per check | Replaced by counting in a 15-minute window |
| `eval status=if(Response_Code="200","OK","NG")` | NG when not 200 | `countIf(responsecode != 200)` |
| `search status="NG" OR (status="OK" AND prev_status="NG")` | Alert, or recovery | Problem opens, and closes on a 200 |
| `check_maintenance_window`, `add_alert_info` | Splunk macros (definitions not shown) | Not migrated; ask for definitions |

## Difference from Splunk to know

| Splunk | Dynatrace | Effect |
|---|---|---|
| Last 2 runs both NG | 2 or more NG and no OK in 15 minutes | Same for a check that runs every few minutes; a flapping check (NG, OK, NG) will not alert |
| Recovery email | Problem closes | The standard flow sends the close notification |

## Terraform

File: `10-jenkins-url-monitor-alert-tf.tf`

```hcl
locals {
  jenkins_url_base_query = <<-EOT
    fetch logs, from:now()-15m
    | filter contains(log.source, "/console")
    | filter contains(content, "[HTTP Monitor]")
    | fieldsAdd src = replaceString(replaceString(log.source, "job/", ""), "%20", " ")
    | parse src, "LD:name '/' INT '/console'"
    | parse content, "LD 'status' LD INT:responsecode"
    | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
    | fieldsAdd application = coalesce(cfg.application, "-"), pager_duty = coalesce(toString(cfg.pager_duty), "1")
    | summarize fails = countIf(responsecode != 200), oks = countIf(responsecode == 200),
                last_code = takeLast(responsecode), last_seen = max(timestamp),
                by:{ application, name, pager_duty }
    | filter fails >= 2 and oks == 0
  EOT

  jenkins_url_alerts = {
    page    = { title = "Application Monitoring Alert - URL",                   filter = "pager_duty != \"0\"", pagerduty = "1" }
    no_page = { title = "Application Monitoring Alert - URL (no PagerDuty)",    filter = "pager_duty == \"0\"", pagerduty = "0" }
  }
}

resource "dynatrace_davis_anomaly_detectors" "jenkins_url_monitor" {
  for_each = local.jenkins_url_alerts
  # Records analyzer
  # query.expression       = base query + "| filter <each.value.filter>"
  # alertIdentityFields[0] = application
  # alertIdentityFields[1] = name
  # severity high, app.name "Jenkins URL Monitor", pagerduty.enabled = each.value.pagerduty
}
```

## Data flow

```
Jenkins URL check job (every minute) → console log "[HTTP Monitor] ... status 200/500"
 → Dynatrace logs → detector every minute (last 15 min)
   → parse name + responsecode → lookup application, pager_duty
     → fails >= 2 and oks == 0 → problem (application + name)
        pager_duty 0 → email only;  otherwise → PagerDuty
     → first 200 → problem closes
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 (Edit Alert) | Full search shown above; cron `*/1`; Last 15 minutes; results > 0 |
| 2 (jenkins_console search) | 2 million events; sourcetypes `jenkins_console` (99.8%) and `json:jenkins:old`; host ceaa2099; sources like `job/TEST/job/Jenkins_FunctionalCheck_Test/30021/console` |
| Earlier version | 2026-10-05 seq 34 used `makeTimeseries` and `{dims:...}` placeholders |

## Result

| Step | What to do |
|---|---|
| 1 | Run check queries 1 and 2 to confirm the source format and where the status code is |
| 2 | Upload the Splunk `configuration` lookup as `/lookups/jenkins/configuration` and run query 3 |
| 3 | Run query 4 to see parsed names and fail counts |
| 4 | Ask for the `check_maintenance_window` macro; if it matters, add a maintenance filter |
| 5 | If seq 34 was applied, remove its `jenkins_url_check_failed` entry before applying this |

## Related files

| File | Purpose |
|---|---|
| `10-jenkins-url-monitor-alert-tf.tf` | Detectors (page and no_page) |
| `10-jenkins-url-monitor-alert-tf-check.dql` | Check queries |
| `10.sh` | Commands |

## Commands

See `10.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/10-jenkins-url-monitor-alert-tf"
terraform init
terraform validate
terraform plan
```
