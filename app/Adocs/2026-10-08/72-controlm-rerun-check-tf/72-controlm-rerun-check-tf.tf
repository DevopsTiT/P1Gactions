# Splunk: CTL-M:リラン確認 (Control-M rerun check)
#   index="controlm_temp" sourcetype=controlm_activejobs NOT (job_name="*-F" OR job_name="*-S")
#   | append [ inputlookup ControlmRerunHistory.csv ]                    (runs already reported: JOB_CODE "Rerun:...")
#   | append [ search sourcetype=controlm_alert earliest=-24h | abend_time=current_time, status=message ]
#   | stats max(JOB_CODE) as RerunFlag, values(status) as status, max(start_time, end_time, avg_start_time,
#           avg_runtime, abend_time, group_name, odate, cmd_line, mem_lib, memname, owner) by order_id
#   | where RerunFlag is not "Rerun:..."                                 (not reported yet)
#   | where status matches "Ended not OK|Ended Not OK"                   (it abended)
#   | search status IN ("Ended OK")                                      (and then ended OK)
#   | JOB_CODE = "Rerun:"+job_name+abend_time
#   | STARTTIME, ENDTIME, ABENDTIME = "%Y/%m/%d %H:%M:%S"; AVGSTARTTIME = "__/__ HH:MM"
#   | AVGENDTIME = start_time + avg_runtime; AVGRUNTIME = avg_runtime as H:M:S
#   | RUNTIME = end_time - start_time; WORKTIME = end_time - abend_time
#   | CMDLINE = cmd_line if not empty, else mem_lib\memname
#   | where isnotnull(JOB_CODE)                                          (abend seen in controlm_alert in 24 h)
#   | table JOB_CODE, group_name, job_name, status, odate, avg_runtime, AVGRUNTIME, RUNTIME, STARTTIME, ENDTIME,
#           AVGSTARTTIME, AVGENDTIME, CMDLINE, owner, WORKTIME, ABENDTIME, end_time, order_id
#   cron */4, Last 8 hours, Expires 24h, results > 0, Once, For each result, no throttle
#   Actions: Output results to lookup ControlmRerunHistory.csv (Append), and Send email (collapsed: recipients
#            and priority not visible)
#
# Dynatrace: one problem per rerun (identity JOB_CODE).
#   The history CSV only stopped Splunk from mailing the same rerun twice. A detector does that by itself:
#   while the run stays in the 8-hour window the problem stays open and does not notify again.
#
# Overlap: controlm_job_result_notify (seq 71) also opens a "正常終了" problem when an abended job ends OK.
#   Splunk sends both mails too. Keep both to match Splunk, or set enabled = false here.
# Earlier: 2026-10-05 seq 30 had a workflow controlm_rerun_check; seq 31/37/38 and 2026-10-07 seq 14 skipped
#   this alert (only the CSV action was visible). If seq 30 was applied, destroy that workflow.
#
# CONFIRM before apply (check.dql):
#   1. Send email priority (High -> severity high); medium assumes Normal
#   2. activejobs has avg_start_time (HHMM), avg_runtime (seconds), cmd_line, mem_lib, memname (query 2)
#   3. controlm_alert has current_time (yyyyMMddHHmmss) and message (query 3)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "controlm_rerun_check" {
  title       = "CTL-M:リラン確認"
  description = "A Control-M job abended and then ended OK after a rerun (within the last 8 hours). One problem per rerun."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-8h
          | filter matchesValue(log.source, "*controlm_activejobs*")
          | filter not endsWith(job_name, "-F") and not endsWith(job_name, "-S")
          | summarize statuses = collectDistinct(status), job_name = max(job_name), start_time = max(start_time), end_time = max(end_time),
                      avg_start_time = max(avg_start_time), avg_runtime = max(avg_runtime), group_name = max(group_name), odate = max(odate),
                      cmd_line = max(cmd_line), mem_lib = max(mem_lib), memname = max(memname), owner = max(owner),
                      by:{ order_id }
          | lookup [ fetch logs, from:now()-24h
                     | filter matchesValue(log.source, "*controlm_alert*")
                     | summarize abend_time = max(current_time), messages = collectDistinct(message), by:{ order_id } ],
                   sourceField:order_id, lookupField:order_id, prefix:"alert."
          | filter isNotNull(alert.abend_time)
          | filter iAny(statuses[] == "Ended not OK" or statuses[] == "Ended Not OK")
                or iAny(contains(alert.messages[], "Ended not OK") or contains(alert.messages[], "Ended Not OK"))
          | filter iAny(statuses[] == "Ended OK")
          | fieldsAdd JOB_CODE = concat("Rerun:", job_name, alert.abend_time)
          | fieldsAdd start_ts = toTimestamp(concat(substring(start_time, from:0, to:4), "-", substring(start_time, from:4, to:6), "-", substring(start_time, from:6, to:8), "T",
                                                    substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14), "+09:00")),
                      end_ts = toTimestamp(concat(substring(end_time, from:0, to:4), "-", substring(end_time, from:4, to:6), "-", substring(end_time, from:6, to:8), "T",
                                                  substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14), "+09:00")),
                      abend_ts = toTimestamp(concat(substring(alert.abend_time, from:0, to:4), "-", substring(alert.abend_time, from:4, to:6), "-", substring(alert.abend_time, from:6, to:8), "T",
                                                    substring(alert.abend_time, from:8, to:10), ":", substring(alert.abend_time, from:10, to:12), ":", substring(alert.abend_time, from:12, to:14), "+09:00"))
          | fieldsAdd STARTTIME = formatTimestamp(start_ts, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo"),
                      ENDTIME = formatTimestamp(end_ts, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo"),
                      ABENDTIME = formatTimestamp(abend_ts, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo"),
                      AVGSTARTTIME = concat("__/__ ", substring(avg_start_time, from:0, to:2), ":", substring(avg_start_time, from:2, to:4)),
                      AVGENDTIME = formatTimestamp(start_ts + toLong(avg_runtime) * 1s, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo"),
                      AVGRUNTIME = toLong(avg_runtime) * 1s,
                      RUNTIME = end_ts - start_ts,
                      WORKTIME = end_ts - abend_ts,
                      CMDLINE = if(isNotNull(cmd_line) and cmd_line != "", cmd_line, else: concat(mem_lib, "\\", memname))
          | fields JOB_CODE, order_id, group_name, job_name, statuses, odate, STARTTIME, ENDTIME, ABENDTIME,
                   AVGSTARTTIME, AVGENDTIME, AVGRUNTIME, RUNTIME, WORKTIME, CMDLINE, owner
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "JOB_CODE"
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
        value = "CTL-M:リラン確認"
      }
      property {
        key   = "event.description"
        value = "アベンドしたControl-Mジョブがリランで正常終了しました。JOB_CODE, ABENDTIME, STARTTIME, ENDTIME, RUNTIME, WORKTIME, CMDLINE を確認してください。"
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Control-M"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
