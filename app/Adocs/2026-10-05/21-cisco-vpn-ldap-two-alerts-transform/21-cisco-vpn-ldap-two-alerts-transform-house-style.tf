# House-style version for the dynatrace-terraform repo (same layout as the other files in G/configuration).
# NOTE: dynatrace_log_alert is not a resource in the dynatrace-oss provider. Use main.tf for a real apply.
# ==========================================
# ALERT: Cisco VPN : LDAP Connections are failing (merged A + B)
# ==========================================

variable "network_pagerduty_integration_key" {
  description = "PagerDuty key for the network service. Pass from a CI secret, never commit."
  type        = string
  sensitive   = true
}

resource "dynatrace_log_alert" "cisco_vpn_ldap_failed" {
  enabled     = true
  alert_name  = "Cisco VPN : LDAP Connections are failing which will impact end users"
  description = "VPN users using Windows login cannot connect: ASA marked the Windows_LDAP server group FAILED more than 3 times in 1 minute."

  search_query = <<-EOT
    fetch logs
    | filter matchesValue(dt.system.bucket, "network*")
    | filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
    | dedup timestamp, content
    | sort timestamp desc
    | limit 100
  EOT

  alert_type      = "SCHEDULED"
  schedule_type   = "CUSTOM"
  cron_expression = "*/1 * * * *"
  time_range      = "LAST_1_MINUTES"
  expires         = 24

  trigger_conditions {
    trigger_alert_when = "NUMBER_OF_RESULTS"
    condition          = "GREATER_THAN"
    threshold          = 3
    trigger_mode       = "ONCE"
  }

  throttle_enabled = false

  trigger_actions {
    action_type = "DYNATRACE_PROBLEM"
    severity    = "CRITICAL"
  }

  trigger_actions {
    action_type        = "PAGERDUTY"
    integration_key    = var.network_pagerduty_integration_key
    custom_description = "Cisco VPN: Windows_LDAP marked FAILED (more than 3 in 1 minute)"
  }

  trigger_actions {
    action_type = "SEND_EMAIL"
    recipients = [
      "<network-team-dl>@axa.co.jp",
    ]
    priority = "HIGH"
    subject  = "[CRITICAL] Cisco VPN : LDAP Connections are failing which will impact end users"
  }
}
