# Splunk: Control-M job health check
#   Description: Control-Mのデータ取得ジョブのヘルスチェックする。
#   index=main host="CEAA204C.prprivmgmt.intraxa" RETURN_CD:2
#   cron */5, Last 10 minutes, results > 0, Once, no throttle, email ops list, priority High
#
# WARNING: index=main search (screenshot 2) shows only hosts ljpljob01 and wpalja2199.
#   CEAA204C sends nothing to index=main right now, so the Splunk alert cannot fire.
#   Run check.dql query 1 before apply: if CEAA204C has no logs in Dynatrace either, this detector is silent too.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "controlm_job_health_check" {
  title       = "Control-M job health check"
  description = "Control-Mのデータ取得ジョブのヘルスチェック: RETURN_CD:2 logged on CEAA204C in the last 10 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-10m
          | filter matchesValue(host.name, "CEAA204C*")
          | filter contains(content, "RETURN_CD:2")
          | fields timestamp, host.name, log.source, content
          | fieldsAdd check = "controlm_job_health_check"
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
        value = "Control-M job health check"
      }
      property {
        key   = "event.description"
        value = "Control-Mのデータ取得ジョブが RETURN_CD:2 を返しました（CEAA204C, 直近10分）。ジョブの状態を確認してください。"
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Control-M"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
