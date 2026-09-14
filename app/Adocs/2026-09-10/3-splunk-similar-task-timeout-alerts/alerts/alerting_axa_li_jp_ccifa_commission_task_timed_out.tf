# Same settings as CCI_AWS_Batch Time Out
# Index: axa-li-jp-ccifa-commission | Source: /aws/lambda/axa-li-jp-ccifa-commission-code-prod-ServicesHealthCheck | Retention: 7d
resource "splunk_saved_searches" "alert_axa_li_jp_ccifa_commission" {
  name        = "AXA_LI_JP_CCIFA_Commission_AWS_Batch Time Out"
  description = "Task timed out on index axa-li-jp-ccifa-commission (source: /aws/lambda/axa-li-jp-ccifa-commission-code-prod-ServicesHealthCheck)"

  search = "index=\"axa-li-jp-ccifa-commission\" \"Task timed out\" | search message!=\"*DEBUG*\""

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
