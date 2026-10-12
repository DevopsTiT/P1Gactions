# Source: Migration/CW/configuration 2/recruitimp-serverless.tf
#   Two "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   Both rewritten as Records detectors (Davis anomaly detectors).
#
# ALERT 1: recrutimp - AWS Serverless Error
#   Cron 0 8 * * * (daily 08:00), last 24 hours, expires 24, results > 0, once, no throttle
#   Email only, Normal → medium (2 recipients, not copied). No PagerDuty → "0".
#   "level:ERROR" or "level:error", both case-insensitive → one check is enough.
#   NOTE: a detector cannot run once a day at 08:00. It checks every minute over 24 hours.
#   For a daily 08:00 digest, use a scheduled workflow instead.
#
# ALERT 2: RI Monitoring Error
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   Email only, Normal → medium (1 distribution list, not copied). No PagerDuty → "0".
#
# Overlap: every Alert 1 line ("level:error") also contains "error", so it also fires Alert 2.
#
# Names keep the original spelling "recrutimp" (the log group is "recruitimp").
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group values containing "recruitimp-serverless" (query 1)
#   2. Alert 2's "ERROR" case-insensitive matches the word "error" anywhere (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ==============================================
# ALERT 1: recrutimp - AWS Serverless Error
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "recrutimp_aws_serverless_error" {
  title       = "recrutimp - AWS Serverless Error"
  description = "Lambda recruitimp-serverless logged level:ERROR in the last 24 hours."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "recruitimp-serverless")
          | filter contains(content, "level:ERROR", caseSensitive:false)
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
        value = "recrutimp - AWS Serverless Error"
      }
      property {
        key   = "event.description"
        value = "Lambda recruitimp-serverless logged level:ERROR. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "recruitimp"
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
# ALERT 2: RI Monitoring Error
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "recrutimp_ri_monitoring_error" {
  title       = "RI Monitoring Error"
  description = "Lambda recruitimp-serverless logged a line containing ERROR in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "recruitimp-serverless")
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
        value = "RI Monitoring Error"
      }
      property {
        key   = "event.description"
        value = "Lambda recruitimp-serverless logged an ERROR. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "recruitimp"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
