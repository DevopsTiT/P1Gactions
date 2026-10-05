# Splunk alert → Dynatrace detector (1 Splunk alert → 1 detector, no workflow)
#
#   ALJ Broker Policy Maintenance: Cannot read properties of undefined
#     index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined*
#     | timechart span=1m count | where count > 50
#     Last 5 minutes, cron */1, results > 0, trigger "For each result", no throttle
#     Email: Splunk Alert: $name$ (Normal) to 2 recipients
#
# CONFIRM before apply (check.dql query 1):
#   The Splunk index name looks like an OpenShift (OCP) namespace → guessed k8s.namespace.name.
#   If the logs arrive with another attribute, change the first filter line only.

resource "dynatrace_davis_anomaly_detectors" "broker_policy_undefined_error" {
  title       = "Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal"
  description = "More than 50 'Cannot read properties of undefined' errors in one minute in brokerpolicymaintenance (prod). Check the OCP pod status."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter k8s.namespace.name == "brokerpolicymaintenance-prod-axa-li-jp"
          | filter contains(content, "Cannot read properties of undefined", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "50"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
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
        value = "Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 50 'Cannot read properties of undefined' errors in one minute in brokerpolicymaintenance (prod). Check the OCP pod status."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Broker Policy Maintenance"
      }
    }
  }

  execution_settings {}
}
