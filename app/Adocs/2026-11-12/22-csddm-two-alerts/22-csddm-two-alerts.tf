resource "dynatrace_davis_anomaly_detectors" "alj_claims_api_call_failed" {
  title       = "ALJ_CLAIMS Claims API call failed"
  description = "Optional"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-24h
| filter contains(aws.log.group, "/aws/lambda/cs-digital-document-management-prod-", caseSensitive:false)
| filter contains(message, "claims api call failed", caseSensitive:false) or contains(content, "claims api call failed", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "csddm-claims-api-failed"
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
        value = "ALJ_CLAIMS Claims API call failed"
      }
      property {
        key   = "event.description"
        value = "ALJ_CLAIMS Claims API call failed detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CLAIMS"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_claims_alerting_profile" {
  name = "ALJ_CLAIMS Alerting Profile"

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
          value          = "ALJ_CLAIMS"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_claims_api_call_failed" {
  name    = "ALJ_CLAIMS Claims API call failed Email"
  profile = dynatrace_alerting.alj_claims_alerting_profile.id
  subject = "[Dynatrace] ALJ_CLAIMS Claims API call failed"
  to = [
    "honlun.chan@axa.co.jp",
    "masaya.okuno@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_davis_anomaly_detectors" "alj_csddm_error" {
  title       = "ALJ_CSDDM Document management error"
  description = "Alerts when an error occurs. Github Repo: cs-digital-document-management"
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query.expression"
        value = <<-EOT
fetch logs, from: now()-5m
| filter index == "cs-digital-document-management"
| filter contains(content, "error", caseSensitive:false)
| filter not(contains(message, "error", caseSensitive:false))
| filter not(contains(message, "elivery not possible", caseSensitive:false))
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "csddm-error"
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
        value = "ALJ_CSDDM Document management error"
      }
      property {
        key   = "event.description"
        value = "ALJ_CSDDM Document management error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_CSDDM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_csddm_alerting_profile" {
  name = "ALJ_CSDDM Alerting Profile"

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
          value          = "ALJ_CSDDM"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_csddm_error" {
  name                   = "ALJ_CSDDM Document management error Email"
  profile                = dynatrace_alerting.alj_csddm_alerting_profile.id
  subject                = "[Dynatrace] ALJ_CSDDM Document management error"
  to                     = ["alj_jp_di_csdigitaldocument@axa.co.jp"]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
