# CCI_AWS_Batch Time Out — Splunk alert (no variables)
# Fill PagerDuty integration key before apply. Do not commit real secrets to git.

terraform {
  required_providers {
    splunk = {
      source  = "splunk/splunk"
      version = "~> 1.4"
    }
  }
}

provider "splunk" {
}

resource "splunk_saved_searches" "cci_aws_batch_time_out" {
  name        = "CCI_AWS_Batch Time Out"
  description = "Task timed out on index cci-fa-comm-calc (Lambda cci-fa-comm-calc)"

  search = "index=\"cci-fa-comm-calc\" \"Task timed out\" | search message!=\"*DEBUG*\""

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
  action_pagerduty_integration_key = "REPLACE_WITH_PAGERDUTY_INTEGRATION_KEY"
  action_pagerduty_custom_details  = "{\"job_label\": \"$job.label$\"}"

  acl {
    owner   = "admin"
    sharing = "app"
    app     = "search"
  }
}
