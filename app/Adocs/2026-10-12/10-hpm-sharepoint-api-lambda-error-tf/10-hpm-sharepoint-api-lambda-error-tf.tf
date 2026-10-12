# Source: Migration/CW/configuration 2/hpm-sharepoint-api.tf (resource "dynatrace_log_alert" "hpm_sharepoint_api_lambda_error")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#
# Original settings:
#   Cron 0 10 * * * (daily 10:00), last 24 hours, expires 7, results > 0, once
#   Throttle 60 minutes
#   Action Dynatrace problem, severity MEDIUM → alert.severity = "medium"
#   No PagerDuty action → pagerduty.enabled = "0"
#   Action email (3 recipients, not copied) → workflow
#
# NOTE: a detector cannot run "once a day at 10:00". It checks every minute over the last 24 hours,
#   so a problem opens soon after the first error and stays open until 24 hours after the last one.
#   For a 10:00 daily digest email, use a scheduled workflow instead.
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group value for /aws/lambda/hpm-sharepoint-api (query 1)
#   2. "ERROR" case-insensitive also matches "error" inside normal text (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "hpm_sharepoint_api_lambda_error" {
  title       = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
  description = "To check Lambda error: failure error of transferring files from S3 to SharePoint and SharePoint to S3."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "/aws/lambda/hpm-sharepoint-api")
          | filter contains(content, "ERROR", caseSensitive:false)
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
        value = "Prod_Life_HPM_SharepointAPILambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda hpm-sharepoint-api logged an error while transferring files between S3 and SharePoint. See the matching log lines (content) on the problem."
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
