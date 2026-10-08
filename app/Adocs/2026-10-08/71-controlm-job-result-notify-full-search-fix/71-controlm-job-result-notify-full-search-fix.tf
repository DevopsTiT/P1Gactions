# Splunk: CTL-M:ジョブ実行結果通知 (Control-M job result notification)
#   index="controlm_temp" sourcetype=controlm_activejobs NOT (job_name="*-F" OR job_name="*-S") NOT job_name=""
#     AND (status="Ended OK" OR status="Ended not OK")
#   | where relative_time(now(),"-10m") < strptime(end_time,"%Y%m%d%H%M%S")     (ended in the last 10 min)
#   | eval UID=order_id+isn | DEDUP UID
#   | join type=left order_id [ search sourcetype=controlm_alert earliest=-24h
#       | eval abend_time=host_time
#       | system = CEAA204D/Server#1 -> Open, mainframe#1 -> MF#1, mainframe#3 -> MF#3, else unknown
#       | RUN_COUNT = run_counter+1 if application="NO_APPL", else run_counter ]
#   | where message!=""                                                          (only jobs that abended in 24 h)
#   | STARTTIME / ENDTIME = "%Y/%m/%d %H:%M:%S", JOB_CODE = job_name+current_time
#   | lookup controlm_addresslist.csv JobID as job_name OUTPUT Method
#   | lookup controlm_job_Definition.csv job_name OUTPUT mem_lib, cmd_line, memname, node_id, host
#   | lookup controlm_SpecificContact.csv job_name OUTPUT Email
#   | CMD_STRING = cmd_line if mem_lib is null, else mem_lib + "\" + memname
#   | PrimarySupport = "" if application="NO_APPL", else ":" + (対応方法, or "N/A" when empty)
#   | TITLE = <job> (<system>)正常終了 (<RUN_COUNT>)[HH:MM:SS]
#           or <job> (<system>)異常終了 (<RUN_COUNT><PrimarySupport>) [HH:MM:SS]
#   | BODY  = <abend_time>にアベンドした<job>は正常終了しました  or  <job>が<abend_time>に異常終了しました
#   | table *
#   cron */1, Last 5 minutes, Expires 24h, results > 0, Once, For each result,
#   throttle on $result.JOB_CODE$ for 10 minutes
#   Action: Send email To one person, CC $result.Email$ (per-job contact), priority Normal (recipients not copied)
#
# Seq 71 corrects seq 13 (same resource name -> in-place update; apply from seq 71 only):
#   1. addresslist lookup key is JobID (seq 13 used job_name)
#   2. PrimarySupport falls back to "N/A" (seq 13 used the literal text "対応方法")
#   3. job_Definition lookup added: CMD_STRING, node_id, def.host shown on the problem
#   4. SpecificContact Email shown on the problem (a detector cannot CC it; a workflow can read it)
#
# Dynatrace: one problem per Control-M run (order_id + isn), open for 10 minutes after the job ends.
#   The 10-minute JOB_CODE throttle is covered by the per-run identity.
#
# CONFIRM before apply (check.dql):
#   1. log.source values for controlm_activejobs and controlm_alert (query 1)
#   2. Lookups uploaded to Grail with these columns (query 5):
#        /lookups/controlm/addresslist      JobID, Method
#        /lookups/controlm/job_definition   job_name, mem_lib, cmd_line, memname, node_id, host
#        /lookups/controlm/specific_contact job_name, Email
#   3. The search uses the field 対応方法 but the addresslist OUTPUT is Method. Mapped 対応方法 = Method.
#      If Splunk has an alias or another lookup for 対応方法, change addr.Method below.

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
          | lookup [ load "/lookups/controlm/addresslist" ], sourceField:job_name, lookupField:JobID, prefix:"addr.", fields:{ Method }
          | lookup [ load "/lookups/controlm/job_definition" ], sourceField:job_name, lookupField:job_name, prefix:"def.", fields:{ mem_lib, cmd_line, memname, node_id, host }
          | lookup [ load "/lookups/controlm/specific_contact" ], sourceField:job_name, lookupField:job_name, prefix:"contact.", fields:{ Email }
          | fieldsAdd system = if(alert.data_center == "CEAA204D" or alert.data_center == "Server#1", "Open",
                               else: if(alert.data_center == "mainframe#1", "MF#1",
                               else: if(alert.data_center == "mainframe#3", "MF#3", else: "unknown")))
          | fieldsAdd RUN_COUNT = if(application == "NO_APPL", toLong(alert.run_counter) + 1, else: toLong(alert.run_counter))
          | fieldsAdd CMD_STRING = if(isNull(def.mem_lib), def.cmd_line, else: concat(def.mem_lib, "\\", def.memname))
          | fieldsAdd taiou = if(isNull(addr.Method) or addr.Method == "", "N/A", else: addr.Method)
          | fieldsAdd PrimarySupport = if(application == "NO_APPL", "", else: concat(":", taiou))
          | fieldsAdd END_HMS = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fieldsAdd TITLE = if(status == "Ended OK",
                                 concat(job_name, " (", system, ")正常終了 (", toString(RUN_COUNT), ")[", END_HMS, "]"),
                                 else: concat(job_name, " (", system, ")異常終了 (", toString(RUN_COUNT), PrimarySupport, ") [", END_HMS, "]"))
          | fieldsAdd BODY = if(status == "Ended OK",
                                concat(toString(alert.abend_time), "にアベンドした", job_name, "は正常終了しました"),
                                else: concat(job_name, "が", toString(alert.abend_time), "に異常終了しました"))
          | fields UID, job_name, status, application, group_name, owner, odate, end_ts, system, RUN_COUNT,
                   TITLE, BODY, CMD_STRING, def.node_id, def.host, contact.Email
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
        value = "アベンドしたControl-Mジョブが再度終了しました（正常終了または異常終了）。TITLE, BODY, CMD_STRING と contact.Email（ジョブ担当）を確認してください。"
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
