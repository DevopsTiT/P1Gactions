resource "dynatrace_davis_anomaly_detectors" "alj_cdus_pending_uploads" {
  title       = "ALJ_CDUS Pending uploads"
  description = "A user started an upload and has not completed the document."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-15m
| filter contains(aws.log.group, "/aws/lambda/document-upload-api-prod-createDocumentAction", caseSensitive:false)
| parse content, "LD 'action:' WORD:upload_action LD 'cmxDocumentId:' LD:cmx_document_id"
| summarize by: { cmx_document_id, upload_action }, seen = count()
| summarize started = countIf(contains(upload_action, "UPLOAD_STARTED", caseSensitive:false)), completed = countIf(contains(upload_action, "UPLOAD_COMPLETED", caseSensitive:false)), failed = countIf(contains(upload_action, "UPLOAD_FAILED", caseSensitive:false)), by: { cmx_document_id }
| fieldsAdd pending = started - completed - failed
| filter pending > 0
| summarize pending_docs = count()
| filter pending_docs > 5
| fieldsAdd alert_key = "cdus-pending-uploads"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_CDUS Pending uploads"
      }
      property {
        key   = "event.description"
        value = "ALJ_CDUS Pending uploads detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CDUS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_cdus_failed_uploads" {
  title       = "ALJ_CDUS Failed uploads"
  description = "A user failed to complete an upload. The file may not have reached CMX."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-15m
| filter contains(aws.log.group, "/aws/lambda/document-upload-api-prod-createDocumentAction", caseSensitive:false)
| parse content, "LD 'action:' WORD:upload_action LD 'cmxDocumentId:' LD:cmx_document_id"
| summarize by: { cmx_document_id, upload_action }, seen = count()
| summarize failed = countIf(contains(upload_action, "UPLOAD_FAILED", caseSensitive:false)), by: { cmx_document_id }
| filter failed > 0
| summarize failed_docs = count()
| filter failed_docs > 1
| fieldsAdd alert_key = "cdus-failed-uploads"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_CDUS Failed uploads"
      }
      property {
        key   = "event.description"
        value = "ALJ_CDUS Failed uploads detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CDUS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_cdus_database_error" {
  title       = "ALJ_CDUS Database error"
  description = "The document upload service cannot access the database."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-15m
| filter contains(aws.log.group, "/aws/lambda/document-upload-api-prod-", caseSensitive:false)
| filter contains(content, "Failed to init database", caseSensitive:false)
| filter contains(content, "ETIMEDOUT", caseSensitive:false) or contains(content, "ECONNREFUSED", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 1
| fieldsAdd alert_key = "cdus-database-error"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_CDUS Database error"
      }
      property {
        key   = "event.description"
        value = "ALJ_CDUS Database error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CDUS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_cdus_cmx_error" {
  title       = "ALJ_CDUS CMX error"
  description = "Failed to create a CMX document."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-15m
| filter contains(aws.log.group, "/aws/lambda/document-upload-api-prod-", caseSensitive:false)
| filter contains(content, "Failed to create CMX Document", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 1
| fieldsAdd alert_key = "cdus-cmx-error"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_CDUS CMX error"
      }
      property {
        key   = "event.description"
        value = "ALJ_CDUS CMX error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CDUS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_cdus_batch_error" {
  title       = "ALJ_CDUS Batch error"
  description = "A document upload batch completed with an error."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-15m
| filter contains(aws.log.group, "/aws/lambda/document-upload-api-prod-uploadOcr", caseSensitive:false)
    or contains(aws.log.group, "/aws/lambda/document-upload-api-prod-Worker", caseSensitive:false)
    or contains(aws.log.group, "/aws/lambda/document-upload-api-prod-rpaBatchProcess", caseSensitive:false)
    or contains(aws.log.group, "/aws/lambda/document-upload-api-prod-uploadBankAccountScannedImage", caseSensitive:false)
    or contains(aws.log.group, "/aws/lambda/document-upload-api-prod-uploadBankAccountCSVToIFT", caseSensitive:false)
    or contains(aws.log.group, "/aws/lambda/document-upload-api-prod-uploadBankAccountCameraImage", caseSensitive:false)
| filter contains(content, "Error Report", caseSensitive:false) or contains(content, "ExitError", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "cdus-batch-error"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_CDUS Batch error"
      }
      property {
        key   = "event.description"
        value = "ALJ_CDUS Batch error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CDUS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_cdus_alerting_profile" {
  name = "ALJ_CDUS Alerting Profile"

  rules {
    rule {
      include_mode     = "NONE"
      delay_in_minutes = 0
      severity_level   = "ERROR"
    }
  }

  filters {
    filter {
      custom {
        title {
          enabled        = true
          operator       = "BEGINS_WITH"
          value          = "ALJ_CDUS"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_cdus_upload" {
  name    = "ALJ_CDUS Upload alerts Email"
  profile = dynatrace_alerting.alj_cdus_alerting_profile.id
  subject = "[Dynatrace] ALJ_CDUS Upload alert"
  to = [
    "axa.jp_di_new_business@axa.co.jp",
    "jp.axa_jp_di_bam@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
