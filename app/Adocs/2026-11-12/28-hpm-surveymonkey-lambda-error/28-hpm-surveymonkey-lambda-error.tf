resource "dynatrace_davis_anomaly_detectors" "alj_hpm_surveymonkey_lambda_error" {
  title       = "ALJ_HPM SurveyMonkey Lambda error"
  description = "Failure while transferring files from SurveyMonkey to S3."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-60m
| filter index == "hpm-survey-monkey"
| filter loglevel == "ERROR" or contains(message, "ERROR", caseSensitive:false) or contains(content, "ERROR", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "hpm-surveymonkey-lambda-error"
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
        value = "ALJ_HPM SurveyMonkey Lambda error"
      }
      property {
        key   = "event.description"
        value = "ALJ_HPM SurveyMonkey Lambda error detected"
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
