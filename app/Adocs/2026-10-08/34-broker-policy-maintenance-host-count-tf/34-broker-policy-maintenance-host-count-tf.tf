# Splunk: broker-policy-maintenance host count (detect logs not being forwarded to splunk)
#   index=brokerpolicymaintenance-prod-axa-li-jp
#   | stats dc(host) as host
#   cron 0 * * * * (hourly), Last 60 minutes, Expires 24h
#   Trigger: Custom "search host < 2", Once, no throttle
#   Action: Send email, Priority Normal (recipients not copied)
#
# What it watches: the two broker-policy-maintenance-web pods (host = pod name, e.g.
#   broker-policy-maintenance-web-5649696b64-xxxxx). Logs reach Splunk through the
#   s3://axa-li-jp-logforwarders-prod bucket. Fewer than 2 pods logging in an hour means
#   a pod is down or the forwarder stopped.
#
# Dynatrace: summarize without "by" always returns 1 row, so 0 pods gives pod_count = 0 and still fires.
#   Runs every minute over 60 minutes (Splunk only checked once an hour).
#
# CONFIRM before apply (check.dql):
#   1. Which field holds the pod name in Dynatrace (k8s.pod.name or host.name); query 1 shows it
#   2. Replica count is still 2; if it changed, change "pod_count < 2"

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "broker_policy_maintenance_host_count" {
  title       = "broker-policy-maintenance host count (detect logs not being forwarded)"
  description = "Fewer than 2 broker-policy-maintenance-web pods sent logs in the last 60 minutes. A pod is down or log forwarding stopped."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter matchesValue(k8s.pod.name, "broker-policy-maintenance-web-*") or matchesValue(host.name, "broker-policy-maintenance-web-*")
          | fieldsAdd pod = coalesce(k8s.pod.name, host.name)
          | summarize pod_count = countDistinct(pod), last_seen = max(timestamp)
          | filter pod_count < 2
          | fieldsAdd check = "broker_policy_maintenance_host_count"
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
        value = "broker-policy-maintenance host count < 2"
      }
      property {
        key   = "event.description"
        value = "Fewer than 2 broker-policy-maintenance-web pods sent logs in the last 60 minutes (expected 2). See pod_count on the problem. Check the pods and the log forwarder."
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
