# eopt-serverless alerts, converted from dynatrace_log_alert

locals {
  eopt_log_group = "/aws/lambda/eopt-serverless-prod"

  # Lambda default line: 2026-10-05T01:02:03.456Z<TAB>request-id<TAB>ERROR<TAB>message
  # Swap for "| filter loglevel == \"ERROR\"" if the check query shows Dynatrace already sets loglevel
  eopt_error_filter = <<-EOT
    | parse content, "LD '-' LD '-' LD '-' LD '-' LD SPACE WORD:level"
    | filter level == "ERROR"
  EOT

  eopt_base = <<-EOT
    fetch logs
    | filter startsWith(aws.log_group, "${local.eopt_log_group}")
    ${local.eopt_error_filter}
  EOT
}

# ============================================================
# ALERT 1: E-Tool Error Lambda (Filtered Output)
# Every 5 minutes, any ERROR line → problem → email with timestamp, level, message
# ============================================================

resource "dynatrace_davis_anomaly_detectors" "etool_error_lambda" {
  title       = "E-Tool Error Lambda"
  description = "ERROR lines from Lambda eopt-serverless-prod."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = "${local.eopt_base}| makeTimeseries count = count(default: 0), interval:1m"
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
        value = "E-Tool Error Lambda"
      }
      property {
        key   = "event.description"
        value = "ERROR lines from Lambda eopt-serverless-prod."
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "etool_error_lambda_email" {
  title       = "E-Tool Error Lambda - email"
  description = "When the E-Tool Error Lambda problem opens, email the recent ERROR lines (timestamp, level, message)."

  tasks {
    task {
      name        = "recent_errors"
      description = "ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "${replace(local.eopt_base, "fetch logs", "fetch logs, from:now()-10m")}| fields timestamp, level, content\n| sort timestamp desc\n| limit 100"
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email E-Tool maintenance"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["aij_jp_dl_etool_maintenance@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: E-Tool Error Lambda"
        content = "Problem {{ event()[\"display_id\"] }}: ERROR lines from eopt-serverless-prod\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.level }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_errors = "OK"
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
          custom_filter = "matchesPhrase(event.name, \"E-Tool Error Lambda\")"
          trigger_on    = "open"
        }
      }
    }
  }
}

# ============================================================
# ALERT 2: eopt - AWS Serverless Error (Full Output)
# Daily digest at 10:00 JST over the last 24 hours, so a scheduled workflow
# ============================================================

resource "dynatrace_automation_workflow" "eopt_aws_serverless_error" {
  title       = "eopt - AWS Serverless Error"
  description = "Every day at 10:00 JST, email all ERROR lines from eopt-serverless-prod in the last 24 hours (full output)."

  tasks {
    task {
      name        = "count_errors"
      description = "Total ERROR lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "${replace(local.eopt_base, "fetch logs", "fetch logs, from:now()-24h")}| summarize total = count()"
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "list_errors"
      description = "Latest 100 ERROR lines, all fields"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = "${replace(local.eopt_base, "fetch logs", "fetch logs, from:now()-24h")}| sort timestamp desc\n| limit 100"
      })
      position {
        x = 1
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the daily digest"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "aij_jp_dl_etool_maintenance@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: eopt - AWS Serverless Error"
        content = "{{ result(\"count_errors\").records[0].total }} ERROR line(s) from eopt-serverless-prod in the last 24 hours. Latest 100:\n\n{% for r in result(\"list_errors\").records %}{{ r.timestamp }}  {{ r[\"aws.log_group\"] }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          count_errors = "SUCCESS"
          list_errors  = "SUCCESS"
        }
        custom = "{{ result(\"count_errors\").records[0].total > 0 }}"
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
        cron = "0 10 * * *"
      }
    }
  }
}
