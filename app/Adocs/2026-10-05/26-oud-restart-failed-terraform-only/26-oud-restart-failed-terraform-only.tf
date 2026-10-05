# ==========================================
# ALERT: OUD restart failed
# Splunk: index=ods sourcetype=oud_service failed
#         cron 1 4 * * *, last 24 hours, results > 0, High, PagerDuty, email
# ==========================================

resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "Prod_OUD_RestartFailed_High"
  description = "The OUD (Oracle Unified Directory) service restart logged 'failed'. Directory lookups and logins that depend on OUD may fail."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*oud_service*")
          | filter matchesPhrase(content, "failed")
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
        EOT
      }
      analyzer_input_field {
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
        value = "Prod_OUD_RestartFailed_High"
      }
      property {
        key   = "event.description"
        value = "OUD service restart failed on {dims:dt.entity.host}. Check the oud_service log on that host."
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
