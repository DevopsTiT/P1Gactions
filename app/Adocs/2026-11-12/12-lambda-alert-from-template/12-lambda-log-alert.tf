resource "dynatrace_davis_anomaly_detectors" "light_digital_confirm_e_signature_error" {
  title       = "ALJ_OCP4 Lambda confirm-e-signature ERROR"
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
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log.group"
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
        value = "ALJ_OCP4 Lambda confirm-e-signature ERROR"
      }
      property {
        key   = "event.description"
        value = "ALJ_OCP4 Lambda confirm-e-signature ERROR detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "light-digital-api-dev-confirm-e-signature"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
