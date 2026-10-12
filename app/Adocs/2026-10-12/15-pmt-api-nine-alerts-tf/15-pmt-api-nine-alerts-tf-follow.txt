# PMT API Nine Alerts

## Decision tree

```
pmt-api.tf (9 x "dynatrace_log_alert")
 resource type not in provider → 9 Records detectors (one resource with for_each)
 Alert 2 memory parse: LD:MemoryUsage takes the rest of the line?
   yes → toLong() is null → alert never fires → FIXED with INT
 Alerts 6 and 7 same query? → yes → one exception, two problems → keep one
 Alert 9 "occured" vs title "occurred"? → check query 3 → fix spelling if logs say "occurred"
 Alert 3 "Task timed out" → any pmt-api function, not only transformation
 60-second throttles → shorter than the window → no real effect
 email Normal or problem MEDIUM, no PagerDuty → medium, pagerduty.enabled "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | All nine resources became Records detectors, written as one resource with `for_each`. |
| Severity | Medium for all. |
| PagerDuty | Off for all. |
| Fixed in the file | Alert 2's memory parse, which could never fire before. |
| Still to decide | Remove one of Alerts 6 and 7, and check Alert 9's spelling. |

## Summary

pmt-api has nine log alerts that all watch the same Lambda log groups. Seven move over unchanged. Alert 2 had a parse bug that made it silent, so the file fixes it. Alerts 6 and 7 are duplicates, and Alert 9 may never match because of a spelling difference between the filter and the real log text.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| `for_each` | Terraform loop that creates one resource per map entry. | Nine near-identical blocks become one block plus a list. |
| Lambda REPORT line | The summary line AWS writes after each invocation, including `Max Memory Used: 123 MB`. | Alert 2 reads memory from it. |
| `LD:name` | Parse pattern that captures any text up to the end. | Captured "123 MB Init Duration: ..." instead of a number. |
| `INT:name` | Parse pattern that captures a whole number only. | The fix for Alert 2. |
| SFDC | Salesforce. | Alert 5 watches calls to its API. |

### The nine alerts

| Alert | Title | Content filter | Window | Old action |
|---|---|---|---|---|
| 1 | Unexpected Error | "Unexpected error", not "sfdc" | 5 minutes | Email |
| 2 | STP APIs Memory Usage over 480MB | "Max Memory Used", then memory > 480 | 5 minutes | Email |
| 3 | TransFormation Timeout | "Task timed out" | 6 minutes | Email |
| 4 | SendApprovalReminder handler failed | same text | 5 minutes | Email |
| 5 | pmt-api SFDC Error | "An error occurred while calling sfdc api" | 5 minutes | Email (subject [pmt-api] SFDC処理失敗のお知らせ) |
| 6 | Exception in myAxaMailSender | "Exception in myAxaMailSender" | 5 minutes | Problem MEDIUM |
| 7 | Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal | "Exception in myAxaMailSender" | 5 minutes | Problem MEDIUM |
| 8 | Exception in ExportData for Datalake | "Exception in ExportData" | 5 minutes | Email |
| 9 | Error occurred during email sending process for this user | "Error occured during email sending process for this user" | 5 minutes | Email |

All filters ignore case. All log group filters are shortened to one `contains(aws.log_group, "pmt-api")`.

### Problems found

| Alert | Problem | What the file does |
|---|---|---|
| 2 | `LD:MemoryUsage` captures "123 MB Init Duration: ...", so `toLong()` is null and the alert never fires. | Fixed: `parse content, "LD 'Max Memory Used:' SPACE? INT:MemoryUsage"` then `filter MemoryUsage > 480`. |
| 6 and 7 | Same query. One exception opens two problems. | Kept both. Delete one; Alert 7 has the better name and description. |
| 9 | Filter says "occured", title says "occurred". | Kept as written. Query 3 shows which spelling the app logs. |
| 3 | "Task timed out" matches any pmt-api function. | Kept as written. The title suggests only the transformation step. |
| 4, 6, 7, 8, 9 | Throttle of 60 seconds. | Dropped. It is shorter than the 5-minute window, so it never mattered. |

## Result

The full file is `15-pmt-api-nine-alerts-tf.tf`. The nine queries sit in a `locals` map, and one resource builds a detector for each:

```hcl
resource "dynatrace_davis_anomaly_detectors" "pmt_api" {
  for_each = local.pmt_api_alerts

  title       = each.value.title
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = "${each.value.description} See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "pmt-api"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
```

The fixed Alert 2 query:

```
fetch logs, from:now()-5m
| filter contains(aws.log_group, "pmt-api")
| filter contains(content, "Max Memory Used", caseSensitive:false)
| parse content, "LD 'Max Memory Used:' SPACE? INT:MemoryUsage"
| filter MemoryUsage > 480
```

To remove the duplicate, delete the `pmt_api_exception_myaxa_mail_sender` entry from the `locals` map. If query 3 shows "occurred", change Alert 9's filter text to "Error occurred during email sending process for this user".

### Before you apply

| Step | Why |
|---|---|
| Run query 2 in the check file | Shows the old parse returning null and the fixed parse returning numbers. |
| Run query 3 | Decides Alert 9's spelling. |
| Run query 4 | Shows how often each alert text appeared in 30 days. |
| Delete one of Alerts 6 and 7 | Avoids duplicate problems. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `15.sh` | Checks the file before apply. |

## Data flow map

```
pmt-api Lambdas write logs (including REPORT lines)
  → CloudWatch Logs
  → Dynatrace Grail logs
  → 9 Records detectors, every minute, last 5 minutes (Alert 3: 6 minutes)
      text match, or memory > 480 MB (Alert 2) → problem (medium)
      Alerts 6 and 7 → same match → two problems
  → workflow: pagerduty.enabled = "0" → email
```

## Related files

| File | What it is |
|---|---|
| `15-pmt-api-nine-alerts-tf.tf` | All nine detectors (one resource with `for_each`) |
| `15-pmt-api-nine-alerts-tf-check.dql` | Log group, memory parse, spelling and hit-count checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Problems found |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `15.sh` | Commands |

## Commands

All commands are in [`15.sh`](15.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/15-pmt-api-nine-alerts-tf"
terraform init
terraform validate
terraform plan
```
