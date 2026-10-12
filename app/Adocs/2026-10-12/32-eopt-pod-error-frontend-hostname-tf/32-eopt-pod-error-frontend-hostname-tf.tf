terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk:
#   index="eopt-prod-axa-li-jp"
#   | spath
#   | eval level=upper(level)
#   | search level="ERROR"
# Run every hour at minute 0, more than 0 results, email Normal.
# spath reads JSON lines. Frontend pods (eoptfrontend-688699b58f-*) write JSON with a "level" key.
# Assumes eopt logs are in Dynatrace with host.name = pod name, same as the Splunk host field.
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_frontend" {
  title       = "eopt - OpenPaaS Pod Error (Frontend)"
  description = "An eopt frontend pod (eoptfrontend) on OpenPaaS logged a JSON line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter startsWith(host.name, "eoptfrontend-")
          | parse content, "JSON:j"
          | fieldsAdd level = upper(toString(j[level]))
          | filter level == "ERROR"
          | fieldsAdd service = "eoptfrontend"
          | fieldsRemove j
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "service"
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
        value = "eopt - OpenPaaS Pod Error (Frontend)"
      }
      property {
        key   = "event.description"
        value = "eopt frontend logged level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "eopt"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
