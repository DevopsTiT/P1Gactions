# Same settings as CCI_AWS_Batch Time Out
# Index: ccifa-commission-glue-etl | Source: /aws-glue/jobs/custom/ccifa-commission-glue-etl | Retention: 100d
resource "splunk_saved_searches" "alert_ccifa_commission_glue_etl" {
  name        = "CCIFA_commission_glue_etl_AWS_Batch Time Out"
  description = "Task timed out on index ccifa-commission-glue-etl (source: /aws-glue/jobs/custom/ccifa-commission-glue-etl)"

  search = "index=\"ccifa-commission-glue-etl\" \"Task timed out\" | search message!=\"*DEBUG*\""

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
