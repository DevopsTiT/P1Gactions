# Source: Migration/CW/configuration 2/customer-process-api.tf
#   Two "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   Both rewritten as Records detectors (Davis anomaly detectors).
#
# ALERT 1: Customer Process API Success Request Monitoring
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   Email only, priority Normal, subject "||PROD|| Alert: $name$" (4 recipients, not copied)
#   This is a SUCCESS notice (statusCode 201 = contract request created), not an error → alert.severity = "low"
#
# ALERT 2: Customer Process API Alerts
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, no throttle
#   Email only, priority Normal → medium (1 distribution list, not copied)
#
# Both: no PagerDuty action → pagerduty.enabled = "0"
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group values containing "customer-process-api" (query 1)
#   2. How statusCode 201 appears in content (query 2)
#   3. Message code "IBL0250002" was read from a photo. Check the exact code.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ==============================================
# ALERT 1: Customer Process API Success Request Monitoring
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "customer_process_api_success_monitoring" {
  title       = "Customer Process API Success Request Monitoring"
  description = "To immediately understand the actual production contract requested and confirm operations."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "customer-process-api")
          | filter contains(content, "\"statusCode\":201") or contains(content, "statusCode\":201")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "||PROD|| Customer Process API Success Request Monitoring"
      }
      property {
        key   = "event.description"
        value = "Customer Process API returned statusCode 201 (production contract request created). See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "Customer Process API"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ==============================================
# ALERT 2: Customer Process API Alerts
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "customer_process_api_alerts" {
  title       = "Customer Process API Alerts"
  description = "Lambda customer-process-api logged a known error message (timeout, handler failure, ineligible policy, zero import, too many connections and others)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "customer-process-api")
          | filter contains(content, "Task timed out", caseSensitive:false)
              or contains(content, "An error occurred", caseSensitive:false)
              or contains(content, "Failed to handle: lifeJData", caseSensitive:false)
              or contains(content, "Got unexpected investment company code", caseSensitive:false)
              or contains(content, "The policy is ineligible for creating a request", caseSensitive:false)
              or contains(content, "IBL0250002", caseSensitive:false)
              or contains(content, "<StatusCd>EB", caseSensitive:false)
              or contains(content, "imported a total of 0 data", caseSensitive:false)
              or contains(content, "Handler Error: Too many connections", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = "||PROD|| Customer Process API Alerts"
      }
      property {
        key   = "event.description"
        value = "Customer Process API logged a known error message. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Customer Process API"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
