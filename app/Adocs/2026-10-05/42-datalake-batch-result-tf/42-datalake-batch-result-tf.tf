# Replaces Splunk alert "Datalake_Batch Result"
#   index="batch_monitoring_logs" | table _time _raw
#   Time range: Today (midnight to now)   Cron: 0 8 * * *   Fires when results > 0   Email, Normal
#   To: masayuki.yasuda@axa.co.jp   Subject: Splunk Alert: $name$
#
# This is a daily report (a table of lines), not an incident, so it is a scheduled workflow, not a detector.
# Same logic as seq 29, plus: standalone provider block, timestamps shown in JST.
#
# CONFIRM before apply:
#   1. Splunk index="batch_monitoring_logs" → real Dynatrace field (check.dql query 1)
#   2. Recipient is still correct (one named person)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}

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
        # Runs at 08:00 JST, so now()-8h is midnight JST (same as Splunk "Today").
        # Do not use @d: it aligns to midnight UTC (09:00 JST).
        query = <<-EOT
          fetch logs, from:now()-8h
          | filter matchesValue(log.source, "*batch_monitoring*")
          | sort timestamp asc
          | fieldsAdd time_jst = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss", timezone:"Asia/Tokyo")
          | fields time_jst, content
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
        to      = ["masayuki.yasuda@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Prod_Datalake_BatchResult_Normal: {{ result(\"get_batch_lines\").records | length }} lines since midnight"
        content = "Datalake batch monitoring lines since 00:00 JST (max 500):\n\n{% for r in result(\"get_batch_lines\").records %}{{ r.time_jst }}  {{ r.content }}\n{% endfor %}"
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
