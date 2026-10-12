terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="powercenter" ISP_MASTER_ELECT_LOCK
# Last 1 minute, cron every minute, more than 2 results, email Normal.
# The index has no Dynatrace equivalent. The message code is specific to Informatica PowerCenter,
# so the content filter alone is enough. After check query 1, you can add
#   | filter contains(host.name, "<powercenter host>")
resource "dynatrace_davis_anomaly_detectors" "mwsp_powercenter_service_down" {
  title       = "0031_MWSP-PowerCenter-Service-Down-Alert"
  description = "This alert will trigger after detecting the service down from Powercenter server. Fires when more than 2 ISP_MASTER_ELECT_LOCK lines are logged in 1 minute."
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
          | filter lock_events > 2
          | fieldsAdd scope = "powercenter-service"
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
        value = "MWSP PowerCenter service down"
      }
      property {
        key   = "event.description"
        value = "More than 2 ISP_MASTER_ELECT_LOCK lines in 1 minute. The PowerCenter domain service may be down or failing over. See lock_events, hosts and sample on the problem."
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
