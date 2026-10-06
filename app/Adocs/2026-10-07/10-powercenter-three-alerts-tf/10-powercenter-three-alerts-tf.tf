# Three Splunk alerts with the SAME search → three Dynatrace Records detectors in one file (no workflow, no makeTimeseries)
#
#   Search (all three): index="powercenter" ISP_MASTER_ELECT_LOCK
#
#   Splunk alert                              Time range   Cron        Trigger   Email priority
#   0031_MWSP-PowerCenter-Service-Down-Alert  Last 1 min   */1 * * * *  > 2       Normal
#   PowerCenter-ProcessStop                   Last 15 min  * * * * *    > 0       High
#   Powercenter down                          Last 1 min   */1 * * * *  > 3       Normal
#   All: expires 24 hours, Once, For each result, no throttle, Send email only. Recipients NOT copied.
#
# ISP_MASTER_ELECT_LOCK: Informatica domain message about the master-gateway election lock.
# It appears when the domain loses its master node and tries to elect a new one (service down or failover).
#
# Overlap: ProcessStop (> 0 in 15 minutes) fires whenever either of the others fires.
# Keep only ProcessStop to avoid 3 emails for one outage: set enabled = false on the other two.
#
# summarize without "by" always returns one row; filter count > threshold keeps it only when the limit is crossed.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  powercenter_alerts = {
    service_down_0031 = {
      title       = "0031_MWSP-PowerCenter-Service-Down-Alert"
      description = "This alert will trigger after detecting the service down from Powercenter server."
      window      = "1m"
      threshold   = 2
      severity    = "medium"
      enabled     = true
    }
    process_stop = {
      title       = "PowerCenter-ProcessStop"
      description = "PowerCenter logged ISP_MASTER_ELECT_LOCK: the Informatica domain is re-electing its master node, so a PowerCenter process has stopped."
      window      = "15m"
      threshold   = 0
      severity    = "high"
      enabled     = true
    }
    powercenter_down = {
      title       = "Powercenter down"
      description = "This alert will be created when powercenter is down."
      window      = "1m"
      threshold   = 3
      severity    = "medium"
      enabled     = true
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "powercenter" {
  for_each = local.powercenter_alerts

  title       = each.value.title
  description = each.value.description
  enabled     = each.value.enabled
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-${each.value.window}
          | filter contains(content, "ISP_MASTER_ELECT_LOCK")
          | summarize count = count()
          | filter count > ${each.value.threshold}
          | fieldsAdd check = "${each.key}"
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
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
      property {
        key   = "app.name"
        value = "PowerCenter"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
