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
# Assumes eopt logs are in Dynatrace with host.name = pod name, same as the Splunk host field.
# Host filter matches the whole Splunk index (same as the Backend alert):
#   eoptsystemapi-*   eoptprocessapi-*   eoptfrontend-*
# Only JSON lines with a "level" key can match, like Splunk spath.
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_frontend" {
  title       = "eopt - OpenPaaS Pod Error (Frontend)"
  description = "An eopt pod on OpenPaaS logged a JSON line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter startsWith(host.name, "eoptsystemapi-")
              or startsWith(host.name, "eoptprocessapi-")
              or startsWith(host.name, "eoptfrontend-")
          | parse content, "JSON:j"
          | fieldsAdd level = upper(toString(j[level]))
          | filter level == "ERROR"
          | fieldsAdd service = if(startsWith(host.name, "eoptsystemapi-"), "eoptsystemapi",
                                else: if(startsWith(host.name, "eoptprocessapi-"), "eoptprocessapi",
                                else: "eoptfrontend"))
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
        value = "eopt - OpenPaaS Pod Error (Frontend): {service}"
      }
      property {
        key   = "event.description"
        value = "eopt service {service} logged a JSON line with level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
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
