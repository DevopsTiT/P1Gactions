terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# ALERT 1: Sa Support Batch Error
# Same query as Alert 3 today. Change the content filter to the real error text, or delete one of them.
resource "dynatrace_davis_anomaly_detectors" "sa_support_batch_error" {
  title       = "Sa Support Batch Error"
  description = "Lambda sa-support-batches logged Task timed out in the last 6 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-6m
          | filter contains(aws.log_group, "sa-support-batches")
          | filter contains(content, "Task timed out", caseSensitive:false)
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
        value = "Sa Support Batch Error"
      }
      property {
        key   = "event.description"
        value = "Lambda sa-support-batches logged Task timed out. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "sa-support-batches"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ALERT 2: Sa Support Batch File Import Confirmation
# Absence alert: opens a problem when fewer than 2 import lines were logged in the last 24 hours.
# The old alert checked only at 08:30 on weekdays. The JST guard below keeps that window
# (Mon-Fri, 08:30-08:59 JST). Run the check DQL first to confirm the guard returns true at that time.
resource "dynatrace_davis_anomaly_detectors" "sa_support_batch_file_import_confirmation" {
  title       = "Sa Support Batch File Import Confirmation"
  description = "Fewer than 2 file import lines from sa-support-batches in the last 24 hours (checked weekdays 08:30 JST)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(aws.log_group, "sa-support-batches")
          | filter contains(content, "importFileHandler :: runner :")
              or contains(content, "importSagaFundGroup")
              or contains(content, "started")
          | summarize matches = count()
          | filter matches < 2
          | fieldsAdd jst_day = formatTimestamp(now(), format:"EEE", timezone:"Asia/Tokyo"),
                      jst_hhmm = toLong(formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo"))
          | filter in(jst_day, {"Mon", "Tue", "Wed", "Thu", "Fri"})
          | filter jst_hhmm >= 830 and jst_hhmm < 900
          | fieldsAdd scope = "sa-support-batches-import"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "Sa Support Batch File Import Confirmation"
      }
      property {
        key   = "event.description"
        value = "sa-support-batches logged fewer than 2 file import lines in the last 24 hours. The import may not have run. See matches on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "sa-support-batches"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# ALERT 3: Sa Support Batch Task Time Out
resource "dynatrace_davis_anomaly_detectors" "sa_support_batch_task_timeout" {
  title       = "Sa Support Batch Task Time Out"
  description = "Lambda sa-support-batches logged Task timed out in the last 6 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-6m
          | filter contains(aws.log_group, "sa-support-batches")
          | filter contains(content, "Task timed out", caseSensitive:false)
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
        value = "Sa Support Batch Task Time Out"
      }
      property {
        key   = "event.description"
        value = "Lambda sa-support-batches logged Task timed out. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "sa-support-batches"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
