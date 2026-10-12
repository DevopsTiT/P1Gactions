# Source: Migration/CW/configuration 2/eopt-serverless.tf
#   Two "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   Both rewritten as Records detectors (Davis anomaly detectors).
#
# ALERT 1: E-Tool Error Lambda (Filtered Output)
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   Email only, Normal → medium (1 distribution list, not copied). No PagerDuty → "0".
#   "Filtered fields: timestamp, level, message" → fields timestamp, loglevel, content (+ aws.log_group for identity)
#
# ALERT 2: eopt - AWS Serverless Error (Full Output)
#   Cron 0 10 * * * (daily 10:00), last 24 hours, expires 24, results > 0, once, no throttle
#   Email only, Normal → medium (2 recipients, not copied). No PagerDuty → "0".
#   NOTE: same filter as Alert 1 over 24 hours. A detector cannot run once a day at 10:00;
#   it checks every minute, so one error opens BOTH problems. For a daily 10:00 digest, use a scheduled workflow.
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group values containing "eopt-serverless" (query 1)
#   2. "ERROR" case-insensitive also matches "error" anywhere, e.g. "errorCount": 0 (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ==============================================
# ALERT 1: E-Tool Error Lambda (Filtered Output)
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "etool_error_lambda" {
  title       = "E-Tool Error Lambda"
  description = "Alert with filtered fields: timestamp, level, message"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "eopt-serverless")
          | filter contains(content, "ERROR", caseSensitive:false)
          | fields timestamp, loglevel, content, aws.log_group
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
        value = "E-Tool Error Lambda"
      }
      property {
        key   = "event.description"
        value = "Lambda eopt-serverless logged an ERROR. See timestamp, loglevel and content on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "E-Tool"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ==============================================
# ALERT 2: eopt - AWS Serverless Error (Full Output)
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "eopt_aws_serverless_error" {
  title       = "eopt - AWS Serverless Error"
  description = "Alert with all fields for investigation"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "eopt-serverless")
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
        value = "eopt - AWS Serverless Error"
      }
      property {
        key   = "event.description"
        value = "Lambda eopt-serverless logged an ERROR in the last 24 hours. All log fields are on the problem for investigation."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "E-Tool"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
