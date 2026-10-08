# Splunk: EIP - ND Mode Alerting in case NULL
#   Description: activate if there are no entries in the log file for EIP ND Mode over a 10-minute interval.
#                If the EIP database returns NULL, the count for the last 10 minutes will be 0.
#   index=eip10 sourcetype=eip_nd_mode (ACTIVEMQMODE!=A OR ACTIVEMQMODE!=B OR ... OR ACTIVEMQMODE!=D)
#   | timechart span=10m count as event_count | stats count as event_count
#   cron */1, Last 1 minute, Number of Results > 1, Once, no throttle, email (priority High)
#
# The Splunk config does not match its description:
#   - the OR of "!=" terms is true for every event that has ACTIVEMQMODE, so it only means "ACTIVEMQMODE has a value"
#   - stats count always returns exactly 1 row, so "Number of Results > 1" can never fire
#   - the time range is 1 minute, not 10
# Dynatrace follows the description: fire when no ND Mode entry with a mode value arrived in 10 minutes.
#
# CONFIRM before apply (check.dql):
#   1. log.source / host for eip_nd_mode logs (query 1)
#   2. ACTIVEMQMODE is an attribute (query 2); if not, use the content-based line in the query comment

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "eip_nd_mode_null" {
  title       = "EIP - ND Mode Alerting in case NULL"
  description = "No EIP ND Mode log entry with an ACTIVEMQMODE value in the last 10 minutes (EIP database returned NULL or logging stopped)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-10m
          | filter matchesValue(log.source, "*eip_nd_mode*")
          | summarize event_count = countIf(isNotNull(ACTIVEMQMODE) and ACTIVEMQMODE != "" and ACTIVEMQMODE != "NULL")
          | filter event_count == 0
          | fieldsAdd check = "eip_nd_mode_null"
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
        value = "EIP - ND Mode Alerting in case NULL"
      }
      property {
        key   = "event.description"
        value = "No EIP ND Mode entries (ACTIVEMQMODE) in the last 10 minutes. The EIP database may be returning NULL, or the ND Mode log stopped."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "EIP"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
