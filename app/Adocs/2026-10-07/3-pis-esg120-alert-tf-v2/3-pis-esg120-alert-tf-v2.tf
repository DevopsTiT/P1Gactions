# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   PIS Connection issue (Batch->OpenPaaS) Alert
#     index=claims host="CEAA2088.prprivmgmt.intraxa" sourcetype=pis_defaultlog
#     | regex _raw = "\"errorCode\"\:\s\"ESG120\""
#     Last 5 minutes, cron */5, expires 24 hours, results > 0, Once, For each result, no throttle
#     Action: Send email (priority Normal) to the claims team list. Recipients NOT copied.
#
# Real events (5 on 10/6), source /IFDATA/DATA/PC/LOG/PISP2/pisp2.log:
#   Date: Tue, 06 Oct 2026 05:33:58 GMT
#   Server: server
#   {
#     "errorCode": "ESG120",
#     "errorMessage": "Routing failed",
#
# Each event is a multi-line HTTP response with a pretty-printed JSON body.
# The match works whether Dynatrace stores it as one record or one record per line,
# because "errorCode": "ESG120" sits on a single line.
# Filter by log path only: the host name is hard to read in the screenshots (CEAA2088 or CEAA20B8).

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "pis_connection_esg120" {
  title       = "Prod_PIS_BatchToOpenPaaS_ESG120_Normal"
  description = "PIS batch (pisp2) received errorCode ESG120 (Routing failed) from ESG: the batch could not reach OpenPaaS."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/")
          | filter contains(content, "\"errorCode\": \"ESG120\"")
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
        value = "PIS Connection issue (Batch->OpenPaaS) Alert"
      }
      property {
        key   = "event.description"
        value = "The PIS batch logged errorCode ESG120 with errorMessage Routing failed in /IFDATA/DATA/PC/LOG/PISP2/pisp2.log. ESG could not route the batch call to OpenPaaS."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "PIS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
