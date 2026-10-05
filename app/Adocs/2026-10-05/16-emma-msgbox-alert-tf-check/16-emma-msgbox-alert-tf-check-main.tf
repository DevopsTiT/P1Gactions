# ALERT: Prod_Life_Emma_OverallMsgBoxErrors_Normal
# More than 5 error or warn lines from message-box-api-prod within 5 minutes

locals {
  emma_msgbox_filter = <<-EOT
    | filter aws.log_group == "/aws/lambda/message-box-api-prod"
    | filter contains(content, "error", caseSensitive: false) or contains(content, "warn", caseSensitive: false)
  EOT
}

resource "dynatrace_davis_anomaly_detectors" "emma_overall_msgbox_errors" {
  title       = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
  description = "Catch unexpected errors related to Emma Life MsgBox: more than 5 error or warn lines in 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          ${local.emma_msgbox_filter}
          | makeTimeseries count = count(default: 0), interval:1m
          | fieldsAdd count = arrayMovingSum(count, 5)
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "5"
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
        value = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 5 error or warn lines from /aws/lambda/message-box-api-prod within 5 minutes."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "emma_overall_msgbox_errors_email" {
  title       = "Prod_Life_Emma_OverallMsgBoxErrors_Normal - email"
  description = "When the problem opens, email the recent error and warn lines. No PagerDuty (Normal)."

  tasks {
    task {
      name        = "recent_errors"
      description = "Error and warn lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          ${local.emma_msgbox_filter}
          | fields timestamp, status, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the Emma Teams channel and owners"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "e33bdf34.axa365.onmicrosoft.com@emea.teams.ms",
          "gregoire.homassel@axa.co.jp",
          "axa_jp_dl_bam@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Prod_Life_Emma_OverallMsgBoxErrors_Normal"
        content = "Problem {{ event()[\"display_id\"] }}: more than 5 error or warn lines in message-box-api-prod\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
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
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_Emma_OverallMsgBoxErrors_Normal\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
