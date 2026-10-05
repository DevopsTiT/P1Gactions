# ALERT: Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal
# Lambda cmx-sharepoint-api-prod logged an error while transferring files from CMX to SharePoint

resource "dynatrace_davis_anomaly_detectors" "hpm_cmx_to_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
  description = "To check Lambda error: failure transferring files from CMX to SharePoint (cmx-sharepoint-api-prod)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cmx-sharepoint-api-prod"
          | filter contains(content, "Error", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "60"
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
        value = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda /aws/lambda/cmx-sharepoint-api-prod logged an error. Failure transferring files from CMX to SharePoint."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}
