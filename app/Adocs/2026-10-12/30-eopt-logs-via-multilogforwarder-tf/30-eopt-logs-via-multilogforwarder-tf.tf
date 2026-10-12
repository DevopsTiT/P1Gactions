terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# eopt logs are NOT in Dynatrace yet (checked 2026-10-12).
# Other OpenPaaS apps arrive through the multilogforwarder:
#   log.source               = multilogforwarder-log-handler-dynatrace
#   dt.openpipeline.source   = /api/v2/logs/ingest
#   k8s.namespace.name       = <app>-prod-axa-li-jp  (capportalsystemapi-prod-axa-li-jp, taxdeduction-prod-axa-li-jp)
# Once eopt is added to the forwarder, its namespace should be eopt-prod-axa-li-jp
# (same as the Splunk index). This detector stays silent until then.
# Keep the Splunk alert running until check query 1 returns eopt lines.
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_backend" {
  title       = "eopt - OpenPaaS Pod Error (Backend)"
  description = "An eopt backend pod (eoptsystemapi or eoptprocessapi) on OpenPaaS logged a line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
          | filter startsWith(k8s.pod.name, "eoptsystemapi-") or startsWith(k8s.pod.name, "eoptprocessapi-")
          | parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
          | filter level == "ERROR"
          | filter endsWith(log_ts, "Z") and contains(log_ts, "T")
          | fieldsAdd service = if(startsWith(k8s.pod.name, "eoptsystemapi-"), "eoptsystemapi", else:"eoptprocessapi")
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
        value = "eopt backend service {service} logged level ERROR in the last hour. See k8s.pod.name and the matching log lines (content) on the problem."
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
