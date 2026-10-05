# Replaces 3 Splunk alerts that all run: index="powercenter" ISP_MASTER_ELECT_LOCK
#   0031_MWSP-PowerCenter-Service-Down-Alert  last 1 min,  every 1 min, results > 2, Normal
#   PowerCenter-ProcessStop                   last 15 min, every 1 min, results > 0, High
#   Powercenter down                          last 1 min,  every 1 min, results > 3, Normal
# ProcessStop (> 0) already fires whenever the other two would, so one detector covers all three.

resource "dynatrace_davis_anomaly_detectors" "powercenter_master_elect_lock" {
  title       = "Prod_MWSP_PowerCenter_ServiceDown_High"
  description = "PowerCenter logged ISP_MASTER_ELECT_LOCK. The PowerCenter service or process may be down."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query"
        # CONFIRM line 2: Splunk index="powercenter" → real Dynatrace field (check.dql query 1)
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*powercenter*")
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive: false)
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
        EOT
      }
      analyzer_input_field {
        # Use "2" instead if check.dql query 2 shows 1-2 lines per minute is normal background
        key   = "threshold"
        value = "0"
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
        value = "15"
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
        value = "Prod_MWSP_PowerCenter_ServiceDown_High"
      }
      property {
        key   = "event.description"
        value = "PowerCenter logged ISP_MASTER_ELECT_LOCK on {dims:dt.entity.host}. The PowerCenter service or process may be down."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "dt.source_entity"
        value = "{dims:dt.entity.host}"
      }
    }
  }

  execution_settings {}
}
