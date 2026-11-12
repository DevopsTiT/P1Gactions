resource "dynatrace_davis_anomaly_detectors" "alj_hpm_sharepoint_lambda_error" {
  title       = "ALJ_HPM SharePoint Lambda error"
  description = "Failure while transferring files between S3 and SharePoint."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-24h
| filter index == "hpm-sharepoint-api"
| filter loglevel == "ERROR" or contains(message, "ERROR", caseSensitive:false) or contains(content, "ERROR", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "hpm-sharepoint-lambda-error"
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
        value = "ALJ_HPM SharePoint Lambda error"
      }
      property {
        key   = "event.description"
        value = "ALJ_HPM SharePoint Lambda error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_HPM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_hpm_alerting_profile" {
  name = "ALJ_HPM Alerting Profile"

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
          value          = "ALJ_HPM"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_hpm_sharepoint_lambda_error" {
  name    = "ALJ_HPM SharePoint Lambda error Email"
  profile = dynatrace_alerting.alj_hpm_alerting_profile.id
  subject = "[Dynatrace] ALJ_HPM SharePoint Lambda error"
  to = [
    "naoya.sota@axa.co.jp",
    "chungyueh.chiu@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
