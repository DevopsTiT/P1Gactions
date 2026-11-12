resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_windows_ldap_failed" {
  title       = "ALJ_VPN Cisco LDAP connections failing"
  description = "LDAP connections are failing and can affect VPN users and business users."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-1m
| filter contains(content, "Windows_LDAP", caseSensitive:false)
| filter contains(content, "FAILED", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 3
| fieldsAdd alert_key = "cisco-asa-windows-ldap"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_VPN Cisco LDAP connections failing"
      }
      property {
        key   = "event.description"
        value = "ALJ_VPN Cisco LDAP connections failing detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
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

resource "dynatrace_alerting" "alj_vpn_alerting_profile" {
  name = "ALJ_VPN Alerting Profile"

  rules {
    rule {
      include_mode     = "NONE"
      delay_in_minutes = 0
      severity_level   = "ERROR"
    }
  }

  filters {
    filter {
      custom {
        title {
          enabled       = true
          operator      = "BEGINS_WITH"
          value         = "ALJ_VPN"
          case_sensitive = false
          negate        = false
        }
      }
    }
  }
}
