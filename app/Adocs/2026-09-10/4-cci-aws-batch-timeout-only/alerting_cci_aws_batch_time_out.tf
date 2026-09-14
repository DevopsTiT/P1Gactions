# Splunk alert — CCI_AWS_Batch Time Out only
# Matches Splunk Edit Alert UI (scheduled + PagerDuty)
# Index sheet: cci-fa-comm-calc | Migration Yes | Source /aws/lambda/cci-fa-comm-calc | Retention 100

resource "splunk_saved_searches" "cci_aws_batch_time_out" {
  name        = "CCI_AWS_Batch Time Out"
  description = "Task timed out on index cci-fa-comm-calc (Lambda cci-fa-comm-calc)"

  # UI had a broken quote; corrected SPL:
  #   index="cci-fa-comm-calc" "Task timed out" | search message!="*DEBUG*"
  search = "index=\"cci-fa-comm-calc\" \"Task timed out\" | search message!=\"*DEBUG*\""

  # Schedule — Cron every 5 minutes, Last 5 minutes
  is_scheduled           = true
  cron_schedule          = "*/5 * * * *"
  dispatch_earliest_time = "-5m"
  dispatch_latest_time   = "now"

  # Trigger — Number of Results greater than 0, Trigger once, no throttle
  alert_type        = "number of events"
  alert_comparator  = "greater than"
  alert_threshold   = "0"
  alert_digest_mode = true
  alert_expires     = "24h"
  alert_track       = true
  alert_suppress    = false

  # Action — PagerDuty (Integration URL blank in UI)
  actions                          = "pagerduty"
  action_pagerduty_integration_key = var.pagerduty_integration_key
  action_pagerduty_custom_details  = jsonencode({ job_label = "$job.label$" })

  acl {
    owner   = var.splunk_alert_owner
    sharing = var.splunk_alert_sharing
    app     = var.splunk_alert_app
  }
}
