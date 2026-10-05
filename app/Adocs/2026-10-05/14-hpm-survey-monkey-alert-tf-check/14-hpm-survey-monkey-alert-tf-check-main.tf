# ALERT: Prod_Life_HPM_SurveyMonkeyLambdaError_Normal
# Lambda hpm-survey-monkey-prod logged an error while transferring files from SurveyMonkey to S3

resource "dynatrace_davis_anomaly_detectors" "hpm_survey_monkey_lambda_error" {
  title       = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
  description = "To check Lambda error: failure transferring files from SurveyMonkey to S3 (hpm-survey-monkey-prod)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/hpm-survey-monkey-prod"
          | filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
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
        value = "60"
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
        value = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
      }
      property {
        key   = "event.description"
        value = "Lambda /aws/lambda/hpm-survey-monkey-prod logged an error. Failure transferring files from SurveyMonkey to S3."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "hpm_survey_monkey_lambda_error_email" {
  title       = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal - email"
  description = "When the problem opens, email the recent ERROR lines to the HPM team. No PagerDuty (Normal)."

  tasks {
    task {
      name        = "recent_errors"
      description = "ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          | filter aws.log_group == "/aws/lambda/hpm-survey-monkey-prod"
          | filter status == "ERROR" or contains(content, "ERROR", caseSensitive: false)
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
      description = "Email the HPM team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "naoya.sota@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
          "hiroshi.annaka@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Prod_Life_HPM_SurveyMonkeyLambdaError_Normal"
        content = "Problem {{ event()[\"display_id\"] }}: error in hpm-survey-monkey-prod (SurveyMonkey to S3)\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
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
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_HPM_SurveyMonkeyLambdaError_Normal\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
