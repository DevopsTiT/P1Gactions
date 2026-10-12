# ALERT: Prod_Life_HPM_SurveyMonkeyLambdaError_Normal
# Source: Migration/CW/configuration 2/hpm-survey-monkey.tf (resource "dynatrace_log_alert" "hpm_survey_monkey_lambda_error")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#
# Original settings:
#   Cron 0 * * * * (hourly), last 60 minutes, expires 7, results > 0, once
#   Throttle 60 minutes
#   Action Dynatrace problem, severity MEDIUM → alert.severity = "medium"
#   No PagerDuty action → pagerduty.enabled = "0"
#   Action email (3 recipients, not copied) → workflow
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group value for /aws/lambda/hpm-survey-monkey (query 1)
#   2. "ERROR" case-insensitive also matches "error" inside normal text (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "hpm_survey_monkey_lambda_error" {
  title       = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
  description = "To check Lambda error: failure error of transferring files from SurveyMonkey to S3."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter contains(aws.log_group, "/aws/lambda/hpm-survey-monkey")
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
        value = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda hpm-survey-monkey logged an error while transferring files from SurveyMonkey to S3. See the matching log lines (content) on the problem."
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
