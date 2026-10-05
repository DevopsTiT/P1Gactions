# ALERT: BRE alert (InnoRules Lambda logs a line with log level ERROR)
# Converted from dynatrace_log_alert. Pages PagerDuty.

variable "bre_pagerduty_routing_key" {
  description = "PagerDuty Events v2 routing key for the BRE service. Pass from a CI secret, never commit."
  type        = string
  sensitive   = true
}

resource "dynatrace_davis_anomaly_detectors" "bre_alert_innorules" {
  title       = "Prod_Life_BRE_InnoRulesError"
  description = "Alert when logs from innorules-prod contain log level ERROR."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/innorules-prod"
          | filter contains(content, "ERROR")
          | parse content, "LD SPACE LD SPACE WORD:loglevel"
          | filter loglevel == "ERROR"
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
        value = "Prod_Life_BRE_InnoRulesError"
      }
      property {
        key   = "event.description"
        value = "BRE alert: InnoRules ERROR detected in /aws/lambda/innorules-prod."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "bre_innorules_pagerduty" {
  title       = "Prod_Life_BRE_InnoRulesError - PagerDuty"
  description = "Sends the BRE InnoRules problem to the BRE PagerDuty service."

  tasks {
    task {
      name        = "pagerduty_trigger"
      description = "PagerDuty Events v2 trigger for the BRE service"
      action      = "dynatrace.automations:http-function"
      active      = true
      input = jsonencode({
        method = "POST"
        url    = "https://events.pagerduty.com/v2/enqueue"
        headers = {
          "Content-Type" = "application/json"
        }
        payload = jsonencode({
          routing_key  = var.bre_pagerduty_routing_key
          event_action = "trigger"
          dedup_key    = "dt-problem-{{ event()[\"display_id\"] }}"
          payload = {
            summary  = "BRE alert: InnoRules ERROR detected"
            source   = "innorules-prod"
            severity = "error"
            custom_details = {
              problem_id = "{{ event()[\"display_id\"] }}"
            }
          }
        })
      })
      position {
        x = 0
        y = 1
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
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_BRE_InnoRulesError\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
