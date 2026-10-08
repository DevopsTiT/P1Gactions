# Splunk: CTL-M:ジョブ実行結果通知 (Control-M job result notification)
#   index="controlm_temp" sourcetype=controlm_activejobs NOT (job_name="*-F" OR job_name="*-S") NOT job_name=""
#     AND (status="Ended OK" OR status="Ended not OK")
#   | where relative_time(now(),"-10m") < strptime(end_time,"%Y%m%d%H%M%S")     (ended in the last 10 min)
#   | eval UID=order_id+isn | dedup UID
#   | join type=left order_id [ search sourcetype=controlm_alert earliest=-24h | abend_time, system, RUN_COUNT ]
#   | where message!=""                                                          (only jobs that abended in 24 h)
#   | STARTTIME, ENDTIME, JOB_CODE=job_name+current_time
#   | lookup controlm_addresslist.csv (Method), controlm_job_Definition.csv, controlm_SpecificContact.csv (Email)
#   | TITLE  = <job> (<system>)正常終了 (<run>)[hh:mm:ss]   or  異常終了 (<run>:<対応方法>) [hh:mm:ss]
#   | BODY   = <abend_time>にアベンドした<job>は正常終了しました   or  <job>が<abend_time>に異常終了しました
#   cron */1, Last 5 minutes, results > 0, throttle on JOB_CODE 10 minutes
#   Email To one person, CC $result.Email$ (per-job contact), priority Normal
#
# Dynatrace: one problem per Control-M run (order_id + isn), open for 10 minutes after the job ends.
#   TITLE and BODY are kept as fields so the problem shows the same Japanese text.
#   Per-job CC (SpecificContact Email) cannot be set by a detector; route by app.name or add a workflow.
#
# CONFIRM before apply (check.dql):
#   1. log.source values for controlm_activejobs and controlm_alert (query 1)
#   2. Control-M fields exist as attributes: job_name, status, end_time, order_id, isn, application,
#      message, host_time, data_center, run_counter (query 2)
#   3. /lookups/controlm/addresslist uploaded (job_name, Method)
# Replaces 2026-10-07 seq 14 controlm_alerts["job_result_after_abend"]; remove that key if applied.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "controlm_job_result_notify" {
  title       = "CTL-M:ジョブ実行結果通知"
  description = "A Control-M job that abended in the last 24 hours has ended again (正常終了 or 異常終了) in the last 10 minutes. One problem per run."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-30m
          | filter matchesValue(log.source, "*controlm_activejobs*")
          | filter isNotNull(job_name) and job_name != ""
          | filter not endsWith(job_name, "-F") and not endsWith(job_name, "-S")
          | filter status == "Ended OK" or status == "Ended not OK"
          | fieldsAdd end_ts = toTimestamp(concat(substring(end_time, from:0, to:4), "-", substring(end_time, from:4, to:6), "-", substring(end_time, from:6, to:8), "T",
                                                  substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14), "+09:00"))
          | filter end_ts > now() - 10m
          | fieldsAdd UID = concat(order_id, isn)
          | dedup UID
          | lookup [ fetch logs, from:now()-24h
                     | filter matchesValue(log.source, "*controlm_alert*")
                     | filter isNotNull(message) and message != ""
                     | summarize abend_time = takeLast(host_time), message = takeLast(message),
                                 data_center = takeLast(data_center), run_counter = takeLast(run_counter),
                                 by:{ order_id } ],
                   sourceField:order_id, lookupField:order_id, prefix:"alert."
          | filter isNotNull(alert.message) and alert.message != ""
          | lookup [ load "/lookups/controlm/addresslist" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ Method }
          | fieldsAdd system = if(alert.data_center == "CEAA204D" or alert.data_center == "Server#1", "Open",
                               else: if(alert.data_center == "mainframe#1", "MF#1",
                               else: if(alert.data_center == "mainframe#3", "MF#3", else: "unknown")))
          | fieldsAdd RUN_COUNT = if(application == "NO_APPL", toLong(alert.run_counter) + 1, else: toLong(alert.run_counter))
          | fieldsAdd PrimarySupport = if(application == "NO_APPL", "", else: concat(":", coalesce(Method, "対応方法")))
          | fieldsAdd END_HMS = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fieldsAdd TITLE = if(status == "Ended OK",
                                 concat(job_name, " (", system, ")正常終了 (", toString(RUN_COUNT), ")[", END_HMS, "]"),
                                 else: concat(job_name, " (", system, ")異常終了 (", toString(RUN_COUNT), PrimarySupport, ") [", END_HMS, "]"))
          | fieldsAdd BODY = if(status == "Ended OK",
                                concat(toString(alert.abend_time), "にアベンドした", job_name, "は正常終了しました"),
                                else: concat(job_name, "が", toString(alert.abend_time), "に異常終了しました"))
          | fields UID, job_name, status, application, group_name, owner, odate, end_ts, TITLE, BODY
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "UID"
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
        value = "CTL-M:ジョブ実行結果通知"
      }
      property {
        key   = "event.description"
        value = "アベンドしたControl-Mジョブが再度終了しました（正常終了または異常終了）。TITLE と BODY を確認してください。"
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
