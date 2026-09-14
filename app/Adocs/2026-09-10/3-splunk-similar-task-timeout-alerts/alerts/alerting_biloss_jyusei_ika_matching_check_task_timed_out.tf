# Same settings as CCI_AWS_Batch Time Out
# Index: biloss-jyusei-ika-matching-check | Source: /aws/lambda/BILoss-jyusei-ika-matching-check-prod | Retention: 90d
resource "splunk_saved_searches" "alert_biloss_jyusei_ika_matching_check" {
  name        = "BILOSS_jyusei_ika_matching_check_AWS_Batch Time Out"
  description = "Task timed out on index biloss-jyusei-ika-matching-check (source: /aws/lambda/BILoss-jyusei-ika-matching-check-prod)"

  search = "index=\"biloss-jyusei-ika-matching-check\" \"Task timed out\" | search message!=\"*DEBUG*\""

  is_scheduled           = true
  cron_schedule          = "*/5 * * * *"
  dispatch_earliest_time = "-5m"
  dispatch_latest_time   = "now"

  alert_type        = "number of events"
  alert_comparator  = "greater than"
  alert_threshold   = "0"
  alert_digest_mode = true
  alert_expires     = "24h"
  alert_track       = true
  alert_suppress    = false

  actions                          = "pagerduty"
  action_pagerduty_integration_key = var.pagerduty_integration_key
  action_pagerduty_custom_details  = jsonencode({ job_label = "$job.label$" })

  acl {
    owner   = var.splunk_alert_owner
    sharing = var.splunk_alert_sharing
    app     = var.splunk_alert_app
  }
}
