resource "dynatrace_davis_anomaly_detectors" "alj_glue_compass_sales_skip" {
  title       = "ALJ_GLUE Compass sales skip発生"
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
| filter contains(aws.log.group, "/aws-glue/jobs/custom/compass-sales-performance/error", caseSensitive:false)
| filter contains(message, "skipping table", caseSensitive:false) or contains(content, "skipping table", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "compass-glue-skip"
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
        value = "ALJ_GLUE Compass sales skip発生"
      }
      property {
        key   = "event.description"
        value = "ALJ_GLUE Compass sales skip発生 detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_GLUE"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_glue_alerting_profile" {
  name = "ALJ_GLUE Alerting Profile"

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
          value          = "ALJ_GLUE"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_glue_compass_sales_skip" {
  name    = "ALJ_GLUE Compass sales skip発生 Email"
  profile = dynatrace_alerting.alj_glue_alerting_profile.id
  subject = "[Dynatrace] ALJ_GLUE Compass sales skip発生"
  to = [
    "yuta.inoue@axa.co.jp",
    "shihao.he@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
