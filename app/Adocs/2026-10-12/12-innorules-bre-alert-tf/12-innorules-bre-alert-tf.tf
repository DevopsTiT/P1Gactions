# ALERT: BRE alert
# Source: Migration/CW/configuration 2/innorules.tf (resource "dynatrace_log_alert" "bre_alert_innorules")
#   That resource type does not exist in the dynatrace-oss/dynatrace provider, so plan fails.
#   Same logic rewritten as a Records detector (Davis anomaly detector).
#
# Original settings:
#   Cron */5 1-5 * * * → every 5 minutes, ONLY during hours 01:00-05:59
#   Last 5 minutes, expires 24, results > 0, once, no throttle
#   Only action: PagerDuty (integration key NOT copied) → pagerduty.enabled = "1", severity high
#   No email, no Dynatrace problem action in the old file
#
# Hour window:
#   A detector has no schedule, so the 01:00-05:59 window is a filter on the log timestamp.
#   getHour() uses UTC. CONFIRM which timezone the old cron used:
#     UTC cron → 01:00-05:59 UTC = 10:00-14:59 JST (keep as written)
#     JST cron → replace the hour filter with the Asia/Tokyo version shown below
#
# CONFIRM before apply (check.dql):
#   1. aws.log_group values containing "innorules" (query 1)
#   2. "ERROR" case-insensitive also matches "error" inside normal text (query 2)
#   3. The old key looks the same as the CCI timeout alert's key (same PagerDuty service). Rotate it if the file was committed.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "bre_alert_innorules" {
  title       = "BRE alert"
  description = "Alert when logs from innorules-* contain log level error (01:00-05:59 only)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(aws.log_group, "innorules")
          | filter contains(content, "ERROR", caseSensitive:false)
          | filter getHour(timestamp) >= 1 and getHour(timestamp) <= 5
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
        value = "BRE alert: InnoRules ERROR detected"
      }
      property {
        key   = "event.description"
        value = "InnoRules (BRE) logged an ERROR. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "InnoRules"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

# Asia/Tokyo version of the hour filter (use if the old cron ran in JST):
#   | fieldsAdd hour_jst = toLong(formatTimestamp(timestamp, format:"H", timezone:"Asia/Tokyo"))
#   | filter hour_jst >= 1 and hour_jst <= 5
