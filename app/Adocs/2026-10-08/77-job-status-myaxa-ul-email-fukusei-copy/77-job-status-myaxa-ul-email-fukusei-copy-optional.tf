# OPTIONAL - recommendation: do NOT migrate. This is a personal copy of seq 70 (CHDE010MJob Status for MyAXA UL Email).
#
# Splunk: Job Status for MyAXA UL Email複製
#   Search is the same as seq 70:
#   index=controlm_temp sourcetype=controlm_activejobs job_name=CHDE010M
#   | dedup odate | StartTime / EndTime = MM/dd HH:mm:ss
#   | MSG = "OK" if status="Ended OK", else "正常終了していません要確認"
#   | WKday = yesterday (yyyyMMdd), OrderDate = odate (yyMMdd -> yyyyMMdd) | where OrderDate = WKday
#   | table job_name, status, StartTime, EndTime, OrderDate, MSG
#   cron 25 11 * * 1-6 (seq 70: 30 11), Last 1 day, Expires 24h, results > 0, Once, For each result, no throttle
#   Action: Send email to ONE person (not copied), Priority Normal, subject "$result.MSG$ $name$" (order swapped)
#   Message: same run-day explanation as seq 70. Inline table, Allow Empty Attachment.
#
# Why not migrate: same data, same logic, same days. It only runs 5 minutes earlier and mails one person.
# That person can be added to the seq 70 notification route instead.
#
# If a separate copy is still wanted: disabled, own resource name, low, gate 11:25 JST to match the copy's cron.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "chde010m_myaxa_ul_job_status_copy" {
  title       = "Job Status for MyAXA UL Email複製"
  description = "Copy of seq 70. Control-M job CHDE010M (MyAXA UL) for yesterday's order date has not Ended OK. Checked Mon-Sat from 11:25 JST. Disabled: seq 70 covers it."
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1d
          | filter matchesValue(log.source, "*controlm_activejobs*")
          | filter job_name == "CHDE010M"
          | filter odate == formatTimestamp(now() - 1d, format:"yyMMdd", timezone:"Asia/Tokyo")
          | filter formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo") >= "1125"
          | filter getDayOfWeek(now() + 9h) <= 6
          | sort timestamp asc
          | summarize status = takeLast(status), start_time = takeLast(start_time), end_time = takeLast(end_time),
                      last_seen = max(timestamp), by:{ job_name, odate }
          | filter status != "Ended OK"
          | fieldsAdd StartTime = concat(substring(start_time, from:4, to:6), "/", substring(start_time, from:6, to:8), " ",
                                         substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14))
          | fieldsAdd EndTime = concat(substring(end_time, from:4, to:6), "/", substring(end_time, from:6, to:8), " ",
                                       substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fieldsAdd OrderDate = concat("20", odate)
          | fieldsAdd MSG = "正常終了していません要確認"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_name"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "odate"
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
        value = "正常終了していません要確認 Job Status for MyAXA UL Email複製"
      }
      property {
        key   = "event.description"
        value = "CHDE010M（MyAXA UL）の前日オーダー分が正常終了していません。status, StartTime, EndTime, OrderDate を確認してください。seq 70 のコピーです。"
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "MyAXA UL"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
