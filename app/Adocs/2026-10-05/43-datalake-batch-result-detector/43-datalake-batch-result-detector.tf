# Replaces Splunk alert "Datalake_Batch Result" as a Dynatrace alert (detector, no workflow)
#   index="batch_monitoring_logs" | table _time _raw
#   Time range: Today   Cron: 0 8 * * *   Fires when results > 0   Email masayuki.yasuda, Normal
#
# Difference from Splunk: a detector evaluates every minute, so it cannot wait until 08:00 and
# send one daily list. Instead it opens ONE problem when batch_monitoring lines appear and closes
# it after 60 quiet minutes, so one batch run = one problem. The problem notification goes through
# the standard flow (email / SILVA); it does not list the log lines (use check.dql query 2 for that).
#
# CONFIRM before apply:
#   1. Splunk index="batch_monitoring_logs" → real Dynatrace field (check.dql query 1)
#   2. If these logs also contain normal "success" lines, add a filter for failures only,
#      otherwise this alerts on every batch run.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title       = "Prod_Datalake_BatchResult_Normal"
  description = "Datalake batch monitoring wrote lines to batch_monitoring_logs. Check the batch result."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*batch_monitoring*")
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
        value = "Prod_Datalake_BatchResult_Normal"
      }
      property {
        key   = "event.description"
        value = "Datalake batch monitoring wrote lines to batch_monitoring_logs. Check the batch result."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "Datalake"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
