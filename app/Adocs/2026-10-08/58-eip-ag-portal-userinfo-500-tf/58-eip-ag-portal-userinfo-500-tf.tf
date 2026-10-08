# Splunk: Prod_Life_EIP_AGPortalUserInfoService_High
#   Description: This is an API service provided by AG Portal. It is consumed by Compass via EIP.
#   index=eip10 API_VERSION="jp-Distributing-Sell-UserInfoService-v1-vs" RESPONSE_CODE=500
#   cron */5, Last 5 minutes, Expires 30 minutes, results > 0, Once, Throttle 5 minutes
#   Actions: Add to Triggered Alerts (severity High), PagerDuty, Send email (recipients and keys not copied)
#
# Dynatrace: one problem while the AG Portal UserInfoService returns HTTP 500 through EIP.
#   Opens when at least one 500 was logged in the last 5 minutes; closes after a 5-minute window with none.
#   An open problem does not re-notify, which replaces Splunk's 5-minute throttle.
#   pagerduty "1": the alert has a direct PagerDuty action.
#
# CONFIRM before apply (check.dql):
#   1. Where eip10 logs land in Grail (log.source / host) and whether API_VERSION and RESPONSE_CODE are
#      attributes or only text in content (query 1). Add a log.source or host filter once known.
#   2. Normal 500 rate (query 2). If a single 500 is routine noise, raise "errors > 0" to a small threshold.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "eip_ag_portal_userinfo_service_500" {
  title       = "Prod_Life_EIP_AGPortalUserInfoService_High"
  description = "AG Portal UserInfoService (consumed by Compass via EIP) returned HTTP 500 in the last 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(content, "jp-Distributing-Sell-UserInfoService-v1-vs")
                or toString(API_VERSION) == "jp-Distributing-Sell-UserInfoService-v1-vs"
          | filter toString(RESPONSE_CODE) == "500"
                or contains(content, "RESPONSE_CODE=500")
                or contains(content, "RESPONSE_CODE=\"500\"")
                or contains(content, "\"RESPONSE_CODE\":500")
                or contains(content, "\"RESPONSE_CODE\":\"500\"")
          | summarize errors = count(), first_seen = min(timestamp), last_seen = max(timestamp)
          | filter errors > 0
          | fieldsAdd check = "eip_ag_portal_userinfo_service_500"
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
        value = "Prod_Life_EIP_AGPortalUserInfoService_High"
      }
      property {
        key   = "event.description"
        value = "AG Portal UserInfoService (jp-Distributing-Sell-UserInfoService-v1-vs) returned HTTP 500 via EIP in the last 5 minutes. Compass user info calls are failing. See errors and last_seen on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "EIP AG Portal UserInfoService"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
