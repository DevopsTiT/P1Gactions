# ALERT: Prod_Life_Compass_BigData連動Glue_Skip発生
# Option A: count-based custom alert (same idea as the Splunk/CloudWatch schedule)

resource "dynatrace_davis_anomaly_detectors" "compass_bigdata_glue_skip" {
  title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  description = "Glue job compass-sales-performance logged 'skipping table' in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws-glue/jobs/custom/compass-sales-performance"
          | filter contains(content, "skipping table")
          | makeTimeseries count = count(default: 0), interval:1m
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
        value = "Prod_Life_Compass_BigData連動Glue_Skip発生"
      }
      property {
        key   = "event.description"
        value = "Glue job compass-sales-performance logged 'skipping table'. Log group /aws-glue/jobs/custom/compass-sales-performance."
      }
      property {
        key   = "alert.priority"
        value = "normal"
      }
      property {
        key   = "alert.notify"
        value = "yuta.inoue@axa.co.jp,shihao.he@axa.co.jp"
      }
    }
  }

  execution_settings {}
}

# Option B: one event per matching log line (classic log events, simpler, API token works)
resource "dynatrace_log_events" "compass_bigdata_glue_skip_line" {
  enabled = false
  summary = "Prod_Life_Compass_BigData連動Glue_Skip発生"
  query   = "matchesValue(aws.log_group, \"/aws-glue/jobs/custom/compass-sales-performance\") and matchesPhrase(content, \"skipping table\")"

  event_template {
    title       = "Prod_Life_Compass_BigData連動Glue_Skip発生"
    description = "{content}"
    event_type  = "CUSTOM_ALERT"
  }
}
