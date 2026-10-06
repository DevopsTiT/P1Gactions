# Splunk alert → Dynatrace log event (Terraform only, no workflow, no makeTimeseries)
#
#   Cisco VPN : LDAP Connections are failing which will impact end users using windows basic
#     index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
#
# A log event fires on every log line that matches the matcher below.
# There is no per-minute count, so no makeTimeseries and no threshold.
# Real data has one line per failed LDAP server, so each failure raises one event.
#
# PagerDuty key is NOT copied. Paging goes through the standard SILVA / PagerDuty flow
# using the app.name and pagerduty.enabled properties.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_API_TOKEN (settings.read, settings.write)
provider "dynatrace" {}

resource "dynatrace_log_events" "cisco_vpn_ldap_failed" {
  enabled = true
  summary = "Prod_Network_CiscoVPN_LDAPFailed_Critical"
  query   = "matchesValue(log.source, \"/var/log/ASA/*\") AND matchesPhrase(content, \"Windows_LDAP as FAILED\")"

  event_template {
    event_type  = "CUSTOM_ALERT"
    title       = "Cisco VPN : LDAP Connections are failing which will impact end users"
    description = "Cisco ASA marked a Windows_LDAP aaa-server as FAILED. VPN users who log in with Windows credentials may be impacted. Log line: {content}"
    davis_merge = false

    metadata {
      item {
        metadata_key   = "alert.severity"
        metadata_value = "critical"
      }
      item {
        metadata_key   = "app.name"
        metadata_value = "Cisco VPN"
      }
      item {
        metadata_key   = "pagerduty.enabled"
        metadata_value = "1"
      }
    }
  }
}
