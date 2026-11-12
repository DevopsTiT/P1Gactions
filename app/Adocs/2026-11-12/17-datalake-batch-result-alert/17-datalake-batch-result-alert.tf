resource "dynatrace_davis_anomaly_detectors" "alj_datalake_batch_result" {
  title       = "ALJ_DATALAKE Batch result"
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
| filter index == "batch_monitoring_logs"
| summarize result_count = count()
| filter result_count > 0
| fieldsAdd alert_key = "datalake-batch-result"
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
        value = "ALJ_DATALAKE Batch result"
      }
      property {
        key   = "event.description"
        value = "ALJ_DATALAKE Batch result detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_DATALAKE"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_datalake_alerting_profile" {
  name = "ALJ_DATALAKE Alerting Profile"

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
          value          = "ALJ_DATALAKE"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_datalake_batch_result" {
  name                   = "ALJ_DATALAKE Batch result Email"
  profile                = dynatrace_alerting.alj_datalake_alerting_profile.id
  subject                = "[Dynatrace] ALJ_DATALAKE Batch result"
  to                     = ["masayuki.yasuda@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
