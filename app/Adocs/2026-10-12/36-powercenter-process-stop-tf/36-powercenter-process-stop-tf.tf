terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="powercenter" ISP_MASTER_ELECT_LOCK
# Last 15 minutes, cron every minute, more than 0 results, email High.
# Any match fires, so no summarize. After check query 1 you can add
#   | filter contains(host.name, "<powercenter host>")
resource "dynatrace_davis_anomaly_detectors" "powercenter_process_stop" {
  title       = "PowerCenter-ProcessStop"
  description = "Fires when any ISP_MASTER_ELECT_LOCK line is logged in the last 15 minutes. This means a PowerCenter domain process stopped and the nodes are electing a new master."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)
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
        value = "PowerCenter process stop"
      }
      property {
        key   = "event.description"
        value = "ISP_MASTER_ELECT_LOCK logged in the last 15 minutes. A PowerCenter domain process stopped or failed over. Check the PowerCenter services on the host in this problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "powercenter"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
