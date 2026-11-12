resource "dynatrace_davis_anomaly_detectors" "alj_msgbox_emma_errors" {
  title       = "ALJ_MSGBOX Emma Life errors"
  description = "Catch unexpected errors related to Emma Life MsgBox."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "message-box-api"
| filter loglevel == "ERROR" or loglevel == "WARN" or contains(content, "ERROR", caseSensitive:false) or contains(content, "WARN", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 5
| fieldsAdd alert_key = "emma-msgbox-error"
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
        value = "ALJ_MSGBOX Emma Life errors"
      }
      property {
        key   = "event.description"
        value = "ALJ_MSGBOX Emma Life errors detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_MSGBOX"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_msgbox_alerting_profile" {
  name = "ALJ_MSGBOX Alerting Profile"

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
          value          = "ALJ_MSGBOX"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_msgbox_emma_errors" {
  name                   = "ALJ_MSGBOX Emma Life errors Email"
  profile                = dynatrace_alerting.alj_msgbox_alerting_profile.id
  subject                = "[Dynatrace] ALJ_MSGBOX Emma Life errors"
  to                     = ["paste-the-teams-address-from-the-form"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
