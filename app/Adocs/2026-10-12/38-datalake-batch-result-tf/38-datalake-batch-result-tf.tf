terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="batch_monitoring_logs" | table _time _raw
# Cron 0 8 * * * (daily 08:00), time range Today, more than 0 results, email Normal.
# Hosts: ceaa20BD, CEAA20BE, CEAA2101 (.prprivmgmt.intraxa)
# Source: /app/splunk/var/log/splunk/datalake_transfer.log
# The batch runs about 02:00 JST. The detector runs every minute, so the JST guard
# only lets rows through between 08:00 and 08:04, which is like the 08:00 cron.
# 8 hours back from 08:00 JST covers "Today".
resource "dynatrace_davis_anomaly_detectors" "datalake_batch_result" {
  title       = "Datalake_Batch Result"
  description = "Daily 08:00 JST report of today's datalake transfer batch log from CEAA20BD, CEAA20BE and CEAA2101. One problem per host, carrying the batch lines."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-8h
          | filter contains(host.name, "CEAA20BD", caseSensitive:false)
              or contains(host.name, "CEAA20BE", caseSensitive:false)
              or contains(host.name, "CEAA2101", caseSensitive:false)
          | filter contains(log.source, "datalake_transfer.log", caseSensitive:false)
          | fieldsAdd jst_hhmm = toLong(formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo"))
          | filter jst_hhmm >= 800 and jst_hhmm < 805
          | fields timestamp, host.name, log.source, content
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "host.name"
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
        value = "Datalake batch result"
      }
      property {
        key   = "event.description"
        value = "Today's datalake transfer batch log lines for this host. Check for lines such as Failed to delete or missing Successfully Completed."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "datalake"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
