resource "dynatrace_davis_anomaly_detectors" "alj_sabatch_error" {
  title       = "ALJ_SABATCH batch error"
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
| filter index == "sa-support-batches"
| filter contains(content, "error", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "sa-support-batch-error"
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
        value = "ALJ_SABATCH batch error"
      }
      property {
        key   = "event.description"
        value = "ALJ_SABATCH batch error detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_SABATCH"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_annuity_file_import" {
  title       = "ALJ_ANNUITY file import confirmation"
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
| filter index == "sa-support-batches"
| filter contains(content, "importFileHandler :: runner :", caseSensitive:false) or contains(content, "importSagaFundGroup", caseSensitive:false) or contains(content, "started", caseSensitive:false)
| summarize seen = count()
| filter seen < 2
| fieldsAdd alert_key = "sa-support-batch-file-import"
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
        value = "ALJ_ANNUITY file import confirmation"
      }
      property {
        key   = "event.description"
        value = "ALJ_ANNUITY file import confirmation detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_ANNUITY"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_davis_anomaly_detectors" "alj_sabatch_task_timeout" {
  title       = "ALJ_SABATCH task timeout"
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
| filter index == "sa-support-batches"
| filter contains(content, "Task timed out", caseSensitive:false)
| summarize failed_count = count()
| filter failed_count > 0
| fieldsAdd alert_key = "sa-support-batch-timeout"
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
        value = "ALJ_SABATCH task timeout"
      }
      property {
        key   = "event.description"
        value = "ALJ_SABATCH task timeout detected"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "ALJ_SABATCH"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_alerting" "alj_sabatch_alerting_profile" {
  name = "ALJ_SABATCH Alerting Profile"

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
          value          = "ALJ_SABATCH"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_alerting" "alj_annuity_alerting_profile" {
  name = "ALJ_ANNUITY Alerting Profile"

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
          value          = "ALJ_ANNUITY"
          case_sensitive = false
          negate         = false
        }
      }
    }
  }
}

resource "dynatrace_email_notification" "alj_sabatch" {
  name    = "ALJ_SABATCH Email"
  profile = dynatrace_alerting.alj_sabatch_alerting_profile.id
  subject = "[Dynatrace] ALJ_SABATCH SA support batch alert"
  to = [
    "alj_jp_di_bap_commonins@ound2@axa.co.jp",
    "maki.kawauchi.ose@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}

resource "dynatrace_email_notification" "alj_annuity" {
  name    = "ALJ_ANNUITY Email"
  profile = dynatrace_alerting.alj_annuity_alerting_profile.id
  subject = "[Dynatrace] ALJ_ANNUITY file import alert"
  to = [
    "axa.jp_di_bap_annuitypayments@axa.co.jp",
  ]
  notify_closed_problems = true
  body                   = "Alert detected: {ProblemDetailsHTML}"
}
