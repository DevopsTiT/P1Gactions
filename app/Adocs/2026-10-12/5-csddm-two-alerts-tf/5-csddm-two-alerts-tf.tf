# Source: Migration/CW/configuration 2/cs-digital-document-management.tf
#   Two "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   Both rewritten as Records detectors (Davis anomaly detectors).
#
# ALERT 1: [CSDDM] Send alert email when Claims API fails
#   Cron 0 10 * * * (daily 10:00), last 24 hours, expires 24, results > 0, once, no throttle
#   Email only, priority Normal → medium (4 recipients, not copied). No PagerDuty → "0".
#   NOTE: a detector cannot run "once a day at 10:00". It checks every minute over the last 24 hours,
#   so a problem opens soon after the first error and stays open until 24 hours after the last one.
#
# ALERT 2: CS Digital Document Management Error alerts
#   Cron */5 * * * *, last 5 minutes, expires 24, results > 0, once, throttle 1 hour
#   Email only, priority Normal → medium (1 recipient, not copied). No PagerDuty → "0".
#   sort and limit 100 removed: a detector only needs rows to exist.
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group values (query 1). Alert 1 matches every group containing "cs-digital-document-management",
#      which includes the -prod group used by alert 2.
#   2. contains(content, "error") in alert 2 is case-sensitive, as in the original. "Error" and "ERROR" are not matched.
#   3. "elivery not possible" is kept as written (it matches both "Delivery" and "delivery").

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ==============================================
# ALERT 1: [CSDDM] Send alert email when Claims API fails
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "csddm_claims_api_fails" {
  title       = "[CSDDM] Send alert email when Claims API fails"
  description = "Lambda cs-digital-document-management logged an error in the last 24 hours (delivery-not-possible and errorEmailNotification lines excluded)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "cs-digital-document-management")
          | filter contains(content, "error", caseSensitive:false)
          | filter not contains(content, "elivery not possible", caseSensitive:false)
          | filter not contains(content, "errorEmailNotification", caseSensitive:false)
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
        value = "[CSDDM] Send alert email when Claims API fails"
      }
      property {
        key   = "event.description"
        value = "Claims API (cs-digital-document-management) logged an error. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "CSDDM"
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
# ALERT 2: CS Digital Document Management Error alerts
# ==============================================
resource "dynatrace_davis_anomaly_detectors" "cs_digital_document_management_error" {
  title       = "CS Digital Document Management Error alerts"
  description = "Alerts when an error occurs. Github Repo: cs-digital-document-management"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "/aws/lambda/cs-digital-document-management-prod")
          | filter contains(content, "error")
          | filter not contains(content, "elivery not possible")
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
        value = "CS Digital Document Management Error alerts"
      }
      property {
        key   = "event.description"
        value = "Lambda cs-digital-document-management-prod logged an error. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "CSDDM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
