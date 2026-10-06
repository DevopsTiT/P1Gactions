# Splunk alert → Dynatrace detector, Records data type (Terraform only, no workflow, no makeTimeseries)
#
#   Cisco VPN : LDAP Connections are failing which will impact end users using windows basic
#     index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
#
# Records analyzer: every row the query returns is a violation. No time series, no threshold.
# Without from: in the query the detector looks back 2 hours, so the alert stays open
# until 2 hours after the last FAILED line, then closes by itself.
# alertIdentityFields[0] = host.name keeps it to one open problem per host instead of one per line.
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

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title       = "Prod_Network_CiscoVPN_LDAPFailed_Critical"
  description = "Cisco ASA marked a Windows_LDAP server as FAILED. VPN users who log in with Windows credentials may be unable to connect."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "/var/log/ASA/") or matchesValue(host.name, "ljcmgt14*")
          | filter contains(content, "Windows_LDAP as FAILED")
        EOT
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
