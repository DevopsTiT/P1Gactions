resource "dynatrace_davis_anomaly_detectors" "alj_bre_innorules_error" {
  title       = "ALJ_BRE Innorules error"
  description = "Alert when logs from innorules contain loglevel error."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter contains(index, "innorules", caseSensitive:false)
| filter loglevel == "ERROR" or contains(content, "ERROR", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "bre-innorules-error"
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
        value = "ALJ_BRE Innorules error"
      }
      property {
        key   = "event.description"
        value = "ALJ_BRE Innorules error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_BRE"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_bre_alerting_profile" {
  name = "ALJ_BRE Alerting Profile"

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
          value          = "ALJ_BRE"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}
