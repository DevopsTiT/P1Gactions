resource "dynatrace_davis_anomaly_detectors" "alj_etool_lambda_error" {
  title       = "ALJ_ETOOL Lambda error"
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
| filter index == "eopt-serverless"
| filter loglevel == "ERROR" or contains(content, "ERROR", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "etool-lambda-error"
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
        value = "ALJ_ETOOL Lambda error"
      }
      property {
        key   = "event.description"
        value = "ALJ_ETOOL Lambda error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_ETOOL"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_etool_alerting_profile" {
  name = "ALJ_ETOOL Alerting Profile"

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
          value          = "ALJ_ETOOL"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_etool_lambda_error" {
  name                   = "ALJ_ETOOL Lambda error Email"
  profile                = dynatrace_alerting.alj_etool_alerting_profile.id
  subject                = "[Dynatrace] ALJ_ETOOL Lambda error"
  to                     = ["alj_jp_di_etool_maintenance@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_davis_anomaly_detectors" "alj_eopt_serverless_error" {
  title       = "ALJ_EOPT Serverless error"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-24h
| filter index == "eopt-serverless"
| filter loglevel == "ERROR" or contains(content, "ERROR", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "eopt-serverless-error"
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
        value = "ALJ_EOPT Serverless error"
      }
      property {
        key   = "event.description"
        value = "ALJ_EOPT Serverless error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_EOPT"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_eopt_alerting_profile" {
  name = "ALJ_EOPT Alerting Profile"

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
          value          = "ALJ_EOPT"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_eopt_serverless_error" {
  name    = "ALJ_EOPT Serverless error Email"
  profile = dynatrace_alerting.alj_eopt_alerting_profile.id
  subject = "[Dynatrace] ALJ_EOPT Serverless error"
  to = [
    "alj_jp_di_etool_maintenance@axa.co.jp",
    "chungyueh.chiu@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
