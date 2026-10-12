# Source: Migration/CW/configuration 2/cmx-sharepoint-api.tf (resource "dynatrace_log_alert" "hpm_cmx_to_sharepoint_api_lambda_error")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#
# Original settings:
#   Cron 0 * * * * (hourly), last 60 minutes, expires 7, results > 0, once
#   Throttle 60 minutes
#   Action Dynatrace problem, severity MEDIUM → alert.severity = "medium"
#   No PagerDuty action → pagerduty.enabled = "0"
#   Action email → handled by the workflow / notification (recipients not copied)
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group value for /aws/lambda/cmx-sharepoint-api (query 1)
#   2. "Error" case-insensitive also matches lines like "errorCount=0". Check query 2 for noise.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "hpm_cmx_to_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal"
  description = "To check Lambda error: failure error of transferring files from CMX to SharePoint."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter contains(aws.log_group, "/aws/lambda/cmx-sharepoint-api")
          | filter contains(content, "Error", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "Lambda cmx-sharepoint-api logged an error while transferring files from CMX to SharePoint. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "HPM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
