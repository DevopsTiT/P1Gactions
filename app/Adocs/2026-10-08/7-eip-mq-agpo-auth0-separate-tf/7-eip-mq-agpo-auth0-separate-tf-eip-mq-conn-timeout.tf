# Splunk: ALERT-EIP-MQ-CONN-TIMEOUT
#   index=mq host="wpalja21b*.prprivmgmt.intraxa" *Connection timed out*
#   cron */1, Last 1 minute, results > 0, Once, no throttle, email infra list, Normal
#   Log file: /var/mqm/qmgrs/MQSRVPROD/errors/AMQERR01.LOG (sourcetype mq-batch)

resource "dynatrace_davis_anomaly_detectors" "eip_mq_conn_timeout" {
  title       = "ALERT-EIP-MQ-CONN-TIMEOUT"
  description = "Timeout between EIP and MQ (Connection timed out in the MQ error log on wpalja21b*). Check MQ status and EIP logs."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        # 2 minutes instead of Splunk's 1 so a line that arrives a little late is not missed
        value = <<-EOT
          fetch logs, from:now()-2m
          | filter matchesValue(host.name, "wpalja21b*")
          | filter contains(content, "Connection timed out", caseSensitive:false)
          | fields timestamp, host.name, log.source, content
          | fieldsAdd check = "eip_mq_conn_timeout"
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
        value = "ALERT-EIP-MQ-CONN-TIMEOUT"
      }
      property {
        key   = "event.description"
        value = "Timeout between EIP and MQ (Connection timed out in the MQ error log on wpalja21b*). Check MQ status and EIP logs."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "EIP"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
