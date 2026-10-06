# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   eopt - OpenPaaS Pod Error (Frontend)
#     index="eopt-prod-axa-li-jp"
#     | spath
#     | eval level=upper(level)
#     | search level="ERROR"
#     Run every hour at 0 minutes past the hour, expires 24 hours, results > 0, Once, For each result, no throttle
#     Action: Send email (priority Normal). Recipients NOT copied.
#
# spath = parse the event as JSON. The frontend writes JSON lines with a "level" field ("error", "ERROR", ...).
# upper() makes the level check case-insensitive.
# Backend lines are plain text ("<timestamp>Z ERROR ..."), so JSON parsing gives no level and they are skipped,
# exactly like spath in Splunk. Backend errors are covered by the Backend alert (2026-10-07 seq 7).

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_frontend" {
  title       = "Prod_eopt_OpenPaaSPodError_Frontend_Normal"
  description = "An eopt frontend pod on OpenPaaS logged a JSON line with level ERROR."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter startsWith(host.name, "eopt")
          | parse content, "JSON:j"
          | filter upper(toString(j[level])) == "ERROR"
          | fieldsRemove j
          | fieldsAdd check = "eopt_frontend_error"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
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
        value = "An eopt frontend pod on OpenPaaS logged a JSON line with level ERROR. Check the frontend pod logs."
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
