# OPTIONAL - recommendation: do NOT migrate separately. Seq 70 (CHDE010MJob Status for MyAXA UL Email) covers it.
#
# Splunk: Job Status for MyAXA UL Email
#   index=controlm_temp sourcetype=controlm_activejobs job_name=CHDE010M
#   | dedup job_name                                  (latest CHDE010M record in the last day, any order date)
#   | StartTime / EndTime = MM/dd HH:mm:ss
#   | MSG = "" if status="Ended OK", else "正常終了していません要確認"
#   | table job_name status StartTime EndTime MSG
#   cron 30 11 * * 2-6, Last 1 day, Expires 24h, results > 0, Once, For each result, no throttle
#   Action: Send email, Priority Normal, subject "$name$ $result.MSG$",
#           message "The job status of CHDE010M / JOB NAME / JOB STATUS / JOB START ..." (recipients not copied)
#
# Compared with seq 70:
#   Same job, same mail list, same 11:30 send time, same Normal priority.
#   Days 2-6 (Tue-Sat) are inside seq 70's 1-6 (Mon-Sat).
#   No order-date filter: it looks at the latest record of the last day. Seq 70 looks at yesterday's order date,
#   which is stricter and does not flag a run that belongs to today.
#   So every real failure this alert would mail is already a seq 70 problem.
#
# If a separate detector is still wanted: latest CHDE010M record in the last day is not Ended OK,
# Tue-Sat from 11:30 JST. Disabled by default, own resource name, no conflict with seq 70.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "chde010m_job_status_myaxa_ul_latest" {
  title       = "Job Status for MyAXA UL Email"
  description = "Latest Control-M CHDE010M (MyAXA UL) record in the last day is not Ended OK. Checked Tue-Sat from 11:30 JST. Disabled: seq 70 covers it."
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
          | filter formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo") >= "1130"
          | filter getDayOfWeek(now() + 9h) >= 2 and getDayOfWeek(now() + 9h) <= 6
          | sort timestamp asc
          | summarize status = takeLast(status), start_time = takeLast(start_time), end_time = takeLast(end_time),
                      odate = takeLast(odate), last_seen = max(timestamp), by:{ job_name }
          | filter status != "Ended OK"
          | fieldsAdd StartTime = concat(substring(start_time, from:4, to:6), "/", substring(start_time, from:6, to:8), " ",
                                         substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14))
          | fieldsAdd EndTime = concat(substring(end_time, from:4, to:6), "/", substring(end_time, from:6, to:8), " ",
                                       substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fieldsAdd MSG = "正常終了していません要確認"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_name"
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
        value = "Job Status for MyAXA UL Email 正常終了していません要確認"
      }
      property {
        key   = "event.description"
        value = "The job status of CHDE010M is not Ended OK. See job_name, status, StartTime and EndTime on the problem."
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
