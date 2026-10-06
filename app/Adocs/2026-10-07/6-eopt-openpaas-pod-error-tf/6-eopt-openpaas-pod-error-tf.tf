# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   eopt - OpenPaaS Pod Error (Backend)
#     index="eopt-prod-axa-li-jp"
#     | rex "^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)\s+(?<level>[A-Z]+)"
#     | eval level=upper(level)
#     | search level="ERROR"
#     Run every hour at 0 minutes past the hour, expires 24 hours, results > 0, Once, For each result, no throttle
#     Action: Send email (priority Normal). Recipients NOT copied.
#
# Real events (11 on 10/6 at 09:30 JST), host eoptsystemapi-564c45bd9f-nj8q4, source s3://axa-li-jp-logforwarders-prod/...
#   2026-10-06T00:30:06.693Z ERROR 1 --- [ scheduling-1] ...PropertyDetailImportServiceImpl : 18 error records were found
#   2026-10-06T00:30:06.693Z ERROR 1 --- [ scheduling-1] ...PropertyDetailImportServiceImpl : Since the value does not exist, we set it to null : GL_ACCOUNT:...
#
# The rex reads the level right after the ISO timestamp. "Z ERROR " is that same position in the line.
# caseSensitive:false matches eval upper(level).
# alertIdentityFields = constant "check": one open problem for all ERROR lines, instead of one email per line.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error" {
  title       = "Prod_eopt_OpenPaaSPodError_Backend_Normal"
  description = "An eopt backend pod on OpenPaaS logged an ERROR-level line."
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
          | filter contains(content, "Z ERROR ", caseSensitive:false)
          | fieldsAdd check = "eopt_backend_error"
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
        value = "eopt - OpenPaaS Pod Error (Backend)"
      }
      property {
        key   = "event.description"
        value = "An eopt backend pod (eoptsystemapi) on OpenPaaS logged an ERROR-level line. Check the pod logs for the failing job or request."
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
