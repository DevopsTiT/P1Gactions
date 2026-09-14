# Splunk alert: CCI_AWS_Batch Time Out
# Source: Splunk Edit Alert UI (scheduled + PagerDuty)
# Index from migration sheet: cci-fa-comm-calc (Retention 100)

resource "splunk_saved_searches" "cci_aws_batch_time_out" {
  name        = "CCI_AWS_Batch Time Out"
  description = ""

  # Fixed quote: UI showed index="cci-fa-comm-calc "Task timed out"
  # Correct SPL:
  search = "index=\"cci-fa-comm-calc\" \"Task timed out\" | search message!=\"*DEBUG*\""

  # Schedule — Run on Cron Schedule, every 5 minutes, Last 5 minutes
  is_scheduled            = true
  cron_schedule           = "*/5 * * * *"
  dispatch_earliest_time  = "-5m"
  dispatch_latest_time    = "now"

  # Trigger — Number of Results is greater than 0, Trigger once
  alert_type        = "number of events"
  alert_comparator  = "greater than"
  alert_threshold   = "0"
  alert_digest_mode = true
  alert_expires     = "24h"
  alert_track       = true
  alert_suppress    = false

  # Trigger Actions — PagerDuty
  actions                             = "pagerduty"
  action_pagerduty_integration_key    = var.pagerduty_integration_key_cci_batch
  action_pagerduty_custom_details     = jsonencode({ job_label = "$job.label$" })
  # Integration URL left blank in UI — omit or set empty:
  # action_pagerduty_integration_url  = ""

  acl {
    owner   = var.splunk_alert_owner
    sharing = var.splunk_alert_sharing
    app     = var.splunk_alert_app
  }
}
