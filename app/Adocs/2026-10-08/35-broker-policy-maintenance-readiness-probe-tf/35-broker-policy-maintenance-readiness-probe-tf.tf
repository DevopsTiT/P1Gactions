# Splunk: 【Brocker Policy Maintenance】ReadinessProbe失敗エラー(HealthCheck)
#   index=brokerpolicymaintenance-prod-axa-li-jp GET "/meta/health" statusCode!=""
#   | head 2
#   | stats earliest(_time) as time, latest(_raw) as log, earliest(statusCode) as earliest, latest(statusCode) as latest
#   | where earliest != latest
#   | eval StatusCode = latest | table check_name StatusCode time log
#   cron */5, Last 5 minutes, Expires 24h, results > 0, Once, no throttle
#   Action: Send email (recipients not copied)
#
# What Splunk really does: takes the newest 2 health lines (from either pod) and mails when the
#   status code CHANGED between them. So it mails on 200 -> 503 and again on 503 -> 200, stays
#   silent while the probe keeps failing, and can flap when one pod is 200 and the other is 503.
#
# Dynatrace (better behaviour, same intent): one problem per pod while that pod's newest health
#   status in the last 5 minutes is not 200. The problem closes when the pod returns 200, which
#   replaces the Splunk "changed back" mail.
#
# CONFIRM before apply (check.dql):
#   1. statusCode really exists on the /meta/health lines (your search screenshot shows no
#      statusCode field on the sampled lines; if it never exists the Splunk alert can never fire)
#   2. Pod name field: k8s.pod.name or host.name (same as seq 34)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "broker_policy_maintenance_readiness_probe" {
  title       = "【Broker Policy Maintenance】ReadinessProbe失敗エラー(HealthCheck)"
  description = "A broker-policy-maintenance-web pod's newest /meta/health response in the last 5 minutes is not 200. One problem per pod."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter matchesValue(k8s.pod.name, "broker-policy-maintenance-web-*") or matchesValue(host.name, "broker-policy-maintenance-web-*")
          | filter contains(content, "/meta/health")
          | parse content, "JSON:j"
          | fieldsAdd statusCode = toString(j[statusCode])
          | filter isNotNull(statusCode) and statusCode != ""
          | fieldsAdd pod = coalesce(k8s.pod.name, host.name)
          | sort timestamp asc
          | summarize latest_status = takeLast(statusCode),
                      bad_checks = countIf(statusCode != "200"),
                      checks = count(),
                      last_seen = max(timestamp),
                      log = takeLast(content),
                      by:{ pod }
          | filter latest_status != "200"
          | fieldsAdd check_name = "broker policy maintenance_healthcheck"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "pod"
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
        value = "【Broker Policy Maintenance】ReadinessProbe失敗エラー(HealthCheck)"
      }
      property {
        key   = "event.description"
        value = "broker-policy-maintenance /meta/health is returning a non-200 status. See pod, latest_status and log on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "broker-policy-maintenance"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
