# Source: Migration/CW/configuration 2/cci-fa-comm-calc.tf (resource "dynatrace_log_alert" "cci_aws_batch_timeout")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#   Seq 2 = seq 1 without the summarize step. Each matching log line is a row;
#   alertIdentityFields = aws.log_group still keeps it to one open problem.
#   Same resource name as seq 1, so apply from ONE folder only.
#
# Original settings kept:
#   Every 5 minutes, last 6 minutes, results > 0, once, no throttle
#   Lambda log group cci-fa-comm-calc, "Task timed out", not [DEBUG]
#   Action PagerDuty → pagerduty.enabled = "1" (the workflow sends it; no integration key here)
#   Action email → handled by the workflow / notification, not by this file (recipients not copied)
#
# CONFIRM before apply:
#   1. The field is really called aws.log_group in your tenant (check.dql query 1)
#   2. Severity high is right for a PagerDuty alert
#   3. The old integration key was in a plain-text file. If that file was ever committed or shared, rotate the key in PagerDuty.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "cci_aws_batch_timeout" {
  title       = "CCI_AWS_Batch Time Out"
  description = "Lambda cci-fa-comm-calc logged 'Task timed out' in the last 6 minutes (DEBUG lines excluded)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-6m
          | filter contains(aws.log_group, "cci-fa-comm-calc")
          | filter contains(content, "Task timed out", caseSensitive:false)
          | filter not contains(content, "[DEBUG]")
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
        value = "CCI AWS Batch Task Timeout Alert"
      }
      property {
        key   = "event.description"
        value = "Lambda cci-fa-comm-calc timed out. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "CCI"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
