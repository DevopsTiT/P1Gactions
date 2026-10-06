# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High
#     index="myaxabackend-prod-axa-li-jp" api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"
#     | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
#     Last 5 minutes, cron */5, expires 24 hours, results > 20, Once, For each result, throttle 60 seconds
#     Actions: Add to Triggered Alerts (High), PagerDuty, Send email. PagerDuty key and recipients NOT copied.
#
# Same search as "ESG - Emma BE timeout to ESG Production" (2026-10-07 seq 1).
# Same resource name on purpose: apply ONE of the two files, not both.
#
# Real data:
#   Source 1: host myaxabackend-*, source s3://axa-li-jp-logforwarders-prod/..., 5 events on 10/6
#     ERROR ... BusinessCalendarServiceException: Business Calendar API unknown error: I/O error on GET request for
#     "https://api-jp-cert.corp.intraxa/biz-calendar/v1/next-biz-day": Read timed out; nested exception is java.net.SocketTimeoutException
#   Source 2: host EEAA2015.ppprivmgmt.intraxa, /SYSLOG/APIGW/prod/local4.log (biz-calendar traffic to api-jp-cert.corp.intraxa)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  esg_timeout_threshold = 20
}

resource "dynatrace_davis_anomaly_detectors" "esg_emma_be_timeout" {
  title       = "Prod_Life_Emma_EmmaBETmeoutToESGProduction_High"
  description = "Calls from Emma BE (OpenPaaS) to ESG (CoreIT) are timing out: more than ${local.esg_timeout_threshold} timeouts in 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter (startsWith(host.name, "myaxabackend-")
                    and contains(content, "api-jp-cert.corp.intraxa")
                    and contains(content, "java.net.SocketTimeoutException"))
                or (contains(log.source, "/SYSLOG/APIGW/prod/")
                    and contains(content, "Problem routing to")
                    and contains(content, "timed out")
                    and contains(content, "myaxa-api.alj.intraxa"))
          | summarize count = count()
          | filter count > ${local.esg_timeout_threshold}
          | fieldsAdd check = "esg_emma_be_timeout"
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
        value = "Prod_Life_Emma_EmmaBETmeoutToESGProduction_High"
      }
      property {
        key   = "event.description"
        value = "This alert is monitoring the ESG calls from Emma BE (OpenPaaS) to ESG (CoreIT) for timeouts. More than 20 timeouts in 5 minutes across the myaxa backend logs and the API gateway logs."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Emma"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
