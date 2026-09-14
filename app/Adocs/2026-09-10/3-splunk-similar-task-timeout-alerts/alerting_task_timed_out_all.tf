# Auto-generated: same settings as CCI_AWS_Batch Time Out
# Schedule */5, window -5m, results > 0 once, PagerDuty

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

# Index: b2b-auth0 | Source: /aws/events/b2b-auth0-prod | Retention: 180d
resource "splunk_saved_searches" "alert_b2b_auth0" {
  name        = "B2B_Auth0_AWS_Batch Time Out"
  description = "Task timed out on index b2b-auth0 (source: /aws/events/b2b-auth0-prod)"

  search = "index=\"b2b-auth0\" \"Task timed out\" | search message!=\"*DEBUG*\""

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

# Index: biloss-link-data-to-cc | Source: /aws/lambda/BILoss-link-data-to-cc-prod | Retention: 90d
resource "splunk_saved_searches" "alert_biloss_link_data_to_cc" {
  name        = "BILOSS_link_data_to_cc_AWS_Batch Time Out"
  description = "Task timed out on index biloss-link-data-to-cc (source: /aws/lambda/BILoss-link-data-to-cc-prod)"

  search = "index=\"biloss-link-data-to-cc\" \"Task timed out\" | search message!=\"*DEBUG*\""

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

# Index: biloss-pre-processing | Source: /aws/lambda/BILoss-pre-processing-prod | Retention: 90d
resource "splunk_saved_searches" "alert_biloss_pre_processing" {
  name        = "BILOSS_pre_processing_AWS_Batch Time Out"
  description = "Task timed out on index biloss-pre-processing (source: /aws/lambda/BILoss-pre-processing-prod)"

  search = "index=\"biloss-pre-processing\" \"Task timed out\" | search message!=\"*DEBUG*\""

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

# Index: biloss-processing | Source: /aws/lambda/BILoss-processing-prod | Retention: 90d
resource "splunk_saved_searches" "alert_biloss_processing" {
  name        = "BILOSS_processing_AWS_Batch Time Out"
  description = "Task timed out on index biloss-processing (source: /aws/lambda/BILoss-processing-prod)"

  search = "index=\"biloss-processing\" \"Task timed out\" | search message!=\"*DEBUG*\""

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

# Index: biloss-retrieve-files-cmx | Source: /aws/lambda/BILoss-retrieve-files-cmx-prod | Retention: 90d
resource "splunk_saved_searches" "alert_biloss_retrieve_files_cmx" {
  name        = "BILOSS_retrieve_files_cmx_AWS_Batch Time Out"
  description = "Task timed out on index biloss-retrieve-files-cmx (source: /aws/lambda/BILoss-retrieve-files-cmx-prod)"

  search = "index=\"biloss-retrieve-files-cmx\" \"Task timed out\" | search message!=\"*DEBUG*\""

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

# Index: biloss-upload-to-cmx | Source: /aws/lambda/BILoss-upload-to-cmx-prod | Retention: 90d
resource "splunk_saved_searches" "alert_biloss_upload_to_cmx" {
  name        = "BILOSS_upload_to_cmx_AWS_Batch Time Out"
  description = "Task timed out on index biloss-upload-to-cmx (source: /aws/lambda/BILoss-upload-to-cmx-prod)"

  search = "index=\"biloss-upload-to-cmx\" \"Task timed out\" | search message!=\"*DEBUG*\""

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

# Index: cloudfront | Source: s3://alj-prod-cloudfront-singapore | Retention: 100d
resource "splunk_saved_searches" "alert_cloudfront" {
  name        = "CloudFront_AWS_Batch Time Out"
  description = "Task timed out on index cloudfront (source: s3://alj-prod-cloudfront-singapore)"

  search = "index=\"cloudfront\" \"Task timed out\" | search message!=\"*DEBUG*\""

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
