resource "dynatrace_davis_anomaly_detectors" "alj_ccl_aws_batch_timeout" {
  title       = "ALJ_CCL AWS batch time out"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-6m
| filter contains(content, "Task timed out", caseSensitive:false)
| filter not(contains(content, "10DEBUG:", caseSensitive:false))
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "ccl-aws-batch-timeout"
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
        value = "ALJ_CCL AWS batch time out"
      }
      property {
        key   = "event.description"
        value = "ALJ_CCL AWS batch time out detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CCL"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_ccl_alerting_profile" {
  name = "ALJ_CCL Alerting Profile"

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
          value          = "ALJ_CCL"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_ccl_aws_batch_timeout" {
  name                   = "ALJ_CCL AWS batch time out Email"
  profile                = dynatrace_alerting.alj_ccl_alerting_profile.id
  subject                = "[Dynatrace] ALJ_CCL AWS batch time out"
  to                     = ["alj_jp_di_oog_to@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
