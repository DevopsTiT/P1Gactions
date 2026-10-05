# 3 Splunk alerts → 3 Dynatrace detectors (no workflows)
#
#   AGPO-Auth0-Password-SyncError              → agpo_eip_claims_alerts["agpo_auth0_password_sync_error"]
#   ALERT-EIP-MQ-CONN-TIMEOUT                  → agpo_eip_claims_alerts["eip_mq_connection_timeout"]
#   Auto-Assessment API Error - !PRODUCTION!   → agpo_eip_claims_alerts["claims_auto_assessment_api_error"]
#
# PagerDuty integration key in the AGPO screenshot is NOT copied. Paging goes through the
# standard SILVA / PagerDuty flow using the pagerduty.enabled and app.name properties.
#
# CONFIRM before apply (check.dql query 1 to 3):
#   sourcetype=agportalapi-prod-axa-li-jp host=agpo-cloud-authorization-process-api-*
#       → guessed k8s.namespace.name and k8s.pod.name
#   index=mq host=wpalja21b*.prprivmgmt.intraxa          → guessed host.name
#   index=claimsda* host=claims-auto-assessment-api*      → guessed k8s.pod.name (or host.name)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}

locals {
  agpo_eip_claims_alerts = {

    # Splunk: sourcetype="agportalapi-prod-axa-li-jp" host="agpo-cloud-authorization-process-api-*"
    #         ("IamCChangePasswordBadRequestResponse" OR "IamCChangePasswordNotFoundResponse")
    #   Last 5 minutes, every 5 minutes, results > 1, throttle 5 seconds, PagerDuty
    #   "> 1" means 2 or more errors in 5 minutes.
    agpo_auth0_password_sync_error = {
      name        = "Prod_AGPO_Auth0PasswordSyncError_High"
      description = "2 or more Auth0 password change errors (BadRequest or NotFound) in 5 minutes in the AGPO cloud authorization process API."
      severity    = "high"
      app_name    = "AGPO"
      pagerduty   = "1"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "agportalapi-prod-axa-li-jp"
        | filter startsWith(k8s.pod.name, "agpo-cloud-authorization-process-api-")
        | filter contains(content, "IamCChangePasswordBadRequestResponse")
              or contains(content, "IamCChangePasswordNotFoundResponse")
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      threshold   = "1"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=mq host="wpalja21b*.prprivmgmt.intraxa" *Connection timed out*
    #   Last 1 minute, every minute, results > 0, email alj_jp_dl_infra_mwss, Normal
    eip_mq_connection_timeout = {
      name        = "Prod_EIP_MQConnectionTimeout_Normal"
      description = "Connection timed out between EIP and MQ on wpalja21b* hosts. Check MQ status and EIP logs."
      severity    = "medium"
      app_name    = "EIP"
      pagerduty   = "0"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(host.name, "wpalja21b*")
        | filter contains(content, "Connection timed out", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "0"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=claimsda* host IN ("claims-auto-assessment-api*") ("*] ERROR *")
    #         NOT ("*Error stacktraces are turned on*")
    #   Last 10 minutes, every 10 minutes, results > 0, For each result, High,
    #   email incident claims IT list and claims agility list
    claims_auto_assessment_api_error = {
      name        = "Prod_Claims_AutoAssessmentAPIError_High"
      description = "Claims Auto-Assessment API logged ERROR lines (excluding the 'Error stacktraces are turned on' startup notice)."
      severity    = "high"
      app_name    = "Claims Auto-Assessment API"
      pagerduty   = "0"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(k8s.pod.name, "claims-auto-assessment-api*")
              or matchesValue(host.name, "claims-auto-assessment-api*")
        | filter contains(content, "] ERROR ")
        | filter not contains(content, "Error stacktraces are turned on")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "0"
      violating   = "1"
      window      = "10"
      dealerting  = "10"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "agpo_eip_claims_alerts" {
  for_each = local.agpo_eip_claims_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = each.value.violating
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = each.value.window
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
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
        value = each.value.name
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
        value = each.value.app_name
      }
      property {
        key   = "pagerduty.enabled"
        value = each.value.pagerduty
      }
    }
  }

  execution_settings {}
}
