# Splunk: AGPO-Auth0-Password-SyncError
#   sourcetype="agportalapi-prod-axa-li-jp" host="agpo-cloud-authorization-process-api-*"
#     "IamCChangePasswordBadRequestResponse" OR "IamCChangePasswordNotFoundResponse"
#   cron */5, Last 5 minutes, results > 1, Once, throttle 5 seconds, PagerDuty action
#   PagerDuty integration key from Splunk is NOT copied; routing uses pagerduty.enabled.

resource "dynatrace_davis_anomaly_detectors" "agpo_auth0_password_sync_error" {
  title       = "AGPO-Auth0-Password-SyncError"
  description = "More than 1 Auth0 password change error (BadRequest or NotFound) from agpo-cloud-authorization-process-api in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter startsWith(host.name, "agpo-cloud-authorization-process-api-") or startsWith(k8s.pod.name, "agpo-cloud-authorization-process-api-")
          | filter contains(content, "IamCChangePasswordBadRequestResponse", caseSensitive:false)
                or contains(content, "IamCChangePasswordNotFoundResponse", caseSensitive:false)
          | summarize count = count()
          | filter count > 1
          | fieldsAdd check = "agpo_auth0_password_sync_error"
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
        value = "AGPO-Auth0-Password-SyncError"
      }
      property {
        key   = "event.description"
        value = "More than 1 Auth0 password change error (BadRequest or NotFound) from agpo-cloud-authorization-process-api in the last 5 minutes."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "AGPO"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
