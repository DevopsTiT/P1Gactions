terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index=ods sourcetype=oud_service failed
# index=ods has one host (WPALJA2162) and four sources:
#   /opt/oracle/oud/asinst_1/OUD/logs/access   98.658%
#   /opt/oracle/oud/asinst_1/OUD/logs/errors    1.33%
#   /opt/oracle/oud/asinst_2/OUD/logs/errors    0.012%
#   /opt/oracle/oud/asinst_2/OUD/logs/access    0%
# The pattern keeps both errors logs (asinst_1 and asinst_2) and skips the access logs,
# where "failed" shows up on normal failed user logins.
resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "OUD restart failed"
  description = "An OUD errors log on host WPALJA2162 logged a failed line in the last 24 hours. The Oracle Unified Directory (OUD) restart may not have completed."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(host.name, "WPALJA2162", caseSensitive:false)
          | filter startsWith(log.source, "/opt/oracle/oud/")
          | filter endsWith(log.source, "/OUD/logs/errors")
          | filter contains(content, "failed", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "log.source"
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
        value = "OUD restart failed"
      }
      property {
        key   = "event.description"
        value = "An OUD errors log on host WPALJA2162 logged a failed line. The OUD restart may not have completed, so directory lookups can fail. See log.source and the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "oud"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
