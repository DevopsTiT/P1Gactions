terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
# Sample event:
#   %ASA-2-113022: AAA Marking LDAP server 10.3.87.2 in aaa-server group Windows_LDAP as FAILED
# The ASA writes one line per LDAP server when it marks that server failed.
# The old "more than 3 in 1 minute" could never be reached, so any line now opens a problem.
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN in case LDAP connections fail due to backend system issues, which impacts VPN users and business users. Fires when the Cisco ASA marks a Windows_LDAP server as FAILED (ASA-2-113022)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(content, "113022")
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
          | parse content, "LD 'LDAP server ' NSPACE:ldap_server"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "ldap_server"
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
        value = "Cisco VPN : LDAP server {ldap_server} marked FAILED"
      }
      property {
        key   = "event.description"
        value = "The Cisco ASA marked LDAP server {ldap_server} in group Windows_LDAP as FAILED. VPN users who sign in with Windows basic auth may be unable to connect. See the log line (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "cisco-vpn"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
