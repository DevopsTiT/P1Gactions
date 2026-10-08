# OPTIONAL - recommendation: do NOT migrate.
#
# Splunk: Claims Status Service PDDW0100 Status_test
#   Search, schedule (15 8 * * *, Last 24 hours, Expires 1h) and message are identical to
#   "Claims Status Service PDDW0100 Status" (2026-10-08 seq 73).
#   Action: Send email to one person only, Priority Highest (recipient not copied).
#   It is a personal test copy: the production alert already covers the same runs.
#
# If a test detector is still wanted (for example to try the query before seq 73 goes live),
# this is the seq 73 detector with its own resource name, disabled, severity low, no PagerDuty.
# Different resource name from seq 73, so both can live in the same state without conflict.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "pddw0100_claims_status_test" {
  title       = "Claims Status Service PDDW0100 Status_test"
  description = "TEST copy of PDDW0100 Status: a PDDW claims run has not ended OK by 08:15 JST. Disabled by default."
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter matchesValue(log.source, "*controlm_activejobs*")
          | filter startsWith(job_name, "PDDW")
          | filter not endsWith(job_name, "-S") and not endsWith(job_name, "-F") and job_name != "TEST001"
          | filter formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo") >= "0815"
          | sort current_time asc
          | summarize status = takeLast(status), job_name = takeLast(job_name), start_time = takeLast(start_time),
                      end_time = takeLast(end_time), last_seen = max(timestamp), by:{ odate, order_id }
          | filter status != "Ended OK"
          | lookup [ load "/lookups/controlm/claims_job_list" ], sourceField:job_name, lookupField:job_id, prefix:"cjl.",
                   fields:{ exec_time, exec_no, app_name, processing, job_name_jp }
          | fieldsAdd JOB = job_name, 処理 = cjl.job_name_jp,
                      起動日 = concat(substring(start_time, from:0, to:4), "/", substring(start_time, from:4, to:6), "/", substring(start_time, from:6, to:8)),
                      StartTime = concat(substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14)),
                      EndTime = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fields odate, order_id, JOB, 処理, status, 起動日, StartTime, EndTime, cjl.exec_time, cjl.app_name, cjl.processing, last_seen
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "odate"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "order_id"
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
        value = "Claims Status Service PDDW0100 Status_test 未完了"
      }
      property {
        key   = "event.description"
        value = "【TEST】PDDWジョブが08:15時点で正常終了していません。JOB, 処理, status, 起動日, StartTime, EndTime を確認してください。"
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "Claims PDDW"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
