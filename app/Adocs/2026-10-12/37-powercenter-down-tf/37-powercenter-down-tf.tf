terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="powercenter" ISP_MASTER_ELECT_LOCK
# Last 1 minute, cron every minute, more than 3 results, email Normal.
# After check query 1 you can add
#   | filter contains(host.name, "<powercenter host>")
resource "dynatrace_davis_anomaly_detectors" "powercenter_down" {
  title       = "Powercenter down"
  description = "This alert will be created when powercenter is down. Fires when more than 3 ISP_MASTER_ELECT_LOCK lines are logged in 1 minute."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1m
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive:false)
          | summarize lock_events = count(),
                      hosts = collectDistinct(host.name),
                      sample = takeFirst(content)
          | filter lock_events > 3
          | fieldsAdd scope = "powercenter-down"
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
        value = "Powercenter down"
      }
      property {
        key   = "event.description"
        value = "More than 3 ISP_MASTER_ELECT_LOCK lines in 1 minute. PowerCenter may be down. See lock_events, hosts and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
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
