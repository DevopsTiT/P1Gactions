# pmt-api-prod: 9 Splunk-style alerts → 8 detectors (alerts 6 and 7 were duplicates)
# plus 3 email workflows, one per recipient group.

locals {
  pmt_log_group = "/aws/lambda/pmt-api-prod"

  # Extracts the number from Lambda REPORT lines: "... Max Memory Used: 312 MB ..."
  pmt_parse = "parse content, \"LD 'Max Memory Used: ' INT:memory_usage\""

  pmt_alerts = {
    unexpected_error = {
      name        = "Prod_Life_PMT_UnexpectedError_Normal"
      description = "pmt-api logged 'Unexpected error'."
      match       = "contains(content, \"Unexpected error\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
    memory_usage_high = {
      name        = "Prod_Life_PMT_STPAPIsMemoryUsageOver480MB_Normal"
      description = "pmt-api Lambda used more than 480 MB of memory in one invocation."
      match       = "isNotNull(memory_usage)"
      series      = "memory_mb = max(memory_usage)"
      threshold   = "480"
      group       = "pa_koichi"
    }
    transformation_timeout = {
      name        = "Prod_Life_PMT_TransformationTimeout_Normal"
      description = "pmt-api Lambda hit its timeout ('Task timed out')."
      match       = "contains(content, \"Task timed out\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
    send_approval_reminder_failed = {
      name        = "Prod_Life_PMT_SendApprovalReminderHandlerFailed_Normal"
      description = "SendApprovalReminder handler failed."
      match       = "contains(content, \"SendApprovalReminder handler failed\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
    sfdc_error = {
      name        = "Prod_Life_PMT_SFDCError_Normal"
      description = "An error occurred while calling the SFDC (Salesforce) API."
      match       = "contains(content, \"An error occurred while calling sfdc api\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "adept"
    }
    exception_myaxa_mail_sender = {
      name        = "Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal"
      description = "This alert is used for detecting the exception in MyAxa Mail sender."
      match       = "contains(content, \"Exception in myAxaMailSender\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "none"
    }
    exception_export_data = {
      name        = "Prod_Life_PMT_ExceptionInExportDataForDatalake_Normal"
      description = "Exception in ExportData for Datalake."
      match       = "contains(content, \"Exception in ExportData\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa_koichi"
    }
    email_sending_error = {
      name        = "Prod_Life_PMT_EmailSendingProcessError_Normal"
      description = "Error occurred during email sending process for a user."
      match       = "contains(content, \"Error occurred during email sending process for this user\", caseSensitive: false)"
      series      = "count = count(default: 0)"
      threshold   = "0"
      group       = "pa"
    }
  }

  pmt_email_groups = {
    pa = {
      to      = ["alj_jp_dl_processautomation@axa.co.jp"]
      subject = "Alert: {{ event()[\"event.name\"] }}"
    }
    pa_koichi = {
      to      = ["koichi.nagamine@axa.co.jp", "alj_jp_dl_processautomation@axa.co.jp"]
      subject = "Alert: {{ event()[\"event.name\"] }}"
    }
    adept = {
      to      = ["ALJ_JP_DL_adept@axa.co.jp"]
      subject = "[pmt-api] SFDC処理失敗のお知らせ"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "pmt_api" {
  for_each = local.pmt_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "${local.pmt_log_group}"
          | ${local.pmt_parse}
          | filter ${each.value.match}
          | makeTimeseries ${each.value.series}, interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "5"
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
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = "${each.value.description} Log group ${local.pmt_log_group}."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "pmt_api_email" {
  for_each = local.pmt_email_groups

  title       = "pmt-api alerts - email (${each.key})"
  description = "Emails recipient group ${each.key} when one of its pmt-api problems opens."

  tasks {
    task {
      name        = "recent_lines"
      description = "Matching lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "${local.pmt_log_group}"
          | ${local.pmt_parse}
          | filter ${join(" or ", [for a in local.pmt_alerts : "(${a.match == "isNotNull(memory_usage)" ? "memory_usage > 480" : a.match})" if a.group == each.key])}
          | fields timestamp, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email recipient group ${each.key}"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = each.value.to
        cc      = []
        bcc     = []
        subject = each.value.subject
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\n\n{% for r in result(\"recent_lines\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_lines = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = join(" or ", [for a in local.pmt_alerts : "matchesPhrase(event.name, \"${a.name}\")" if a.group == each.key])
          trigger_on    = "open"
        }
      }
    }
  }
}
