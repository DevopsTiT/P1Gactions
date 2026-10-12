terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
# Last 1 minute, more than 3 results, severity Critical, PagerDuty and email.
# The content phrase alone is specific to the Cisco ASA. After running check query 1,
# you can add a source filter, for example: | filter log.source == "<value from query 1>"
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN in case LDAP connections fail due to backend system issues, which impacts VPN users and business users. Fires when more than 3 Windows_LDAP FAILED lines arrive in 1 minute."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1m
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
          | summarize failures = count(), sample = takeFirst(content)
          | filter failures > 3
          | fieldsAdd scope = "cisco-vpn-windows-ldap"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "More than 3 Cisco ASA Windows_LDAP FAILED lines in 1 minute. VPN users who sign in with Windows basic auth may be unable to connect. See failures and sample on the problem."
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
