resource "dynatrace_davis_anomaly_detectors" "alj_cpa_customer_process_api" {
  title       = "ALJ_CPA Customer Process API alerts"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "customer-process-api"
| filter contains(content, "Task timed out", caseSensitive:false)
    or contains(content, "An error occurred", caseSensitive:false)
    or contains(content, "Failed to handle: lifeJData", caseSensitive:false)
    or contains(content, "Got unexpected investment company code", caseSensitive:false)
    or contains(content, "The policy is ineligible for creating a request", caseSensitive:false)
    or contains(content, "1BL0250002", caseSensitive:false)
    or contains(content, "<StatusCd>EB", caseSensitive:false)
    or contains(content, "imported a total of 0 data", caseSensitive:false)
    or contains(content, "Handler Error: Too many connections", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "customer-process-api"
EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "alert_key"
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
        value = "ALJ_CPA Customer Process API alerts"
      }
      property {
        key   = "event.description"
        value = "ALJ_CPA Customer Process API alerts detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CPA"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_cpa_alerting_profile" {
  name = "ALJ_CPA Alerting Profile"

  rules {
    rule {
      include_mode     = "NONE"
      delay_in_minutes = 0
      severity_level   = "ERROR"
    }
  }

  filters {
    filter {
      custom {
        title {
          enabled        = true
          operator       = "BEGINS_WITH"
          value          = "ALJ_CPA"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_cpa_customer_process_api" {
  name                   = "ALJ_CPA Customer Process API alerts Email"
  profile                = dynatrace_alerting.alj_cpa_alerting_profile.id
  subject                = "[Dynatrace] ALJ_CPA Customer Process API alerts"
  to                     = ["alj_jp_di_adect@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
