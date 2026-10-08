# Splunk: Datalake_Batch Result
#   index="batch_monitoring_logs" | table _time _raw
#   Scheduled, cron 0 8 * * *, Today, Number of Results > 0, Send email (one person, Normal)
#   Index fed from /app/splunk/var/log/splunk/datalake_transfer.log on ceaa20bd
# Same resource name as 2026-10-07 seq 11 and seq 12: apply only one version.

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
  description = "Daily Datalake batch result from datalake_transfer.log: LINE log compression, transfer to UDM, and original data deletion."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "datalake_transfer.log")
          | fields timestamp, host.name, content
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
        value = "The nightly Datalake batch wrote its result lines to datalake_transfer.log (Process Start, compression, transfer to UDM, deletion). Check the lines for Failed steps."
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
