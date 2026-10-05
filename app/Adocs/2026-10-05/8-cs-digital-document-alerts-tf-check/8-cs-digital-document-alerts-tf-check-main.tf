# ============================================================
# ALERT 1: [CSDDM] Send alert email when Claims API fails
# Daily digest at 10:00 JST over the last 24 hours, so it is a scheduled workflow, not an anomaly detector
# ============================================================

resource "dynatrace_automation_workflow" "csddm_claims_api_fails" {
  title       = "[CSDDM] Send alert email when Claims API fails"
  description = "Every day at 10:00 JST, count 'claims api call failed' in cs-digital-document-management-prod over the last 24 hours and email if more than 0."

  tasks {
    task {
      name        = "count_failures"
      description = "Count Claims API failures in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter aws.log_group == "/aws/lambda/cs-digital-document-management-prod"
          | filter contains(content, "claims api call failed", caseSensitive: false)
          | summarize failures = count()
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the team when failures were found"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "honlun.chan@axa.co.jp",
          "masaya.okuno@axa.co.jp",
          "aij_jp_dl_incident_claims_it@axa.co.jp",
          "axa_jp_dl_claims_transformation@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: [CSDDM] Send alert email when Claims API fails"
        content = "Claims API call failed {{ result(\"count_failures\").records[0].failures }} time(s) in the last 24 hours.\nLog group: /aws/lambda/cs-digital-document-management-prod"
      })
      conditions {
        states = {
          count_failures = "SUCCESS"
        }
        custom = "{{ result(\"count_failures\").records[0].failures > 0 }}"
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

# ============================================================
# ALERT 2: CS Digital Document Management Error alerts
# Every 5 minutes, any "error" except "delivery not possible", throttle 1 hour
# ============================================================

resource "dynatrace_davis_anomaly_detectors" "cs_digital_document_management_error" {
  title       = "CS Digital Document Management Error alerts"
  description = "Alerts when an error occurs. Github Repo: cs-digital-document-management"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/cs-digital-document-management-prod"
          | filter contains(content, "error", caseSensitive: false)
          | filter not contains(content, "delivery not possible", caseSensitive: false)
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
        value = "CS Digital Document Management Error alerts"
      }
      property {
        key   = "event.description"
        value = "Error logged by /aws/lambda/cs-digital-document-management-prod (excluding 'delivery not possible'). Github Repo: cs-digital-document-management"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "cs_digital_document_management_error_email" {
  title       = "CS Digital Document Management Error alerts - email"
  description = "Emails the team when the CS Digital Document Management Error alerts problem opens."

  tasks {
    task {
      name        = "send_email"
      description = "Email the team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["aij_jp_dl_csdigitaldocument@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: CS Digital Document Management Error alerts"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\nLog group: /aws/lambda/cs-digital-document-management-prod"
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
          custom_filter = "matchesPhrase(event.name, \"CS Digital Document Management Error alerts\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
