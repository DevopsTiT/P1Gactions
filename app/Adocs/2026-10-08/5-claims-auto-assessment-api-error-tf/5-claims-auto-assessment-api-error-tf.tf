# Splunk: Auto-Assessment API Error - !PRODUCTION!
#   index=claimsda* AND host IN ("claims-auto-assessment-api*") AND ("*] ERROR *")
#     AND NOT ("*Error stacktraces are turned on*")
#   | table _time, host, _raw | sort _time asc
#   Scheduled, cron */10 * * * *, Last 10 minutes, Number of Results > 0, Trigger Once, no throttle
#   Send email to the claims incident list, priority High
#
# CONFIRM before apply: where the pod name lands in Dynatrace (host.name or k8s.pod.name), check.dql query 1.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "claims_auto_assessment_api_error" {
  title       = "Prod_Claims_AutoAssessmentAPI_Error_High"
  description = "ERROR lines from claims-auto-assessment-api in the last 10 minutes (excluding the 'Error stacktraces are turned on' startup message)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-10m
          | filter startsWith(host.name, "claims-auto-assessment-api") or startsWith(k8s.pod.name, "claims-auto-assessment-api")
          | filter contains(content, "] ERROR ", caseSensitive:false)
          | filter not contains(content, "Error stacktraces are turned on", caseSensitive:false)
          | fields timestamp, host.name, k8s.pod.name, content
          | sort timestamp asc
          | fieldsAdd check = "claims_auto_assessment_api_error"
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
        value = "Prod_Claims_AutoAssessmentAPI_Error_High"
      }
      property {
        key   = "event.description"
        value = "claims-auto-assessment-api logged ERROR lines in the last 10 minutes. Check the pod logs."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Claims"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
