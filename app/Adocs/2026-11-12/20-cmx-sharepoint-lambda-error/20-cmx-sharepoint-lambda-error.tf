resource "dynatrace_davis_anomaly_detectors" "alj_cmx_sharepoint_lambda_error" {
  title       = "ALJ_CMX SharePoint Lambda error"
  description = "Failure while transferring files from CMX to SharePoint."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-1h
| filter index == "cmx-sharepoint-api"
| filter contains(message, "Error", caseSensitive:false) or contains(content, "Error", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "cmx-sharepoint-lambda-error"
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
        value = "ALJ_CMX SharePoint Lambda error"
      }
      property {
        key   = "event.description"
        value = "ALJ_CMX SharePoint Lambda error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CMX"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_cmx_alerting_profile" {
  name = "ALJ_CMX Alerting Profile"

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
          value          = "ALJ_CMX"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_cmx_sharepoint_lambda_error" {
  name    = "ALJ_CMX SharePoint Lambda error Email"
  profile = dynatrace_alerting.alj_cmx_alerting_profile.id
  subject = "[Dynatrace] ALJ_CMX SharePoint Lambda error"
  to = [
    "naoya.sota@axa.co.jp",
    "chungyuah.chiu@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
