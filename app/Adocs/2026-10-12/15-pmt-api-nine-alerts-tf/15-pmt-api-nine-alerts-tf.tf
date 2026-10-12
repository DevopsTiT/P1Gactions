# Source: Migration/CW/configuration 2/pmt-api.tf
#   Nine "dynatrace_log_alert" resources. That type does not exist in the dynatrace-oss/dynatrace provider.
#   All rewritten as Records detectors (Davis anomaly detectors).
#
# All nine: cron */5 * * * *, expires 24, results > 0, once. Most windows LAST_5_MINUTES; Alert 3 LAST_6_MINUTES.
#   Alerts 4, 6, 7, 8, 9 had a 60-SECOND throttle (shorter than the window, so it changes almost nothing).
#   Actions: email Normal (Alerts 1-5, 8, 9; recipients not copied) or Dynatrace problem MEDIUM (Alerts 6, 7).
#   → alert.severity = "medium" for all. No PagerDuty anywhere → pagerduty.enabled = "0".
#
# Changes from the original:
#   Alert 2: FIXED parse. "LD 'Used:' SPACE? LD:MemoryUsage" captured "123 MB Init Duration: ..." so
#            toLong() returned null and the alert could never fire. Now reads the number with INT.
#
# CONFIRM before apply (check.dql):
#   1. Alerts 6 and 7 have the SAME query ("Exception in myAxaMailSender"). One exception opens two problems.
#      Keep one (Alert 7 has the proper Prod_Life_ name and description).
#   2. Alert 9 searches "Error occured" (one r) but its title says "occurred". If the app logs "occurred",
#      the alert never fires (query 3).
#   3. Alert 3 "Task timed out" covers every pmt-api function, not only the transformation step.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  pmt_api_alerts = {
    pmt_api_unexpected_error = {
      title       = "Unexpected Error"
      description = "pmt-api logged 'Unexpected error' (SFDC errors excluded; they have their own alert)."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Unexpected error", caseSensitive:false)
        | filter not contains(content, "sfdc", caseSensitive:false)
      EOT
    }
    pmt_api_memory_usage_high = {
      title       = "STP APIs Memory Usage over 480MB"
      description = "A pmt-api Lambda invocation used more than 480 MB of memory (Max Memory Used in the REPORT line)."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Max Memory Used", caseSensitive:false)
        | parse content, "LD 'Max Memory Used:' SPACE? INT:MemoryUsage"
        | filter MemoryUsage > 480
      EOT
    }
    pmt_api_transformation_timeout = {
      title       = "TransFormation Timeout"
      description = "A pmt-api Lambda hit its timeout ('Task timed out')."
      query       = <<-EOT
        fetch logs, from:now()-6m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Task timed out", caseSensitive:false)
      EOT
    }
    pmt_api_send_approval_reminder_failed = {
      title       = "SendApprovalReminder handler failed"
      description = "The SendApprovalReminder handler in pmt-api failed."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "SendApprovalReminder handler failed", caseSensitive:false)
      EOT
    }
    pmt_api_sfdc_error = {
      title       = "pmt-api SFDC Error"
      description = "[pmt-api] SFDC処理失敗のお知らせ: an error occurred while calling the SFDC (Salesforce) API."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "An error occurred while calling sfdc api", caseSensitive:false)
      EOT
    }
    pmt_api_exception_myaxa_mail_sender = {
      title       = "Exception in myAxaMailSender"
      description = "pmt-api logged an exception in myAxaMailSender. (Same query as emma_exception_myaxa_mail_sender.)"
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Exception in myAxaMailSender", caseSensitive:false)
      EOT
    }
    emma_exception_myaxa_mail_sender = {
      title       = "Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal"
      description = "This alert is used for detecting the exception in MyAxa Mail sender."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Exception in myAxaMailSender", caseSensitive:false)
      EOT
    }
    pmt_api_exception_export_data = {
      title       = "Exception in ExportData for Datalake"
      description = "pmt-api logged an exception while exporting data for the Datalake."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Exception in ExportData", caseSensitive:false)
      EOT
    }
    pmt_api_email_sending_error = {
      title       = "Error occurred during email sending process for this user"
      description = "pmt-api failed to send an email to a user."
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter contains(aws.log_group, "pmt-api")
        | filter contains(content, "Error occured during email sending process for this user", caseSensitive:false)
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "pmt_api" {
  for_each = local.pmt_api_alerts

  title       = each.value.title
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "aws.log_group"
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
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = "${each.value.description} See the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "pmt-api"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
