resource "dynatrace_davis_anomaly_detectors" "alj_sfdc_api_error" {
  title       = "ALJ_SFDC API error"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "An error occurred while calling sfdc api", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-sfdc-api-error"
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
        value = "ALJ_SFDC API error"
      }
      property {
        key   = "event.description"
        value = "ALJ_SFDC API error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_SFDC"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_pmt_unexpected_error" {
  title       = "ALJ_PMT unexpected error"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "Unexpected errors", caseSensitive:false)
| filter not(contains(content, "sfdc", caseSensitive:false))
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-unexpected-error"
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
        value = "ALJ_PMT unexpected error"
      }
      property {
        key   = "event.description"
        value = "ALJ_PMT unexpected error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_PMT"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_pmt_transformation_timeout" {
  title       = "ALJ_PMT transformation timeout"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-6m
| filter index == "pmt-api"
| filter contains(content, "Task timed out", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-transformation-timeout"
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
        value = "ALJ_PMT transformation timeout"
      }
      property {
        key   = "event.description"
        value = "ALJ_PMT transformation timeout detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_PMT"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_pmt_approval_reminder" {
  title       = "ALJ_PMT SendApprovalReminder failed"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "SendApprovalReminder handler failed", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-approval-reminder-failed"
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
        value = "ALJ_PMT SendApprovalReminder failed"
      }
      property {
        key   = "event.description"
        value = "ALJ_PMT SendApprovalReminder failed detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_PMT"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_stp_memory_over_480" {
  title       = "ALJ_STP memory over 480MB"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "Max Memory Used", caseSensitive:false)
| parse content, "LD '+Used:' SPACE* LONG:memory_usage"
| filter memory_usage > 480
| summarize hot_count = count()
| filter hot_count > 0
| fieldsAdd alert_key = "pmt-memory-over-480"
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
        value = "ALJ_STP memory over 480MB"
      }
      property {
        key   = "event.description"
        value = "ALJ_STP memory over 480MB detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_STP"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_mailsender_exception" {
  title       = "ALJ_MAILSENDER exception in myAxaMailSender"
  description = "This alert is used for Detecting the exception in MyAxa Mail sender"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "Exception in myAxaMailSender", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-emma-mailsender"
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
        value = "ALJ_MAILSENDER exception in myAxaMailSender"
      }
      property {
        key   = "event.description"
        value = "ALJ_MAILSENDER exception in myAxaMailSender detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_MAILSENDER"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_pmt_mailsender_exception" {
  title       = "ALJ_PMT exception in myAxaMailSender"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "Exception in myAxaMailSender", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-mailsender-exception"
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
        value = "ALJ_PMT exception in myAxaMailSender"
      }
      property {
        key   = "event.description"
        value = "ALJ_PMT exception in myAxaMailSender detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_PMT"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_stp_exportdata" {
  title       = "ALJ_STP ExportData exception"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "Exception in ExportData", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-exportdata-exception"
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
        value = "ALJ_STP ExportData exception"
      }
      property {
        key   = "event.description"
        value = "ALJ_STP ExportData exception detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_STP"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_pmt_email_sending_error" {
  title       = "ALJ_PMT email sending error"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "pmt-api"
| filter contains(content, "Error occured during email sending process for this user", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "pmt-email-sending-error"
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
        value = "ALJ_PMT email sending error"
      }
      property {
        key   = "event.description"
        value = "ALJ_PMT email sending error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_PMT"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_sfdc_alerting_profile" {
  name = "ALJ_SFDC Alerting Profile"

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
          value          = "ALJ_SFDC"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_alerting" "alj_pmt_alerting_profile" {
  name = "ALJ_PMT Alerting Profile"

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
          value          = "ALJ_PMT"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_alerting" "alj_stp_alerting_profile" {
  name = "ALJ_STP Alerting Profile"

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
          value          = "ALJ_STP"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_sfdc" {
  name    = "ALJ_SFDC Email"
  profile = dynatrace_alerting.alj_sfdc_alerting_profile.id
  subject = "[Dynatrace] ALJ_SFDC SFDC API error"
  to = [
    "ALJ_JP_DI_operations@axa.co.jp",
    "TS_JP_DI_applications@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_email_notification" "alj_pmt" {
  name    = "ALJ_PMT Email"
  profile = dynatrace_alerting.alj_pmt_alerting_profile.id
  subject = "[Dynatrace] ALJ_PMT pmt-api alert"
  to = [
    "alj_jp_di_processautomation@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_email_notification" "alj_stp" {
  name    = "ALJ_STP Email"
  profile = dynatrace_alerting.alj_stp_alerting_profile.id
  subject = "[Dynatrace] ALJ_STP pmt-api alert"
  to = [
    "koichi.nagamine@axa.co.jp",
    "alj_jp_di_processautomation@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
