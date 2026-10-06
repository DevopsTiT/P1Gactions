# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   ESG - Emma BE timeout to ESG Production
#     index="myaxabackend-prod-axa-li-jp" api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"
#     | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
#     Last 5 minutes, cron */5, expires 24 hours, results > 20, Once, For each result, throttle 60 seconds
#     Action: Send email only (priority High). No PagerDuty. Recipients NOT copied.
#
# Source 1 (Emma BE / myaxa backend): host myaxabackend-*, source s3://axa-li-jp-logforwarders-prod/...
# Source 2 (API gateway): /SYSLOG/APIGW/prod/local4.log
# append = both result sets added together, so one filter with "or" and one count.
#
# alertIdentityFields = constant "check": one open problem while the count stays above 20.

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
  title       = "Prod_ESG_EmmaBETimeout_High"
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
        value = "ESG - Emma BE timeout to ESG Production"
      }
      property {
        key   = "event.description"
        value = "This alert monitors the ESG calls from Emma BE (OpenPaaS) to ESG (CoreIT) for timeouts. More than 20 timeouts in 5 minutes across the myaxa backend logs and the API gateway logs."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "ESG"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
