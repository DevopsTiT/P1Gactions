# recruitimp-serverless-prod: 2 alerts converted from dynatrace_log_alert
# Alert 1 (daily 08:00 digest)  → scheduled workflow
# Alert 2 (every 5 min)         → detector + email workflow

locals {
  # Confirm the real name: alert 1 in the original file says "recrutimp" (no i), alert 2 says "recruitimp".
  recruitimp_log_group = "/aws/lambda/recruitimp-serverless-prod"

  # Works for Node.js ("ts<TAB>requestId<TAB>ERROR<TAB>msg") and Python ("[ERROR]<TAB>ts...") Lambda lines.
  recruitimp_error_filter = <<-EOT
    | filter aws.log_group == "${local.recruitimp_log_group}"
    | filter status == "ERROR" or contains(content, "\tERROR\t") or contains(content, "[ERROR]")
  EOT

  recruitimp_ri_filter = <<-EOT
    | filter aws.log_group == "${local.recruitimp_log_group}"
    | parse content, "NSPACE:session_id SPACE WORD:level SPACE NSPACE:user_id"
    | filter level == "ERROR"
  EOT
}

# Alert 1: daily digest of yesterday's errors
resource "dynatrace_automation_workflow" "recruitimp_aws_serverless_error_daily" {
  title       = "Prod_Life_RecruitImp_AWSServerlessError_Daily"
  description = "Every day at 08:00 JST, email the ERROR lines from recruitimp-serverless-prod in the last 24 hours."

  tasks {
    task {
      name        = "count_errors"
      description = "ERROR lines in the last 24 hours"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          ${local.recruitimp_error_filter}
          | summarize total = count()
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "list_errors"
      description = "Latest 100 ERROR lines"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          ${local.recruitimp_error_filter}
          | fields timestamp, content
          | sort timestamp desc
          | limit 100
        EOT
      })
      conditions {
        states = {
          count_errors = "OK"
        }
        custom = "{{ result(\"count_errors\").records[0].total > 0 }}"
        else   = "SKIP"
      }
      position {
        x = 0
        y = 2
      }
    }
    task {
      name        = "send_email"
      description = "Email the eTool maintenance team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to = [
          "alj_jp_dl_etool_maintenance@axa.co.jp",
          "chungyueh.chiu@axa.co.jp",
        ]
        cc      = []
        bcc     = []
        subject = "Alert: Prod_Life_RecruitImp_AWSServerlessError_Daily ({{ result(\"count_errors\").records[0].total }} errors)"
        content = "recruitimp-serverless-prod logged {{ result(\"count_errors\").records[0].total }} ERROR lines in the last 24 hours. Latest 100:\n\n{% for r in result(\"list_errors\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          list_errors = "OK"
        }
      }
      position {
        x = 0
        y = 3
      }
    }
  }

  trigger {
    schedule {
      active    = true
      time_zone = "Asia/Tokyo"
      trigger {
        cron = "0 8 * * *"
      }
    }
  }
}

# Alert 2: RI Monitoring Error
resource "dynatrace_davis_anomaly_detectors" "recruitimp_ri_monitoring_error" {
  title       = "Prod_Life_RecruitImp_RIMonitoringError_Normal"
  description = "RI monitoring logged a line with level ERROR in recruitimp-serverless-prod."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          ${local.recruitimp_ri_filter}
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
        value = "Prod_Life_RecruitImp_RIMonitoringError_Normal"
      }
      property {
        key   = "event.description"
        value = "RI monitoring logged level ERROR in /aws/lambda/recruitimp-serverless-prod."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "recruitimp_ri_monitoring_error_email" {
  title       = "Prod_Life_RecruitImp_RIMonitoringError_Normal - email"
  description = "When the RI monitoring problem opens, email the recent error lines."

  tasks {
    task {
      name        = "recent_errors"
      description = "RI ERROR lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          ${local.recruitimp_ri_filter}
          | fields timestamp, session_id, user_id, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the eTool maintenance team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["alj_jp_dl_etool_maintenance@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Alert: {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }} opened.\n\n{% for r in result(\"recent_errors\").records %}{{ r.timestamp }}  session={{ r.session_id }}  user={{ r.user_id }}  {{ r.content }}\n{% endfor %}"
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
          custom_filter = "matchesPhrase(event.name, \"Prod_Life_RecruitImp_RIMonitoringError_Normal\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
