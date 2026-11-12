resource "dynatrace_davis_anomaly_detectors" "testdummy_cloudwatch_logs" {
  title       = "TESTDUMMY cloudwatch logs"
  description = "Dummy. Disable after the problem shows."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-2h
| filter contains(aws.log_group, "/aws/", caseSensitive:false)
| summarize log_count = count()
| filter log_count > 0
| fieldsAdd alert_key = "testdummy-cloudwatch"
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
        value = "TESTDUMMY cloudwatch logs"
      }
      property {
        key   = "event.description"
        value = "TESTDUMMY cloudwatch logs detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "dt.source_entity"
        value = "HOST-00026D8D201D203A"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
