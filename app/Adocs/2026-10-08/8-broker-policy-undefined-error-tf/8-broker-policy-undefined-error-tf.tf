# Splunk: ALJ Broker Policy Maintenance: Cannot read properties of undefined
#   index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined*
#   | timechart span=1m count | where count > 50
#   cron */1, Last 5 minutes, results > 0, Once, no throttle, email (person + infra list), Normal
#   Description: Need to check the OCP POD Status
#   Pods: broker-policy-maintenance-web-<hash>, JSON logs via s3://axa-li-jp-logforwarders-prod
#
# CONFIRM before apply: pod name in host.name or k8s.pod.name (check.dql query 1).

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "broker_policy_undefined_error" {
  title       = "ALJ Broker Policy Maintenance: Cannot read properties of undefined"
  description = "More than 50 'Cannot read properties of undefined' errors in a single minute (last 5 minutes) from broker-policy-maintenance-web. Check the OCP pod status."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter startsWith(host.name, "broker-policy-maintenance-web") or startsWith(k8s.pod.name, "broker-policy-maintenance-web")
          | filter contains(content, "Cannot read properties of undefined", caseSensitive:false)
          | summarize count = count(), by:{ minute = bin(timestamp, 1m) }
          | filter count > 50
          | fieldsAdd check = "broker_policy_undefined_error"
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
        value = "ALJ Broker Policy Maintenance: Cannot read properties of undefined"
      }
      property {
        key   = "event.description"
        value = "More than 50 'Cannot read properties of undefined' errors in one minute from broker-policy-maintenance-web. Check the OCP pod status."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Broker Policy Maintenance"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
