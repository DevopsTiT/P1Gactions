# House-style version for the dynatrace-terraform repo (same layout as the other files in G/configuration).
# NOTE: dynatrace_log_alert is not a resource in the dynatrace-oss provider. Use main.tf for a real apply.
# ==========================================
# ALERT: OUD restart failed
# ==========================================

resource "dynatrace_log_alert" "oud_restart_failed" {
  enabled     = true
  alert_name  = "Prod_OUD_RestartFailed_High"
  description = "The OUD (Oracle Unified Directory) service restart logged 'failed'."

  search_query = <<-EOT
    fetch logs
    | filter matchesValue(log.source, "*oud_service*")
    | filter matchesPhrase(content, "failed")
    | sort timestamp desc
    | limit 100
  EOT

  alert_type      = "SCHEDULED"
  schedule_type   = "CUSTOM"
  cron_expression = "1 4 * * *"
  time_range      = "LAST_24_HOURS"
  expires         = 24

  trigger_conditions {
    trigger_alert_when = "NUMBER_OF_RESULTS"
    condition          = "GREATER_THAN"
    threshold          = 0
    trigger_mode       = "ONCE"
  }

  throttle_enabled = false

  trigger_actions {
    action_type = "DYNATRACE_PROBLEM"
    severity    = "HIGH"
  }

  trigger_actions {
    action_type = "SEND_EMAIL"
    recipients = [
      "<oud-team-dl>@axa.co.jp",
    ]
    priority = "HIGH"
    subject  = "[HIGH] OUD restart failed"
  }
}
