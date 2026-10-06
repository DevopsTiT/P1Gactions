# Splunk alert → Dynatrace detector (Terraform only, no workflow)
#
#   Cisco VPN : LDAP Connections are failing which will impact end users using windows basic
#     index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
#     Last 1 minute, every minute, results > 3, Critical, PagerDuty and email
#
# Query = the three lines agreed with the team. The last line (makeTimeseries) is required:
# a detector only accepts a query that returns a time series, and it rejects plain log rows.
#
# Real data: one line per failed LDAP server, so "> 3 in 1 minute" never fired.
# Set ldap_failed_threshold to "0" to alert on the first FAILED line.
#
# PagerDuty key is NOT copied. Paging goes through the standard SILVA / PagerDuty flow.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  ldap_failed_threshold = "3"
}

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title       = "Prod_Network_CiscoVPN_LDAPFailed_Critical"
  description = "Cisco ASA marked a Windows_LDAP server as FAILED. VPN users who log in with Windows credentials may be unable to connect."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "/var/log/ASA/") or matchesValue(host.name, "ljcmgt14*")
          | filter contains(content, "Windows_LDAP as FAILED")
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = local.ldap_failed_threshold
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
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "1"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "15"
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
        value = "Cisco VPN : LDAP Connections are failing which will impact end users"
      }
      property {
        key   = "event.description"
        value = "Cisco ASA (JPNDH-VASA19) marked a Windows_LDAP aaa-server as FAILED. VPN users using Windows login may be impacted. Check the LDAP servers 10.3.87.1 and 10.3.87.2."
      }
      property {
        key   = "alert.severity"
        value = "critical"
      }
      property {
        key   = "app.name"
        value = "Cisco VPN"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
