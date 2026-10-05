# ============================================================
# ALERT 1: Customer Process API Success Request Monitoring
# Not a failure: an every-5-minutes notice of successful (201) requests.
# A scheduled workflow sends the email, so no Davis problem (and no SILVA/PagerDuty) is created.
# ============================================================

resource "dynatrace_automation_workflow" "customer_process_api_success_monitoring" {
  title       = "Customer Process API Success Request Monitoring"
  description = "To immediately understand the actual production contract requested and confirm operations."

  tasks {
    task {
      name        = "find_success"
      description = "201 responses from customer-process-api-prod in the last 5 minutes (shifted 1 minute for ingest delay)"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-6m, to:now()-1m
          | filter aws.log_group == "/aws/lambda/customer-process-api-prod"
          | filter contains(content, "\"statusCode\":201")
          | fields timestamp, aws.log_group, content
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
      description = "Email the team when there were successful requests"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "iori.baba@axa.co.jp",
          "ryo.masuda@axa.co.jp",
          "naoki.takuda@axa.co.jp",
          "akito.matsumoto.ose@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "!!PROD!! Alert: Customer Process API Success Request Monitoring"
        content = "{{ result(\"find_success\").records | length }} successful request(s) in the last 5 minutes.\n\n{% for r in result(\"find_success\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          find_success = "SUCCESS"
        }
        custom = "{{ result(\"find_success\").records | length > 0 }}"
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
        cron = "*/5 * * * *"
      }
    }
  }
}

# ============================================================
# ALERT 2: Customer Process API Alerts
# Any of 9 known failure messages in the last 5 minutes
# ============================================================

resource "dynatrace_davis_anomaly_detectors" "customer_process_api_alerts" {
  title       = "Customer Process API Alerts"
  description = "Known failure messages from Lambda customer-process-api-prod (timeouts, unhandled errors, ineligible policy, IBL0250002, too many connections)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter aws.log_group == "/aws/lambda/customer-process-api-prod"
          | fieldsAdd c = lower(content)
          | filter contains(c, "task timed out")
              or contains(c, "an error occurred")
              or contains(c, "failed to handle: lifejdata")
              or contains(c, "got unexpected investment company code")
              or contains(c, "the policy is ineligible for creating a request")
              or contains(c, "ibl0250002")
              or contains(c, "<statuscd>eb")
              or contains(c, "imported a total of 0 data")
              or contains(c, "handler error: too many connections")
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
        value = "Customer Process API Alerts"
      }
      property {
        key   = "event.description"
        value = "Known failure message logged by /aws/lambda/customer-process-api-prod."
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "customer_process_api_alerts_email" {
  title       = "Customer Process API Alerts - email"
  description = "Emails the ADEPT team when the Customer Process API Alerts problem opens."

  tasks {
    task {
      name        = "send_email"
      description = "Email the team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["aij_jp_dl_adept@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "!!PROD!! Alert: Customer Process API Alerts"
        content = "Problem {{ event()[\"display_id\"] }} opened: {{ event()[\"event.name\"] }}\nLog group: /aws/lambda/customer-process-api-prod"
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
          custom_filter = "matchesPhrase(event.name, \"Customer Process API Alerts\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
