resource "dynatrace_davis_anomaly_detectors" "alj_eip_eip006_service_failure" {
  title       = "ALJ_EIP EIP006 service failure"
  description = "This alert checks EIP006 services that depend on the backend provider system IWFM."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-1m
| filter contains(content, "jp-Distributing-Sell-GenerateFormImage-v2-vs", caseSensitive:false)
| filter contains(content, "FAILURE", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 2
| fieldsAdd alert_key = "eip006-iwfm-service-failure"
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
        value = "ALJ_EIP EIP006 service failure"
      }
      property {
        key   = "event.description"
        value = "ALJ_EIP EIP006 service failure detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_EIP"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_eip_alerting_profile" {
  name = "ALJ_EIP Alerting Profile"

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
          value          = "ALJ_EIP"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_eip_eip006_service_failure" {
  name                   = "ALJ_EIP EIP006 service failure Email"
  profile                = dynatrace_alerting.alj_eip_alerting_profile.id
  subject                = "[Dynatrace] ALJ_EIP EIP006 service failure"
  to                     = ["alj_jp_di_infra_mwss@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_davis_anomaly_detectors" "alj_compass_iwfm_report_exception" {
  title       = "ALJ_COMPASS IWFMReportException発生"
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
| filter contains(content, "IWFMReportException", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 15
| fieldsAdd alert_key = "compass-iwfm-report-exception"
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
        value = "ALJ_COMPASS IWFMReportException発生"
      }
      property {
        key   = "event.description"
        value = "ALJ_COMPASS IWFMReportException発生 detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_COMPASS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_compass_alerting_profile" {
  name = "ALJ_COMPASS Alerting Profile"

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
          value          = "ALJ_COMPASS"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_compass_iwfm_report_exception" {
  name                   = "ALJ_COMPASS IWFMReportException発生 Email"
  profile                = dynatrace_alerting.alj_compass_alerting_profile.id
  subject                = "[Dynatrace] ALJ_COMPASS IWFMReportException発生"
  to                     = ["axa.jp_di_compass_it_member@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_davis_anomaly_detectors" "alj_iwfm_errors" {
  title       = "ALJ_IWFM Errors"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-1h
| filter contains(content, "LOGLEVEL", caseSensitive:false)
| filter contains(content, "Caution", caseSensitive:false) or contains(content, "Fatal", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "iwfm-errors"
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
        value = "ALJ_IWFM Errors"
      }
      property {
        key   = "event.description"
        value = "ALJ_IWFM Errors detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_IWFM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_iwfm_alerting_profile" {
  name = "ALJ_IWFM Alerting Profile"

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
          value          = "ALJ_IWFM"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_iwfm_errors" {
  name                   = "ALJ_IWFM Errors Email"
  profile                = dynatrace_alerting.alj_iwfm_alerting_profile.id
  subject                = "[Dynatrace] ALJ_IWFM Errors"
  to                     = ["rajukolukuluri@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
