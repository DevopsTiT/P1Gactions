# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   OUD restart failed
#     index=ods sourcetype=oud_service failed
#     Last 24 hours, cron "1 4 * * *" (04:01 daily, as read from the screenshot), expires 24 hours
#     Number of results > 0, Once, For each result, no throttle
#     Actions: Triggered Alerts (High), PagerDuty, Send email
#
# Splunk index=ods data: one host WPALJA2162.prprivmgmt.intraxa, sources under /opt/oracle/oud/asinst_1/OUD/logs/
# (2 sources, 2 sourcetypes). oud_service is the service log; confirm its log.source with check.dql query 1.
#
# Records analyzer: every row returned is a violation, so "> 0" is the default behaviour.
# Splunk checked once a day; Dynatrace checks every minute, so a failed restart alerts within minutes.
# No from: in the query, so it looks back 2 hours and closes 2 hours after the last "failed" line.
#
# PagerDuty key is NOT copied. Paging goes through the standard SILVA / PagerDuty flow.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "Prod_OUD_RestartFailed_High"
  description = "OUD (Oracle Unified Directory) service log on WPALJA2162 reports a failed restart."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter matchesValue(host.name, "WPALJA2162*") and contains(log.source, "/opt/oracle/oud/")
          | filter contains(content, "failed", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "host.name"
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
        value = "OUD restart failed"
      }
      property {
        key   = "event.description"
        value = "The OUD service log on WPALJA2162.prprivmgmt.intraxa contains a failed message. The directory service may not have restarted. Check the OUD instance under /opt/oracle/oud/asinst_1."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "OUD"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
