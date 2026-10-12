# Gov Inquiry System Seven Alerts

## Decision tree

```
gov-inquiry-system.tf (7 x "dynatrace_log_alert")
 resource type not in provider → 7 x dynatrace_davis_anomaly_detectors
 Alert 2 unreadable (rotated, blurry)? → placeholder, enabled = false → need a straight screenshot
 file summary alerts (1, 2, 3, 7)?
   information, not failure → severity low
   parse fileName → one problem per file
   WORD:fileName cuts at "." and "-" → check query 2 → NSPACE if names have dots
 error alerts (4, 5, 6)? → severity medium, one problem per log group
 sort and limit 100? → removed
 all: email only, no PagerDuty → pagerduty.enabled "0"
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | All seven resources became Records detectors in one file. |
| Window | All `from:now()-5m` (old `LAST_5_MINUTES`). |
| Severity | Low for the four file-summary notices; medium for the three error notices. |
| PagerDuty | Off for all. |
| Blocker | Alert 2 could not be read. It is a disabled placeholder until you send a clear screenshot. |

## Summary

This system sends two kinds of email: "a file was processed, here are its counts" (Alerts 1, 2, 3, 7) and "an error happened" (Alerts 4, 5, 6). Both kinds move into Records detectors with the same filters. The summary ones parse the file name and counts, and open one low-severity problem per file. Alert 2's details were unreadable, so it is disabled with a placeholder query.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces all seven alerts. |
| `parse` with `LD 'name:' INT:name` | Skips text until `name:`, then reads a number into a field. | How the counts are pulled out of the log line. |
| `WORD` | Parse pattern for letters, digits and underscore only. | Stops at "." or "-", so file names can be cut short. |
| `NSPACE` | Parse pattern for everything up to the next space. | Safer for file names with dots. |
| `alertIdentityFields = fileName` | One problem per file name. | Each processed file gets its own notice, like the old email rows. |

### The seven alerts

| Alert | Title | Lambda (log group suffix) | Content filter | Kind |
|---|---|---|---|---|
| 1 | ND file detailed summary | parseNdAndUpdateDb | "Biz file summary" and "fileCategory:ND_SEARCH_RESULT_FILE" | Summary |
| 2 | answer file detailed summary | Unreadable | Unreadable | Summary |
| 3 | request file detailed summary | validateAndComputeAnswer (read from rotated photo) | "Biz file summary" and "fileCategory:REQUEST_FILE" (read from rotated photo) | Summary |
| 4 | General Error | logFailure (read from rotated photo) | "level:ERROR" | Error |
| 5 | Error File Processing | parseErrorFileAndUpdateDb | "ParseErrorFileAndUpdateDB" | Error |
| 6 | System Error File Processing | parseSysErrorFileAndUpdateDb | "parseGatewaySysErrorFileAndUpdateDbEffect" | Error |
| 7 | MDM file summary | parseMdmResponseAndUpdateDb | "Biz file summary" | Summary |

All seven: every 5 minutes, last 5 minutes, expires 24, results > 0, once, no throttle, email to one distribution list (not copied).

### Parsed fields

| Alert | Fields kept |
|---|---|
| 1 | timestamp, fileName, searchResultCount, noContractCount, contractExistsCount |
| 3 | timestamp, fileName, requestingGovernmentCount, contractRequestCount, precheckResultCount |

### Things to know

| Point | What it means |
|---|---|
| Alert 2 is a placeholder | Its log group and `fileCategory` say `REPLACE_ME`, and `enabled = false`. Send a straight screenshot of lines 50 to 95, or run query 3 to find the answer-file log line. |
| Rotated-photo values | Alert 3's log group and file category and Alert 4's log group were read sideways. Query 1 lists the real log group names. |
| File names may be cut | `WORD:fileName` stops at "." and "-". If query 2 shows names like `ND_20261012.csv`, change `WORD` to `NSPACE` in Alerts 1 to 3. |
| Summary alerts as problems | A Dynatrace problem for "file processed" is unusual. Low severity keeps them out of error views. If the team only wants the email, a scheduled workflow is a cleaner home. |
| Case-sensitive matches | No filter has `caseSensitive:false`, the same as the original. |

## Result

The full file is `9-gov-inquiry-system-seven-alerts-tf.tf`. Every alert uses the same block layout as before (analyzer, identity field, event template, `execution_settings {}`). The parts that differ:

| Alert | Resource name | Severity | Identity field | `event.name` |
|---|---|---|---|---|
| 1 | `gov_inquiry_nd_file_detailed_summary` | low | fileName | [Gov Inquiry System] ND file detailed summary |
| 2 | `gov_inquiry_answer_file_detailed_summary` (disabled) | low | fileName | [Gov Inquiry System] answer file detailed summary |
| 3 | `gov_inquiry_request_file_detailed_summary` | low | fileName | [Gov Inquiry System] request file detailed summary |
| 4 | `gov_inquiry_general_error` | medium | aws.log_group | gov-inquiry-system: General Error |
| 5 | `gov_inquiry_error_file_processing` | medium | aws.log_group | gov-inquiry-system: error file processing |
| 6 | `gov_inquiry_system_error_file_processing` | medium | aws.log_group | gov-inquiry-system: system error file |
| 7 | `gov_inquiry_mdm_file_summary` | low | aws.log_group | [Gov Inquiry System] MDM file summary |

Alert 1 in full:

```hcl
resource "dynatrace_davis_anomaly_detectors" "gov_inquiry_nd_file_detailed_summary" {
  title       = "[gov-inquiry-system] ND file detailed summary"
  description = "Extract ND file summary with detailed metrics"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb")
          | filter contains(content, "Biz file summary")
          | filter contains(content, "fileCategory:ND_SEARCH_RESULT_FILE")
          | parse content, "LD 'fileName:' WORD:fileName"
          | parse content, "LD 'searchResultCount:' INT:searchResultCount"
          | parse content, "LD 'noContractCount:' INT:noContractCount"
          | parse content, "LD 'contractExistsCount:' INT:contractExistsCount"
          | fields timestamp, fileName, searchResultCount, noContractCount, contractExistsCount
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "fileName"
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
        value = "[Gov Inquiry System] ND file detailed summary"
      }
      property {
        key   = "event.description"
        value = "ND search result file processed. See fileName, searchResultCount, noContractCount and contractExistsCount on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "gov-inquiry-system"
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

Queries for Alerts 2 to 7:

```
// Alert 2 (PLACEHOLDER, enabled = false)
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-REPLACE_ME")
| filter contains(content, "Biz file summary")
| filter contains(content, "fileCategory:REPLACE_ME")
| parse content, "LD 'fileName:' WORD:fileName"
| fields timestamp, fileName

// Alert 3
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer")
| filter contains(content, "Biz file summary")
| filter contains(content, "fileCategory:REQUEST_FILE")
| parse content, "LD 'fileName:' WORD:fileName"
| parse content, "LD 'requestingGovernmentCount:' INT:requestingGovernmentCount"
| parse content, "LD 'contractRequestCount:' INT:contractRequestCount"
| parse content, "LD 'precheckResultCount:' INT:precheckResultCount"
| fields timestamp, fileName, requestingGovernmentCount, contractRequestCount, precheckResultCount

// Alert 4
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-logFailure")
| filter contains(content, "level:ERROR")

// Alert 5
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb")
| filter contains(content, "ParseErrorFileAndUpdateDB")

// Alert 6
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb")
| filter contains(content, "parseGatewaySysErrorFileAndUpdateDbEffect")

// Alert 7
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb")
| filter contains(content, "Biz file summary")
```

### Before you apply

| Step | Why |
|---|---|
| Send a straight screenshot of Alert 2 (lines 50 to 95) | Finishes the placeholder. |
| Run query 1 | Confirms all log group names, including the ones read sideways. |
| Run query 2 | Shows the real `fileCategory` values and whether file names contain dots. |
| Run query 3 | Helps find Alert 2's log line if no screenshot is available. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `9.sh` | Checks the file before apply. |

## Data flow map

```
gov-inquiry-system Lambdas write logs
  → CloudWatch Logs
  → Dynatrace Grail logs
  → 7 Records detectors, every minute, last 5 minutes
      Summary (1, 2, 3, 7): "Biz file summary" → parse counts → problem (low), one per file
      Errors (4, 5, 6): error markers         → problem (medium), one per log group
  → workflow: pagerduty.enabled = "0" → email to the maintenance distribution list
```

## Related files

| File | What it is |
|---|---|
| `9-gov-inquiry-system-seven-alerts-tf.tf` | All seven detectors (Alert 2 disabled) |
| `9-gov-inquiry-system-seven-alerts-tf-check.dql` | Log group, file category, Alert 2 and error-rate checks |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | What was read and what is uncertain |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `9.sh` | Commands |

## Commands

All commands are in [`9.sh`](9.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/9-gov-inquiry-system-seven-alerts-tf"
terraform init
terraform validate
terraform plan
```
