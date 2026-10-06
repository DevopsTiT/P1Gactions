# Splunk alert → Dynatrace Records detector (Terraform only, no workflow, no makeTimeseries)
#
#   PIS Connection issue (Batch->OpenPaaS) Alert
#     index=claims host="CEAA20B8.prprivmgmt.intraxa" sourcetype=pis_defaultlog
#     | regex _raw = "\"errorCode\"\:\s\"ESG120\""
#     Last 5 minutes, cron */5, expires 24 hours, results > 0, Once, For each result, no throttle
#     Action seen: Send email (priority Normal) to the claims team list. Recipients NOT copied.
#     If an Alert Status Manager action with PagerDuty Enable is further down, set pagerduty.enabled = "1".
#
# Splunk data: host CEAA20B8.prprivmgmt.intraxa, source /IFDATA/DATA/PC/LOG/PISP2/pisp2.log (Spring Batch app)
#
# Records analyzer: every returned row is a violation, so "> 0" is the default behaviour.
# Splunk regex \s = one whitespace character; the log writes a single space, so contains() is exact enough.
# No from: in the query, so it looks back 2 hours and closes 2 hours after the last ESG120 line.

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
  description = "PIS batch (pisp2) logged errorCode ESG120: the batch could not connect to OpenPaaS."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/") or matchesValue(host.name, "CEAA20B8*")
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
        value = "The PIS batch on CEAA20B8 logged errorCode ESG120 in /IFDATA/DATA/PC/LOG/PISP2/pisp2.log. The batch failed to connect to OpenPaaS."
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
