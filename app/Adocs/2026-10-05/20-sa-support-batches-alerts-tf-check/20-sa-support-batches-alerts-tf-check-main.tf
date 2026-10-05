# sa-support-batches-prod: 3 alerts converted from dynatrace_log_alert
# Alerts 1 and 3 (error, timeout, every 5 min) → 2 detectors (for_each) + 1 email workflow
# Alert 2 (weekday 08:30 "did the import run?")  → scheduled workflow, emails when fewer than 2 lines

locals {
  sa_log_group = "/aws/lambda/sa-support-batches-prod"
  sa_prefix    = "Prod_Life_SA_SupportBatch"

  sa_alerts = {
    batch_error = {
      name        = "${local.sa_prefix}_Error_Normal"
      description = "sa-support-batches logged an error."
      match       = "contains(content, \"error\", caseSensitive: false)"
    }
    task_timeout = {
      name        = "${local.sa_prefix}_TaskTimeOut_Normal"
      description = "sa-support-batches Lambda hit its timeout ('Task timed out')."
      match       = "contains(content, \"Task timed out\", caseSensitive: false)"
    }
  }

  # Confirm against real lines (check.dql query 2). The original used OR with "started",
  # which matches almost anything and hides a missing run.
  sa_import_match = "contains(content, \"importFileHandler :: runner\", caseSensitive: false) and contains(content, \"importSagaFundGroup\", caseSensitive: false)"
}

resource "dynatrace_davis_anomaly_detectors" "sa_support_batch" {
  for_each = local.sa_alerts

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
          | filter aws.log_group == "${local.sa_log_group}"
          | filter ${each.value.match}
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
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
        value = "${each.value.description} Log group ${local.sa_log_group}."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "sa_support_batch_email" {
  title       = "${local.sa_prefix} - email"
  description = "Emails the common-infra team when an sa-support-batches error or timeout problem opens."

  tasks {
    task {
      name        = "recent_lines"
      description = "Error and timeout lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "${local.sa_log_group}"
          | filter ${join(" or ", [for a in local.sa_alerts : "(${a.match})"])}
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
      description = "Email the common-infra team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "alj_jp_dl_bap_commoninfsound2@axa.co.jp",
          "maki.kawauchi.os@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: {{ event()[\"event.name\"] }}"
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
          custom_filter = "startsWith(event.name, \"${local.sa_prefix}_\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# Alert 2: weekday 08:30 check that the file import ran (at least 2 matching lines in 24 h)
resource "dynatrace_automation_workflow" "sa_support_batch_file_import_confirmation" {
  title       = "${local.sa_prefix}_FileImportConfirmation_Normal"
  description = "Weekdays 08:30 JST: email the annuity payment team if the file import logged fewer than 2 lines in the last 24 hours."

  tasks {
    task {
      name        = "count_import_lines"
      description = "Import lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter aws.log_group == "${local.sa_log_group}"
          | filter ${local.sa_import_match}
          | summarize total = count(), last_seen = max(timestamp)
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the annuity payment team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["axa_jp_dl_bap_annuitypayment@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: ${local.sa_prefix}_FileImportConfirmation_Normal (import may not have run)"
        content = "sa-support-batches file import logged {{ result(\"count_import_lines\").records[0].total }} matching lines in the last 24 hours (expected at least 2).\nLast seen: {{ result(\"count_import_lines\").records[0].last_seen }}"
      })
      conditions {
        states = {
          count_import_lines = "OK"
        }
        custom = "{{ result(\"count_import_lines\").records[0].total < 2 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "30 8 * * 1-5"
      }
    }
  }
}
