# ALERT: CCI_AWS_Batch Time Out
# Lambda cci-fa-comm-calc logged "Task timed out" (DEBUG lines excluded)

resource "dynatrace_davis_anomaly_detectors" "cci_aws_batch_timeout" {
  title       = "CCI_AWS_Batch Time Out"
  description = "Lambda cci-fa-comm-calc logged 'Task timed out' in the last 5 minutes. CCI AWS Batch Task Timeout Alert."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cci-fa-comm-calc"
          | filter contains(content, "Task timed out")
          | filter not contains(content, "!DEBUG!")
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
        value = "CCI_AWS_Batch Time Out"
      }
      property {
        key   = "event.description"
        value = "CCI AWS Batch Task Timeout Alert. Lambda /aws/lambda/cci-fa-comm-calc logged 'Task timed out'."
      }
    }
  }

  execution_settings {}
}

# Option B: one event per matching line (classic API token is enough)
resource "dynatrace_log_events" "cci_aws_batch_timeout_line" {
  enabled = false
  summary = "CCI_AWS_Batch Time Out"
  query   = "matchesValue(aws.log_group, \"/aws/lambda/cci-fa-comm-calc\") and matchesPhrase(content, \"Task timed out\") and not matchesPhrase(content, \"!DEBUG!\")"

  event_template {
    title       = "CCI_AWS_Batch Time Out"
    description = "{content}"
    event_type  = "CUSTOM_ALERT"
  }
}
