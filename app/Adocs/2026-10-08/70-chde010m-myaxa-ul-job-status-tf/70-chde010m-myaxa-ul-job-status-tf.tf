# Splunk: CHDE010MJob Status for MyAXA UL Email
#   index=controlm_temp sourcetype=controlm_activejobs job_name=CHDE010M
#   | dedup odate                                     (latest record per order date)
#   | StartTime / EndTime = MM/dd HH:mm:ss from start_time / end_time (yyyyMMddHHmmss)
#   | MSG = "OK" if status="Ended OK", else "正常終了していません要確認"
#   | where OrderDate (odate, yyMMdd -> yyyyMMdd) = yesterday
#   | table job_name, status, StartTime, EndTime, OrderDate, MSG
#   cron 30 11 * * 1-6, Last 1 day, Expires 24h, results > 0, Once, For each result, no throttle
#   Action: Send email, Priority Normal, subject "$name$ $result.MSG$" (recipients not copied)
#   Message: data is actually created weekly on the day after the first business day of the week (11:00),
#            and monthly on the day after the first business day of the month.
#
# Splunk mails a status report every time yesterday's order exists, OK or not.
# Dynatrace: one problem only when the run is NOT Ended OK (the "要確認" case).
#   The OK mail is information only and has no detector equivalent.
#   Time gate: judged only Mon-Sat from 11:30 JST, like the Splunk cron, because the job finishes by 11:00.
#   The problem closes at midnight JST when "yesterday" moves on, or earlier if a rerun ends OK.
#
# Replaces 2026-10-07 seq 14 controlm_alerts["chde010m_no_success"] for this alert; remove that key if applied.
# Fixes 2026-10-05 seq 30/31: odate is yyMMdd (Splunk strptime "%y%m%d"), not yyyyMMdd.
#
# CONFIRM before apply (check.dql):
#   1. log.source value for controlm_activejobs (query 1)
#   2. odate is 6 digits and start_time / end_time are 14 digits on CHDE010M rows (query 2)
#   3. Dry run without the time gate shows the expected rows (query 3)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "chde010m_myaxa_ul_job_status" {
  title       = "CHDE010MJob Status for MyAXA UL Email"
  description = "Control-M job CHDE010M (MyAXA UL) for yesterday's order date has not Ended OK. Checked Mon-Sat from 11:30 JST."
  enabled     = true
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
          | filter formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo") >= "1130"
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
        value = "CHDE010MJob Status for MyAXA UL Email 正常終了していません要確認"
      }
      property {
        key   = "event.description"
        value = "CHDE010M（MyAXA UL）の前日オーダー分が正常終了していません。status, StartTime, EndTime, OrderDate を確認してください。実際にデータが作られる日: 週次は週の第1営業日の翌日 11:00、月次は月の第1営業日の翌日。"
      }
      property {
        key   = "alert.severity"
        value = "medium"
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
