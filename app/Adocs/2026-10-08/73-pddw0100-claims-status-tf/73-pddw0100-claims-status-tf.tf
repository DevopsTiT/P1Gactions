# Splunk: Claims Status Service PDDW0100 Status
#   index=controlm_temp sourcetype=controlm_activejobs NOT job_name=*-S NOT job_name=*-F NOT job_name=TEST001 (job_name="PDDW*")
#   | eventstats max(current_time) as max_time by odate,order_id
#   | where current_time = max_time and status="Ended OK"                (latest snapshot of each run, ended OK)
#   | dedup _raw
#   | lookup controlm_avg_run_info_lookup.csv job_name
#   | lookup claims_job_list.csv job_id as job_name output exec_time, exec_no, app_name, processing, job_name_jp
#   | 起動日 = yyyy/MM/dd, StartTime / EndTime = HH:MM:SS
#   | rename job_name as JOB, job_name_jp as 処理 | table JOB, 起動日, StartTime, EndTime | sort start_time desc
#   cron 15 8 * * *, Last 24 hours, Expires 1h, results > 0, Once, For each result, no throttle
#   Action: Send email, Priority Highest, inline table (recipients not copied)
#   Message: "担当各位 PDDWの完了時刻のレポートを送信致します。" then a note for runs that have not finished
#
# Splunk mails a completion-time report every morning. The report is information; the action item is
# "a PDDW run has not ended OK yet". Dynatrace: one problem per PDDW run (odate + order_id) whose latest
# snapshot is not Ended OK, judged from 08:15 JST (the Splunk send time) until midnight.
#   Closes when the run's latest snapshot becomes Ended OK, or when it leaves the 24-hour window.
#
# Replaces 2026-10-07 seq 14 controlm_alerts["pddw_no_success"] (only fired when no PDDW job at all ended OK);
#   remove that key if applied. Replaces the 2026-10-05 seq 31 daily report pddw0100_claims_status.
#
# CONFIRM before apply (check.dql):
#   1. log.source for controlm_activejobs; current_time exists on each snapshot (query 1, 2)
#   2. /lookups/controlm/claims_job_list uploaded with job_id, exec_time, exec_no, app_name, processing, job_name_jp (query 3)
#   3. PDDW runs that normally finish after 08:15 (query 4). If any, exclude them using exec_time.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "pddw0100_claims_status" {
  title       = "Claims Status Service PDDW0100 Status"
  description = "A PDDW claims Control-M run has not ended OK by 08:15 JST (latest snapshot of the run in the last 24 hours). One problem per run."
  enabled     = true
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
        value = "Claims Status Service PDDW0100 Status 未完了"
      }
      property {
        key   = "event.description"
        value = "担当各位　PDDWジョブが08:15時点で正常終了していません。JOB, 処理, status, 起動日, StartTime, EndTime を確認してください。"
      }
      property {
        key   = "alert.severity"
        value = "high"
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
