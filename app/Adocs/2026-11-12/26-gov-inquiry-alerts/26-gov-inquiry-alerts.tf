resource "dynatrace_davis_anomaly_detectors" "alj_gov_mdm_file_summary" {
  title       = "ALJ_GOV MDM file summary"
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
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb", caseSensitive:false)
| filter contains(content, "Biz file summary", caseSensitive:false)
| filter contains(content, "MDM_SEARCH_RESULT_FILE", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-mdm-file-summary"
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
        value = "ALJ_GOV MDM file summary"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV MDM file summary detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_gov_nd_file_summary" {
  title       = "ALJ_GOV ND file summary"
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
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb", caseSensitive:false)
| filter contains(content, "Biz file summary", caseSensitive:false)
| filter contains(content, "ND_SEARCH_RESULT_FILE", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-nd-file-summary"
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
        value = "ALJ_GOV ND file summary"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV ND file summary detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_gov_answer_file_summary" {
  title       = "ALJ_GOV Answer file summary"
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
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-buildAnswerFile", caseSensitive:false)
| filter contains(content, "Biz file summary", caseSensitive:false)
| filter contains(content, "ANSWER_FILE", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-answer-file-summary"
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
        value = "ALJ_GOV Answer file summary"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV Answer file summary detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_gov_request_file_summary" {
  title       = "ALJ_GOV Request file summary"
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
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer", caseSensitive:false)
| filter contains(content, "Biz file summary", caseSensitive:false)
| filter contains(content, "REQUEST_FILE", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-request-file-summary"
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
        value = "ALJ_GOV Request file summary"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV Request file summary detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_gov_general_error" {
  title       = "ALJ_GOV General error"
  description = "A General Error occurred in the gov-inquiry-system."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-logFailure", caseSensitive:false)
| filter contains(content, "level:ERROR", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-general-error"
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
        value = "ALJ_GOV General error"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV General error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_gov_pipitlinq_error_file" {
  title       = "ALJ_GOV PipItLinq error file"
  description = "An answer error file is transferred from pipItLINQ."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb", caseSensitive:false)
| filter contains(content, "ParseErrorFileAndUpdateDb", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-pipitlinq-error-file"
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
        value = "ALJ_GOV PipItLinq error file"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV PipItLinq error file detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_gov_syserror_file" {
  title       = "ALJ_GOV SYSERROR file"
  description = "A system error file is transferred from the kyodo GW."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter contains(aws.log.group, "/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb", caseSensitive:false)
| filter contains(content, "parseGatewaySysErrorFileAndUpdateDbEffect", caseSensitive:false)
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "gov-syserror-file"
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
        value = "ALJ_GOV SYSERROR file"
      }
      property {
        key   = "event.description"
        value = "ALJ_GOV SYSERROR file detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GOV"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_gov_alerting_profile" {
  name = "ALJ_GOV Alerting Profile"

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
          value          = "ALJ_GOV"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_gov_inquiry" {
  name                   = "ALJ_GOV Inquiry alerts Email"
  profile                = dynatrace_alerting.alj_gov_alerting_profile.id
  subject                = "[Dynatrace] ALJ_GOV Gov inquiry alert"
  to                     = ["alj_jp_di_maintenance_operation_digital@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
