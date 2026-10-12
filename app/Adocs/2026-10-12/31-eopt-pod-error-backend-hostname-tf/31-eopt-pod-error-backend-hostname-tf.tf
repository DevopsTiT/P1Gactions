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
#   | rex "^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)\s+(?<level>[A-Z]+)"
#   | eval level=upper(level)
#   | search level="ERROR"
# Run every hour at minute 0, more than 0 results, email Normal.
# Assumes eopt logs are in Dynatrace with host.name = pod name, same as the Splunk host field.
# The index has 12 hosts in three services:
#   eoptsystemapi-564c45bd9f-*   eoptprocessapi-7d49b9558c-*   eoptfrontend-688699b58f-*
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_backend" {
  title       = "eopt - OpenPaaS Pod Error (Backend)"
  description = "An eopt pod on OpenPaaS (eoptsystemapi, eoptprocessapi or eoptfrontend) logged a line with level ERROR in the last hour."
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
          | parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
          | filter level == "ERROR"
          | filter endsWith(log_ts, "Z") and contains(log_ts, "T")
          | fieldsAdd service = if(startsWith(host.name, "eoptsystemapi-"), "eoptsystemapi",
                                else: if(startsWith(host.name, "eoptprocessapi-"), "eoptprocessapi",
                                else: "eoptfrontend"))
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
        value = "eopt - OpenPaaS Pod Error (Backend): {service}"
      }
      property {
        key   = "event.description"
        value = "eopt service {service} logged level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
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
