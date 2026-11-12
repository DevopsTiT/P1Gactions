resource "dynatrace_davis_anomaly_detectors" "alj_etool_ri_monitoring_error" {
  title       = "ALJ_ETOOL RI monitoring error"
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
| filter index == "recruitimp-serverless"
| parse content, "LD WORD '-' WORD '-' WORD '-' WORD '\t' WORD:loglevel"
| filter loglevel == "ERROR"
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "recruitimp-ri-monitoring-error"
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
        value = "ALJ_ETOOL RI monitoring error"
      }
      property {
        key   = "event.description"
        value = "ALJ_ETOOL RI monitoring error detected"
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

resource "dynatrace_davis_anomaly_detectors" "alj_eopt_recruitimp_serverless_error" {
  title       = "ALJ_EOPT recruitimp serverless error"
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
| filter index == "recruitimp-serverless"
| parse content, "LD 'level:' WORD:raw_level"
| filter upper(raw_level) == "ERROR"
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "recruitimp-aws-serverless-error"
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
        value = "ALJ_EOPT recruitimp serverless error"
      }
      property {
        key   = "event.description"
        value = "ALJ_EOPT recruitimp serverless error detected"
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
