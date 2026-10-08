# Two Splunk alerts → two Records detectors
#
# 1. ALERT-EIP-MQ-CONN-TIMEOUT
#    index=mq host="wpalja21b*.prprivmgmt.intraxa" *Connection timed out*
#    cron */1, Last 1 minute, results > 0, Once, no throttle, email infra list, Normal
#    Log file: /var/mqm/qmgrs/MQSRVPROD/errors/AMQERR01.LOG (sourcetype mq-batch)
#
# 2. AGPO-Auth0-Password-SyncError
#    sourcetype="agportalapi-prod-axa-li-jp" host="agpo-cloud-authorization-process-api-*"
#      "IamCChangePasswordBadRequestResponse" OR "IamCChangePasswordNotFoundResponse"
#    cron */5, Last 5 minutes, results > 1, Once, throttle 5 seconds, PagerDuty action
#    Hosts are Kubernetes pods; logs arrive via s3://axa-li-jp-logforwarders-prod
#
# CONFIRM before apply (check.dql):
#   query 1: MQ log host and log.source in Dynatrace
#   query 2: AGPO pod name in host.name or k8s.pod.name
# PagerDuty integration key from Splunk is NOT copied; routing uses pagerduty.enabled.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  alerts = {

    eip_mq_conn_timeout = {
      title       = "ALERT-EIP-MQ-CONN-TIMEOUT"
      description = "Timeout between EIP and MQ (Connection timed out in the MQ error log on wpalja21b*). Check MQ status and EIP logs."
      severity    = "medium"
      pagerduty   = "0"
      app         = "EIP"
      # 2 minutes instead of Splunk's 1 so a line that arrives a little late is not missed
      query = <<-EOT
        fetch logs, from:now()-2m
        | filter matchesValue(host.name, "wpalja21b*")
        | filter contains(content, "Connection timed out", caseSensitive:false)
        | fields timestamp, host.name, log.source, content
        | fieldsAdd check = "eip_mq_conn_timeout"
      EOT
    }

    agpo_auth0_password_sync_error = {
      title       = "AGPO-Auth0-Password-SyncError"
      description = "More than 1 Auth0 password change error (BadRequest or NotFound) from agpo-cloud-authorization-process-api in the last 5 minutes."
      severity    = "high"
      pagerduty   = "1"
      app         = "AGPO"
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter startsWith(host.name, "agpo-cloud-authorization-process-api-") or startsWith(k8s.pod.name, "agpo-cloud-authorization-process-api-")
        | filter contains(content, "IamCChangePasswordBadRequestResponse", caseSensitive:false)
              or contains(content, "IamCChangePasswordNotFoundResponse", caseSensitive:false)
        | summarize count = count()
        | filter count > 1
        | fieldsAdd check = "agpo_auth0_password_sync_error"
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "eip_agpo_alerts" {
  for_each = local.alerts

  title       = each.value.title
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = each.value.query
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
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
      property {
        key   = "app.name"
        value = each.value.app
      }
      property {
        key   = "pagerduty.enabled"
        value = each.value.pagerduty
      }
    }
  }

  execution_settings {}
}
