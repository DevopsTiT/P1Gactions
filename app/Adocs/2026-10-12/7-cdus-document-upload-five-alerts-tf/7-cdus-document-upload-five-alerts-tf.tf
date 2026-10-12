# Source: Migration/CW/configuration 2/document-upload-api.tf
#   Five "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   All rewritten as Records detectors (Davis anomaly detectors).
#
# All five had:
#   Cron */5 * * * *, last 15 minutes, expires 30, results > 0, once
#   Dynatrace problem severity HIGH → alert.severity = "high"
#   PagerDuty action → pagerduty.enabled = "1" (integration key NOT copied; the workflow sends the page)
#   Email to 2 distribution lists, priority Normal (not copied) → workflow
#   Alert 5 only: throttle 8 hours
#
# CONFIRM before apply (check.dql) — these page PagerDuty, so false positives wake people up:
#   1. Alert 1 and Alert 5 have the SAME query. One error will page twice. Keep one, or give them different filters.
#   2. Alert 1 is called "Pending Uploads" but searches "Error Report" / "ExitError". It does not detect pending uploads.
#   3. Alert 2 "Failed Uploads" matches lines with "action:" and "cmxDocumentId:". These may be NORMAL upload logs (query 3).
#   4. Alert 3 "ETIM" case-insensitive also matches words like "dateTime" and "lifetime" (query 4).
#      Safer: contains(content, "ETIMEDOUT").
#   5. The PagerDuty integration key was in the old file in plain text. If it was ever committed or shared, rotate it.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ==============================================
# ALERT 1: Pending Uploads (pending > 0)
# ==============================================
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

# ==============================================
# ALERT 2: Failed Uploads (failed > 0)
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "cdus_backend_failed_uploads" {
  title       = "Prod_Life_CDUS_Backend HasDetectedFailedUploads_High"
  description = "Alert when uploads have failed"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
          | filter contains(content, "action:", caseSensitive:false)
          | filter contains(content, "cmxDocumentId:", caseSensitive:false)
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
        value = "[PROD] Alert: Failed Uploads Detected"
      }
      property {
        key   = "event.description"
        value = "Failed uploads detected in document upload API. See the matching log lines (content) on the problem."
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

# ==============================================
# ALERT 3: Database Connection Errors
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "cdus_backend_database_errors" {
  title       = "Prod_Life_CDUS_Backend HasDetectedDatabaseErrors_High"
  description = "Alert when database connection errors occur"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
          | filter contains(content, "Failed to init database", caseSensitive:false)
              or contains(content, "ETIM", caseSensitive:false)
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
        value = "[PROD] Alert: Database Errors Detected"
      }
      property {
        key   = "event.description"
        value = "Database errors detected in document upload API. See the matching log lines (content) on the problem."
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

# ==============================================
# ALERT 4: CMX Document Creation Errors
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "cdus_backend_cmx_errors" {
  title       = "Prod_Life_CDUS_Backend HasDetectedCMXErrors_High"
  description = "Alert when CMX document creation fails"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
          | filter contains(content, "Failed to create CMX Document", caseSensitive:false)
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
        value = "[PROD] Alert: CMX Errors Detected"
      }
      property {
        key   = "event.description"
        value = "CMX errors detected in document upload API. See the matching log lines (content) on the problem."
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

# ==============================================
# ALERT 5: Batch Processing Errors
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "cdus_backend_batch_error" {
  title       = "Prod_Life_CDUS_Backend HasDetectedBatchError_High"
  description = "Alert when batch processing errors occur"
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
        value = "[PROD] Alert: Batch Errors Detected"
      }
      property {
        key   = "event.description"
        value = "Batch errors detected in document upload API. See the matching log lines (content) on the problem."
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
