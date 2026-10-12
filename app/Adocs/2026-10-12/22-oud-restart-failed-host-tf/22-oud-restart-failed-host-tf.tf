terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index=ods sourcetype=oud_service failed
# Splunk shows index=ods comes from one host only: WPALJA2162.prprivmgmt.intraxa (100% of events).
# Dynatrace has no index or sourcetype, so the query is scoped to that host instead.
resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "OUD restart failed"
  description = "The Oracle Unified Directory (OUD) service on host WPALJA2162 logged a failed line in the last 24 hours. The OUD restart may not have completed."
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
          | filter contains(content, "failed", caseSensitive:false)
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
        value = "OUD restart failed"
      }
      property {
        key   = "event.description"
        value = "The OUD service on host WPALJA2162 logged a failed line. The OUD restart may not have completed, so directory lookups can fail. See the matching log lines (content) on the problem."
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
