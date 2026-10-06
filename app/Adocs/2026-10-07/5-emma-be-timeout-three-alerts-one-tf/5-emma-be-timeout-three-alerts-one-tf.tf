# Three Splunk alerts with the SAME search → ONE Dynatrace Records detector (Terraform only, no workflow)
#
#   Search (identical in all three):
#     index="myaxabackend-prod-axa-li-jp" api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"
#     | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
#     Last 5 minutes, cron */5, expires 24 hours, results > 20, Once, For each result, throttle 60 seconds
#
#   Splunk alert                                          Actions
#   ESG - Emma BE timeout to ESG Production               Send email (High) + Alert Status Manager (PagerDuty Enable)
#   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High       Triggered Alerts (High) + PagerDuty + Send email
#   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High_PagerDuty   PagerDuty only (integration key in Splunk, NOT copied)
#
# One detector with pagerduty.enabled = "1" covers all three: the standard flow sends SILVA, PagerDuty and email.
# Migrating all three would page on-call three times for the same timeout.
# Same resource name as 2026-10-07 seq 1 and seq 4: apply only this file.

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
  description = "Calls from Emma BE (OpenPaaS) to ESG (CoreIT) are timing out: more than ${local.esg_timeout_threshold} timeouts in 5 minutes. Replaces three Splunk alerts with the same search."
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
