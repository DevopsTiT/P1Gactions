# Replaces Splunk alert "Datalake_Batch Result"
#   index="batch_monitoring_logs" | table _time _raw
#   Time range: Today (midnight to now)   Cron: 0 8 * * *   Fires when results > 0   Email, Normal
# This is a daily report (a table of lines), so it is a scheduled workflow, not a detector.

resource "dynatrace_automation_workflow" "datalake_batch_result" {
  title       = "Prod_Datalake_BatchResult_Normal"
  description = "Daily 08:00 JST: email every batch_monitoring_logs line written since midnight JST."

  tasks {
    task {
      name        = "get_batch_lines"
      description = "Batch monitoring lines since midnight JST"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        # Runs at 08:00 JST, so now()-8h is midnight JST (same as Splunk "Today")
        # CONFIRM line 3: Splunk index="batch_monitoring_logs" → real Dynatrace field (check.dql query 1)
        query = <<-EOT
          fetch logs, from:now()-8h
          | filter matchesValue(log.source, "*batch_monitoring*")
          | sort timestamp asc
          | fields timestamp, content
          | limit 500
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the batch result list"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        # CONFIRM the address spelling from the Splunk screenshot
        to      = ["masayuki.yasuda@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Prod_Datalake_BatchResult_Normal: {{ result(\"get_batch_lines\").records | length }} lines since midnight"
        content = "Datalake batch monitoring lines since 00:00 JST:\n\n{% for r in result(\"get_batch_lines\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          get_batch_lines = "OK"
        }
        custom = "{{ result(\"get_batch_lines\").records | length > 0 }}"
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
        cron = "0 8 * * *"
      }
    }
  }
}
