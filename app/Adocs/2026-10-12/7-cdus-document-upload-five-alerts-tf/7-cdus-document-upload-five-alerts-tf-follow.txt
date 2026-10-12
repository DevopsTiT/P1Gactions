# CDUS Document Upload Five Alerts

## Decision tree

```
document-upload-api.tf (5 x "dynatrace_log_alert", all HIGH + PagerDuty)
 resource type not in provider → 5 x dynatrace_davis_anomaly_detectors
 all five page PagerDuty → check every query for false positives before apply
   Alert 1 and Alert 5 same query?      → yes → one error pages twice → keep one
   Alert 1 "Pending" searches errors?   → yes → name does not match what it finds
   Alert 2 matches normal upload lines? → check query 3 → if normal, add a failure word
   Alert 3 "ETIM" matches dateTime?     → check query 4 → use "ETIMEDOUT"
 Alert 5 throttle 8 hours → identity field only; widen window if pages repeat
 PagerDuty key in old file → removed; pagerduty.enabled "1"; rotate key if committed
 email to 2 lists → workflow (not copied)
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed? | All five resources became Records detectors in one file. |
| Severity and paging | All `high`, all `pagerduty.enabled = "1"`. |
| Window | All `from:now()-15m` (old `LAST_15_MINUTES`). |
| Biggest risk | Alerts 1 and 5 are duplicates, and Alerts 2 and 3 may match normal logs. All of them page. |
| Integration key | Not copied. Rotate it if the old file was ever committed. |

## Summary

The conversion itself is straightforward: same filters, 15-minute window, high severity, PagerDuty on. The real work is the query review, because a wrong match here wakes someone up. Two alerts are identical, one is named for something it does not detect, and two use filters that can match ordinary lines.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute and opens a problem when rows come back. | Replaces all five alerts. |
| `pagerduty.enabled = "1"` | Tells the workflow to page on-call. | Every false positive becomes a page. |
| `Runtime.ExitError` | Lambda message when the function process crashed or exited. | What Alerts 1 and 5 really detect. |
| `ETIMEDOUT` | Node.js error code for a network or database connection timeout. | What Alert 3's "ETIM" is trying to catch. |
| CMX | The document management system that uploads are sent to. | Alert 4 watches CMX document creation failures. |

### The five alerts

| Alert | Title | Log group | Content filter |
|---|---|---|---|
| 1 | HasDetectedPendingUploads_High | contains `/aws/lambda/document-upload-api` | "Error Report" or "ExitError" |
| 2 | HasDetectedFailedUploads_High | contains `/aws/lambda/document-upload-api-prod-createDocumentAction` | "action:" and "cmxDocumentId:" |
| 3 | HasDetectedDatabaseErrors_High | contains `/aws/lambda/document-upload-api-prod-` | "Failed to init database" or "ETIM" |
| 4 | HasDetectedCMXErrors_High | contains `/aws/lambda/document-upload-api-prod-` | "Failed to create CMX Document" |
| 5 | HasDetectedBatchError_High | contains `/aws/lambda/document-upload-api` | "Error Report" or "ExitError" |

All five: every 5 minutes, last 15 minutes, expires 30, results > 0, once, severity HIGH, PagerDuty, email Normal. Alert 5 also had an 8-hour throttle.

### Problems found

| Alert | Problem | Why it matters | Suggested fix |
|---|---|---|---|
| 1 and 5 | Identical query | One crash opens two problems and pages twice. | Keep Alert 5 (batch errors) and delete Alert 1, or give Alert 1 a real "pending" filter. |
| 1 | Named "Pending Uploads" but searches crash messages | On-call reads the wrong story. | Rename, or change the filter to the log line that shows a stuck upload. |
| 2 | "action:" and "cmxDocumentId:" can appear in every normal upload log | Could page on every successful upload. | Run query 3. If the lines are normal, add a failure word such as `"failed"` or `loglevel == "ERROR"`. |
| 3 | "ETIM" case-insensitive matches "dateTime", "lifetime" and similar words | Pages on normal JSON fields. | Use `contains(content, "ETIMEDOUT")`. |
| 5 | 8-hour throttle has no exact match | The detector closes 15 minutes after the last error and may reopen later. | If pages repeat, widen Alert 5 to `from:now()-8h`. |
| All | PagerDuty key in plain text | Anyone with it can open incidents. | Rotate the key if the old file was committed or shared. |

The `.tf` keeps the original filters so nothing changes silently. Apply the suggested fixes only after the check queries confirm them.

## Result

The full file is `7-cdus-document-upload-five-alerts-tf.tf`. Alert 1 in full:

```hcl
resource "dynatrace_davis_anomaly_detectors" "cdus_backend_pending_uploads" {
  title       = "Prod_Life_CDUS_Backend HasDetectedPendingUploads_High"
  description = "Alert when uploads are pending and not completing"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(aws.log_group, "/aws/lambda/document-upload-api")
          | filter contains(content, "Error Report", caseSensitive:false)
              or contains(content, "ExitError", caseSensitive:false)
        EOT
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
        value = "[PROD] Alert: Pending Uploads Detected"
      }
      property {
        key   = "event.description"
        value = "Pending uploads detected in document upload API. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "CDUS Backend"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
```

Alerts 2 to 5 use the same block. Only these parts change:

| Alert | Resource name | `event.name` |
|---|---|---|
| 2 | `cdus_backend_failed_uploads` | [PROD] Alert: Failed Uploads Detected |
| 3 | `cdus_backend_database_errors` | [PROD] Alert: Database Errors Detected |
| 4 | `cdus_backend_cmx_errors` | [PROD] Alert: CMX Errors Detected |
| 5 | `cdus_backend_batch_error` | [PROD] Alert: Batch Errors Detected |

Queries for Alerts 2 to 5:

```
// Alert 2
fetch logs, from:now()-15m
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:", caseSensitive:false)
| filter contains(content, "cmxDocumentId:", caseSensitive:false)

// Alert 3
fetch logs, from:now()-15m
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to init database", caseSensitive:false)
    or contains(content, "ETIM", caseSensitive:false)

// Alert 4
fetch logs, from:now()-15m
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to create CMX Document", caseSensitive:false)

// Alert 5 (same as Alert 1)
fetch logs, from:now()-15m
| filter contains(aws.log_group, "/aws/lambda/document-upload-api")
| filter contains(content, "Error Report", caseSensitive:false)
    or contains(content, "ExitError", caseSensitive:false)
```

Safer Alert 3 query, once query 4 confirms the noise:

```
fetch logs, from:now()-15m
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to init database", caseSensitive:false)
    or contains(content, "ETIMEDOUT")
```

### Before you apply

| Step | Why |
|---|---|
| Run query 1 | Lists the log groups the alerts watch. |
| Run query 2 | Shows how often Alerts 1 and 5 would page. |
| Run query 3 | Decides whether Alert 2 matches failures or normal uploads. |
| Run query 4 | Shows how many "ETIM" hits are not real timeouts. |
| Decide which of Alert 1 and Alert 5 to keep | Avoids double pages. |
| Rotate the PagerDuty key if the old file was committed | The key was in plain text. |
| Run `terraform validate` and `terraform plan` from `7.sh` | Checks the file before apply. |

## Data flow map

```
document-upload-api Lambdas write logs
  → CloudWatch Logs
  → Dynatrace Grail logs
  → 5 Records detectors, every minute, last 15 minutes
      Alert 1 crash lines            → problem (high)  ┐ same query,
      Alert 5 crash lines            → problem (high)  ┘ double page
      Alert 2 action + cmxDocumentId → problem (high)
      Alert 3 init database or ETIM  → problem (high)
      Alert 4 CMX create failed      → problem (high)
  → workflow: pagerduty.enabled = "1"
      → PagerDuty incident
      → email to the 2 distribution lists
```

## Related files

| File | What it is |
|---|---|
| `7-cdus-document-upload-five-alerts-tf.tf` | All five converted detectors |
| `7-cdus-document-upload-five-alerts-tf-check.dql` | Five check queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Problems found |
| `2-result.md` | Before-apply steps |
| `3-glossary.md` | Terms |
| `7.sh` | Commands |

## Commands

All commands are in [`7.sh`](7.sh). Nothing was run.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/7-cdus-document-upload-five-alerts-tf"
terraform init
terraform validate
terraform plan
```
