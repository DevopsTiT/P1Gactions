# ALERT: Prod_Life_Emma_OverallMsgBoxErrors_Normal
# Source: Migration/CW/configuration 2/message-box-api.tf (resource "dynatrace_log_alert" "emma_overall_msgbox_errors")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#
# Original settings:
#   Cron */5 * * * *, last 5 minutes, expires 24
#   Trigger: NUMBER_OF_RESULTS GREATER_THAN 5 (not 0) → summarize + filter matches > 5
#   Once, no throttle
#   Action Dynatrace problem, severity MEDIUM → alert.severity = "medium"
#   No PagerDuty action → pagerduty.enabled = "0"
#   Action email (3 recipients incl. a Teams channel address, not copied) → workflow
#
# Why summarize here: the detector alerts on "any row". To alert only when MORE THAN 5 lines match,
#   the query counts them and returns a row only when the count is above 5.
#   The count is across all matching log groups, like the old alert. scope is a fixed identity value.
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group values containing "message-box-api" (query 1)
#   2. status values on these logs (ERROR, WARN, INFO...) (query 2)
#   3. How often the 5-line threshold would have been crossed (query 3)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "emma_overall_msgbox_errors" {
  title       = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
  description = "Catch unexpected errors related to Emma Life MsgBox (more than 5 error or warn lines in 5 minutes, DeprecationWarning excluded)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "message-box-api")
          | filter contains(status, "error", caseSensitive:false)
              or contains(status, "warn", caseSensitive:false)
          | filter not contains(content, "DeprecationWarning", caseSensitive:false)
          | summarize matches = count(), log_groups = collectDistinct(aws.log_group), sample = takeFirst(content)
          | filter matches > 5
          | fieldsAdd scope = "message-box-api"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 5 error or warn lines from message-box-api in 5 minutes. See matches, log_groups and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Emma Life MsgBox"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
