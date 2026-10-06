# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   ALJ OpenPaaS Egress Proxy Public IP Usage Alert
#     index=apigw_syslog sourcetype=apigw_syslog_prod /maam/* *52.76.125.86* OR *54.179.120.88*
#     | stats count | where count <= 0
#     Last 15 minutes, cron */15, expires 24 hours, results > 0, Once, For each result, no throttle
#     Action: Send email only (priority High). No PagerDuty. Recipients NOT copied.
#
# Meaning: alert when, in the last 15 minutes, no /maam/ API gateway line used either of the
# two egress proxy public IPs (only the third IP is in use on ESG).
#
# Splunk data: host EEAA2015.ppprivmgmt.intraxa, source /SYSLOG/APIGW/prod/local4.log
#
# summarize without "by" always returns one row, so count = 0 is still returned and the filter fires.
# fieldsAdd check = constant gives a stable alertIdentityFields value: one open problem, not one per minute.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "openpaas_egress_proxy_ip_usage" {
  title       = "Prod_OpenPaaS_EgressProxyPublicIPUnused_High"
  description = "No /maam/ API gateway traffic used egress proxy public IPs 52.76.125.86 or 54.179.120.88 in the last 15 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter contains(log.source, "/SYSLOG/APIGW/prod/")
          | filter contains(content, "/maam/")
          | filter contains(content, "52.76.125.86") or contains(content, "54.179.120.88")
          | summarize count = count()
          | filter count == 0
          | fieldsAdd check = "egress_proxy_public_ip"
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
        value = "ALJ OpenPaaS Egress Proxy Public IP Usage Alert"
      }
      property {
        key   = "event.description"
        value = "Only one public IP is found on ESG. The other two egress proxy public IPs (52.76.125.86 and 54.179.120.88) were not found in the API gateway /maam/ logs for 15 minutes."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "OpenPaaS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
