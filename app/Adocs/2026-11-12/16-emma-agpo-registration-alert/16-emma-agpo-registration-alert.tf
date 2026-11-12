resource "dynatrace_davis_anomaly_detectors" "alj_emma_agpo_registration_failed" {
  title       = "ALJ_EMMA AGPO registration MDM failed"
  description = "Alert when MyAxa calls MDM or PODs failed."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter contains(content, "CustomerNotFoundException: Customer not found in CIF", caseSensitive:false)
    or contains(content, "InvalidCustomerDataException: Invalid customer data", caseSensitive:false)
    or contains(content, "CustomerDuplicateException: Duplicate customer found", caseSensitive:false)
    or contains(content, "PolicyNotFoundException: Policy not found", caseSensitive:false)
    or contains(content, "CifServiceException:", caseSensitive:false)
    or contains(content, "VonageSmsServiceException: Failed to send SMS", caseSensitive:false)
    or contains(content, "MyPageException during registration", caseSensitive:false)
    or contains(content, "Unexpected exception during AGPortal registration", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 1
| fieldsAdd alert_key = "emma-agpo-registration-mdm"
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
        value = "ALJ_EMMA AGPO registration MDM failed"
      }
      property {
        key   = "event.description"
        value = "ALJ_EMMA AGPO registration MDM failed detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Emma AGPO"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_emma_alerting_profile" {
  name = "ALJ_EMMA Alerting Profile"

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
          value          = "ALJ_EMMA"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_emma_agpo_registration_failed" {
  name    = "ALJ_EMMA AGPO registration MDM failed Email"
  profile = dynatrace_alerting.alj_emma_alerting_profile.id
  subject = "[Dynatrace] ALJ_EMMA AGPO registration MDM failed"
  to = [
    "thuphuong.nguyen@axa.co.jp",
    "regoire.homassel@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
