# Two Splunk alerts → two Dynatrace Records detectors in one file (no workflow, no makeTimeseries)
#
# Splunk alert 1: Cisco VPN : LDAP Connections are failing which will impact end users
#   index=*network* sourcetype=asa_networksyslog *Windows_LDAP as FAILED*
# Splunk alert 2: Cisco VPN : LDAP Connections are failing which will impact end users using windows basic
#   index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
#
# Both Splunk alerts: Last 1 minute, cron */1, expires 24 hours, results > 3, Once, For each result,
# no throttle, Triggered Alerts (Critical), PagerDuty, Send email.
#
# Records analyzer: every row returned is a violation (no threshold, no time series).
# No from: in the query, so each detector looks back 2 hours and closes 2 hours after the last FAILED line.
# alertIdentityFields[0] = host.name: one open problem per host.
#
# CONFIRM alert 1 filter with check.dql query 3 (which log.source holds sourcetype asa_networksyslog).
# If both detectors match the same lines, the same failure pages twice: keep only one enabled.
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
  cisco_vpn_ldap_alerts = {
    ldap_failed_asa_networksyslog = {
      title      = "Prod_Network_CiscoVPN_LDAPFailed_AsaNetworksyslog_Critical"
      event_name = "Cisco VPN : LDAP Connections are failing which will impact end users"
      query      = <<-EOT
        fetch logs
        | filter contains(log.source, "networksyslog") or contains(log.source, "/var/log/ASA/")
        | filter contains(content, "Windows_LDAP as FAILED")
      EOT
    }
    ldap_failed_windows_basic = {
      title      = "Prod_Network_CiscoVPN_LDAPFailed_WindowsBasic_Critical"
      event_name = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
      query      = <<-EOT
        fetch logs
        | filter contains(log.source, "/var/log/ASA/") or matchesValue(host.name, "ljcmgt14*")
        | filter contains(content, "Windows_LDAP as FAILED")
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap" {
  for_each = local.cisco_vpn_ldap_alerts

  title       = each.value.title
  description = "Cisco ASA marked a Windows_LDAP server as FAILED. VPN users who log in with Windows credentials may be unable to connect."
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
        value = each.value.event_name
      }
      property {
        key   = "event.description"
        value = "This alert monitors the VPN in case LDAP connections are failing due to backend system issues, which will impact VPN users and business users. Cisco ASA marked a Windows_LDAP aaa-server as FAILED. Check the LDAP servers 10.3.87.1 and 10.3.87.2."
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
