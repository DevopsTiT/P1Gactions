terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk:
#   index=claims host="CEAA20B8.prprivmgmt.intraxa" sourcetype=pis_defaultlog
#   | regex _raw = "\"errorCode\":\s\"ESG120\""
# Event: "errorCode": "ESG120", "errorMessage": "Routing failed"
# host:   CEAA20B8.prprivmgmt.intraxa
# source: /IFDATA/DATA/PC/LOG/PISP2/pisp2.log
resource "dynatrace_davis_anomaly_detectors" "pis_connection_issue_batch_openpaas" {
  title       = "PIS Connection issue (Batch->OpenPaaS) Alert"
  description = "The PIS batch on host CEAA20B8 logged errorCode ESG120 (Routing failed) in pisp2.log in the last 5 minutes. The batch could not reach OpenPaaS."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(host.name, "CEAA20B8", caseSensitive:false)
          | filter contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/pisp2.log", caseSensitive:false)
          | filter contains(content, "errorCode") and contains(content, "ESG120")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "log.source"
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
        value = "PIS Connection issue (Batch->OpenPaaS)"
      }
      property {
        key   = "event.description"
        value = "PIS batch on CEAA20B8 logged errorCode ESG120 (Routing failed). Requests from the batch to OpenPaaS are not getting through. See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "pis"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
