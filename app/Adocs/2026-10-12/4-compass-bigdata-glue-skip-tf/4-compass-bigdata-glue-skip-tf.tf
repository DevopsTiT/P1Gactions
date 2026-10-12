# ALERT: Prod_Life_Compass_BigData連動Glue_Skip発生
# Source: Migration/CW/configuration 2/compass-sales-performance.tf (resource "dynatrace_log_alert" "compass_bigdata_glue_skip")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#
# Original settings:
#   Cron */5 * * * *, last 5 minutes, expires 2400, results > 0, once, no throttle
#   Only action: email, priority Normal → alert.severity = "medium" (recipients not copied)
#   No PagerDuty action → pagerduty.enabled = "0"
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group value for /aws-glue/jobs/custom/compass-sales-performance/error (query 1)
#   2. What a "skipping table" line looks like (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "compass_bigdata_glue_skip" {
  title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  description = "Glue job compass-sales-performance logged 'skipping table' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws-glue/jobs/custom/compass-sales-performance/error")
          | filter contains(content, "skipping table", caseSensitive:false)
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
        value = "Prod_Life_Compass_BigData連動Glue_Skip発生"
      }
      property {
        key   = "event.description"
        value = "Glue job compass-sales-performance skipped a table. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Compass"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
