# Splunk: "OUD restart failed"
#   index=ods sourcetype=oud_service failed
#   cron 1 4 * * * (daily 04:01), last 24 hours, results > 0, once, no throttle
#   Triggered alert High, PagerDuty, Send email
# Dynatrace: detector (alerts within minutes, any time of day) + email workflow.
# PagerDuty and SILVA come from the standard problem workflow (preview then post).

resource "dynatrace_davis_anomaly_detectors" "oud_restart_failed" {
  title       = "Prod_OUD_RestartFailed_High"
  description = "The OUD (Oracle Unified Directory) service restart logged 'failed'. Directory lookups and logins that depend on OUD may fail."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        # Replace the log.source filter with what check.dql query 1 shows for sourcetype=oud_service
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*oud_service*")
          | filter matchesPhrase(content, "failed")
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
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
        value = "Prod_OUD_RestartFailed_High"
      }
      property {
        key   = "event.description"
        value = "OUD service restart failed on {dims:dt.entity.host}. Check the oud_service log on that host."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      # Puts the problem on the OUD host so its AGO tags reach the standard SILVA + PagerDuty workflow
      property {
        key   = "dt.source_entity"
        value = "{dims:dt.entity.host}"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "oud_restart_failed_email" {
  title       = "Prod_OUD_RestartFailed_High - email"
  description = "Emails the OUD owners with the failed restart lines. Paging is done by the standard SILVA and PagerDuty workflow."

  tasks {
    task {
      name        = "failed_lines"
      description = "OUD 'failed' lines from the last 30 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-30m
          | filter matchesValue(log.source, "*oud_service*")
          | filter matchesPhrase(content, "failed")
          | fields timestamp, host.name, log.source, content
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
      description = "Email the OUD owners"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["<oud-team-dl>@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "[HIGH] OUD restart failed"
        content = "Problem {{ event()[\"display_id\"] }}: the OUD service restart logged 'failed'.\n\n{% for r in result(\"failed_lines\").records %}{{ r.timestamp }}  {{ r[\"host.name\"] }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          failed_lines = "OK"
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
          custom_filter = "matchesPhrase(event.name, \"Prod_OUD_RestartFailed_High\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
