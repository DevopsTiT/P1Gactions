# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   Datalake_Batch Result
#     index="batch_monitoring_logs" | table _time _raw
#     Time range Today, cron "0 8 * * *" (08:00 daily), expires 24 hours, results > 0, Once, For each result, no throttle
#     Action: Send email (priority Normal) to one person. Recipient NOT copied.
#
# Real data (240 events in 30 days = 8 lines per night at about 02:00 JST):
#   [2026/10/06 02:00:33] ########Process Start########
#   [2026/10/06 02:00:33] File LINEBOT.csv is existing
#   [2026/10/06 02:00:33] ########Data Compression Initiated########
#   [2026/10/06 02:00:33] Compression SP_LINE_LOG_20261005_020033.csv successfully Completed
#   [2026/10/06 02:00:33] ########Data transfering Initiated########
#   [2026/10/06 02:00:33] Data SP_LINE_LOG_20261005_020033.csv sent to UDM successfully
#   [2026/10/06 02:00:33] ########Original Data Deletion Initiated########
#   [2026/10/06 02:00:33] Failed to delete Data LINEBOT.csv          <- every night
#
# Splunk is a daily REPORT: at 08:00 it emails today's batch lines.
# Records detector checks every minute, so the email arrives at about 02:00 when the batch writes its lines,
# not at 08:00. The default lookback is 2 hours, so the problem closes at about 04:00: one email per night.
# Exactly 08:00 needs a scheduled workflow instead (2026-10-05 seq 42).

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title       = "Datalake_Batch Result"
  description = "Daily Datalake batch result: the batch_monitoring log lines written by the nightly LINE log transfer to UDM."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*batch_monitoring*")
          | fields timestamp, content
          | fieldsAdd check = "datalake_batch_result"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
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
        value = "Datalake_Batch Result"
      }
      property {
        key   = "event.description"
        value = "The nightly Datalake batch wrote its result lines (Process Start, compression, transfer to UDM, deletion). Check the lines for Failed steps."
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
