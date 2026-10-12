terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
# "/var/log/ASA" covers all four ASA files seen in Splunk:
#   JPNDH-VASA19-ALJ.log, JPNDH-VASA19-ADJ.log, JPNDH-VASA19.log, JPNDH-VASA17.log
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN in case LDAP connections fail due to backend system issues, which impacts VPN users and business users. Fires when a Cisco ASA log under /var/log/ASA reports Windows_LDAP as FAILED."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(log.source, "/var/log/ASA", caseSensitive:false)
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "log.source"
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
        value = "Cisco VPN : LDAP Connections are failing"
      }
      property {
        key   = "event.description"
        value = "A Cisco ASA marked a Windows_LDAP server as FAILED. VPN users who sign in with Windows basic auth may be unable to connect. See the log line (content) and log.source on the problem."
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
