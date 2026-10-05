# Control-M Splunk alerts → Dynatrace, v2 (13 Splunk alerts → 1 detector + 6 workflows)
#
#   Splunk alert                                        Dynatrace
#   CH:UL Email Job status                              daily_reports["chde010m_ul_today"]
#   CHDE010MJob Status for MyAXA UL Email   (30 11 1-6) daily_reports["chde010m_myaxa_ul"] (merged)
#   Job Status for MyAXA UL Email           (30 11 2-6) daily_reports["chde010m_myaxa_ul"] (merged)
#   CHDR010MJob Status for MyAXA User Registration...   daily_reports["chdr010m_user_registration"]
#   Claims Status Service PDDW0100 Status               daily_reports["pddw0100_claims_status"]
#   CTL-M アベンドアラート + CTL-M アベンドアラートV2     controlm_job_abend (detector, merged)
#   CTL-M:ジョブ実行結果通知                              controlm_job_result_notify
#   Claim Job Over Run Alert                             claims_job_overrun
#
# Not migrated:
#   CTL-M:リラン確認                       only action is "Output results to lookup" (ControlmRerunHistory.csv), no notification
#   Claims Status Service PDDW0100 Status_test   test copy (koichi.hasegawa, subject 【test】)
#   Claims Status Service PDDW0100 Status複製    personal copy (shunjin.chen)
#   Job Status for MyAXA UL Email複製            personal copy (shunjin.chen, 25 11 * * 1-6)
#
# CONFIRM before apply:
#   1. log.source values for sourcetype controlm_activejobs and controlm_alert (check.dql query 1)
#   2. Control-M fields (job_name, status, start_time, end_time, order_id, isn, odate, message,
#      application, run_counter, data_center, group_name, owner) exist as log attributes (check.dql query 2).
#      If they only exist inside content, add a parse step after the source filter.
#   3. Lookup files uploaded to Grail (Settings > Lookup data), keyed by job_name:
#        /lookups/controlm/addresslist        (controlm_addresslist.csv, column Method / 対応方法)
#        /lookups/controlm/job_definition     (controlm_job_Definition.csv)
#        /lookups/controlm/specific_contact   (controlm_SpecificContact.csv, column Email)
#        /lookups/controlm/claims_jobs        (claims_jobs.csv)
#        /lookups/controlm/claims_job_list    (claims_job_list.csv, column job_name_jp)
#   4. Every email address (screenshots are blurry; some are cut off)

locals {
  cm_activejobs = "matchesValue(log.source, \"*controlm_activejobs*\")"
  cm_alert      = "matchesValue(log.source, \"*controlm_alert*\")"

  # Control-M times are text like 20261005063015 (yyyyMMddHHmmss, JST)
  cm_start_fmt = "concat(substring(start_time, from:0, to:4), \"/\", substring(start_time, from:4, to:6), \"/\", substring(start_time, from:6, to:8), \" \", substring(start_time, from:8, to:10), \":\", substring(start_time, from:10, to:12), \":\", substring(start_time, from:12, to:14))"
  cm_end_fmt   = "concat(substring(end_time, from:0, to:4), \"/\", substring(end_time, from:4, to:6), \"/\", substring(end_time, from:6, to:8), \" \", substring(end_time, from:8, to:10), \":\", substring(end_time, from:10, to:12), \":\", substring(end_time, from:12, to:14))"

  daily_reports = {

    # Splunk: CH:UL Email Job status   Today, 0 13 * * 2-6, throttle on JOB_CODE (no effect for a daily run)
    chde010m_ul_today = {
      title = "Prod_UL_CHDE010M_JobStatusToday_Normal"
      cron  = "0 13 * * 2-6"
      to    = ["mitsuru.noda@axa.co.jp", "masayuki.yasuda@axa.co.jp"] # CONFIRM, third address is cut off
      cc    = []
      query = <<-EOT
        fetch logs, from:now()-13h
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDE010M"
        | sort timestamp desc
        | dedup order_id
        | fieldsAdd StartTime = ${local.cm_start_fmt}, EndTime = ${local.cm_end_fmt}
        | fields job_name, status, StartTime, EndTime, odate
      EOT
      line  = "{{ r.job_name }}  {{ r.status }}  start {{ r.StartTime }}  end {{ r.EndTime }}  odate {{ r.odate }}"
    }

    # Splunk (2 alerts, same job, same list, same 11:30):
    #   CHDE010MJob Status for MyAXA UL Email   30 11 * * 1-6, dedup odate, only yesterday's order date
    #   Job Status for MyAXA UL Email           30 11 * * 2-6, dedup job_name, CC ops guild + tadashi.yoshida,
    #                                           subject "$name$ $result.MSG$", body "The job status of CHDE010M ..."
    #   Merged: yesterday's-order-date logic (stricter), union of recipients, MSG in the subject.
    chde010m_myaxa_ul = {
      title = "Prod_MyAXA_UL_CHDE010M_JobStatus_Normal"
      cron  = "30 11 * * 1-6"
      to    = ["digital_marketing_squad@axa.co.jp", "axa_jp_dl_emma_support@axa.co.jp"]               # CONFIRM
      cc    = ["alj_jp_dl_ops_guild_marketing_servicing@axa.co.jp", "tadashi.yoshida@axa.co.jp"] # CONFIRM
      query = <<-EOT
        fetch logs, from:now()-1d
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDE010M"
        | sort timestamp desc
        | dedup odate
        | filter odate == formatTimestamp(now() - 1d, format:"yyyyMMdd", timezone:"Asia/Tokyo")
        | fieldsAdd StartTime = ${local.cm_start_fmt}, EndTime = ${local.cm_end_fmt}
        | fieldsAdd MSG = if(status == "Ended OK", "OK", else:"正常終了していません要確認")
        | fields job_name, status, StartTime, EndTime, odate, MSG
      EOT
      line  = "JOB NAME: {{ r.job_name }}\nJOB STATUS: {{ r.status }}\nJOB START: {{ r.StartTime }}\nJOB END: {{ r.EndTime }}\nORDER DATE: {{ r.odate }}\n{{ r.MSG }}\n"
    }

    # Splunk: CHDR010MJob Status for MyAXA User Registration Batch   every day 06:00
    chdr010m_user_registration = {
      title = "Prod_MyAXA_UserRegistration_CHDR010M_JobStatus_Normal"
      cron  = "0 6 * * *"
      to    = ["digital_marketing_squad@axa.co.jp", "axa_jp_dl_emma_support@axa.co.jp"] # CONFIRM
      cc    = ["shunjin.chen@axa.co.jp"]                                                # CONFIRM, Teams channel address left out on purpose
      query = <<-EOT
        fetch logs, from:now()-24h
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDR010M"
        | sort timestamp desc
        | dedup job_name
        | fieldsAdd StartTime = ${local.cm_start_fmt}, EndTime = ${local.cm_end_fmt}
        | fieldsAdd MSG = if(status == "Ended OK", "OK", else:"NG")
        | fields job_name, status, StartTime, EndTime, MSG
      EOT
      line  = "{{ r.job_name }}  {{ r.status }}  start {{ r.StartTime }}  end {{ r.EndTime }}  {{ r.MSG }}"
    }

    # Splunk: Claims Status Service PDDW0100 Status   Last 24 hours, 15 8 * * *, priority Highest, inline table
    #   Message starts "担当各位 PDDWの完了時刻のレポートを送信致します。"
    pddw0100_claims_status = {
      title = "Prod_Claims_PDDW0100_JobStatus_Normal"
      cron  = "15 8 * * *"
      to    = ["akio.fukuda.ose@axa.co.jp", "ryusuke.tsumura@axa.co.jp"] # CONFIRM
      cc    = ["alj_jp_dl_uog_oo_s@axa.co.jp"]                           # CONFIRM, partly unreadable
      query = <<-EOT
        fetch logs, from:now()-24h
        | filter ${local.cm_activejobs}
        | filter startsWith(job_name, "PDDW")
        | filter not endsWith(job_name, "-S") and not endsWith(job_name, "-F") and job_name != "TEST001"
        | sort timestamp desc
        | dedup odate, order_id
        | filter status == "Ended OK"
        | lookup [ load "/lookups/controlm/claims_job_list" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ job_name_jp }
        | fieldsAdd StartDate = concat(substring(start_time, from:0, to:4), "/", substring(start_time, from:4, to:6), "/", substring(start_time, from:6, to:8))
        | fieldsAdd StartTime = concat(substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14))
        | fieldsAdd EndTime = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
        | sort start_time desc
        | fields job_name, job_name_jp, StartDate, StartTime, EndTime
      EOT
      line  = "JOB {{ r.job_name }}  処理 {{ r.job_name_jp }}  起動日 {{ r.StartDate }}  {{ r.StartTime }} - {{ r.EndTime }}"
    }
  }

  report_intro = {
    chde010m_ul_today          = "CHDE010M job status today."
    chde010m_myaxa_ul          = "The job status of CHDE010M"
    chdr010m_user_registration = "CHDR010M (emma registration batch) job status."
    pddw0100_claims_status     = "担当各位\n\nPDDWの完了時刻のレポートを送信致します。"
  }
}

resource "dynatrace_automation_workflow" "controlm_daily_report" {
  for_each = local.daily_reports

  title       = each.value.title
  description = "Daily Control-M job status email (converted from Splunk)."

  tasks {
    task {
      name        = "get_rows"
      description = "Control-M job status rows"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = each.value.query
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the job status"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = each.value.to
        cc      = each.value.cc
        bcc     = []
        subject = "${each.value.title} {{ result(\"get_rows\").records[0].MSG | default(\"\") }}"
        content = "${local.report_intro[each.key]}\n\n{% for r in result(\"get_rows\").records %}${each.value.line}\n{% endfor %}"
      })
      conditions {
        states = {
          get_rows = "OK"
        }
        custom = "{{ result(\"get_rows\").records | length > 0 }}"
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
        cron = each.value.cron
      }
    }
  }
}

# Splunk: CTL-M アベンドアラート (V1) and CTL-M アベンドアラートV2
#   sourcetype=controlm_alert message="Ended not OK", last 5 min every minute, throttle JOB_CODE
#   Both alerts run the same base search → one detector, one problem per job_name
resource "dynatrace_davis_anomaly_detectors" "controlm_job_abend" {
  title       = "Prod_ControlM_JobAbend_High"
  description = "A Control-M job ended not OK."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter ${local.cm_alert}
          | filter lower(message) == "ended not ok"
          | makeTimeseries count = count(default: 0), by:{ job_name }, interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "0"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "5"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "10"
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
        value = "Prod_ControlM_JobAbend_High"
      }
      property {
        key   = "event.description"
        value = "Control-M job {dims:job_name} ended not OK."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
    }
  }

  execution_settings {}
}

# Splunk: CTL-M:ジョブ実行結果通知
#   Jobs that abended in the last 24 h and have now ended (OK = recovered, not OK = failed again).
#   One email per job, To fixed person, CC from controlm_SpecificContact.csv.
#   Splunk ran every minute over overlapping windows + 10 min throttle; here each job end is
#   picked up exactly once: the first snapshot showing the end must fall in the last 5-minute slot.
resource "dynatrace_automation_workflow" "controlm_job_result_notify" {
  title       = "Prod_ControlM_JobResultNotify_Normal"
  description = "Every 5 minutes: one email per Control-M job that abended in the last 24 hours and has now ended."

  tasks {
    task {
      name        = "get_job_results"
      description = "Abended jobs that just ended"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-30m
          | filter ${local.cm_activejobs}
          | filter isNotNull(job_name) and job_name != ""
          | filter not endsWith(job_name, "-F") and not endsWith(job_name, "-S")
          | filter status == "Ended OK" or lower(status) == "ended not ok"
          | summarize first_seen = min(timestamp),
                      job_name = takeLast(job_name), status = takeLast(status),
                      application = takeLast(application), group_name = takeLast(group_name),
                      owner = takeLast(owner), odate = takeLast(odate),
                      start_time = takeLast(start_time), end_time = takeLast(end_time),
                      by:{ order_id, isn }
          | filter first_seen >= now() - 6m and first_seen < now() - 1m
          | lookup [ fetch logs, from:now()-24h
                     | filter ${local.cm_alert}
                     | summarize abend_time = max(timestamp), message = takeLast(message),
                                 data_center = takeLast(data_center), run_counter = takeLast(run_counter),
                                 by:{ order_id } ],
                   sourceField:order_id, lookupField:order_id, prefix:"alert."
          | filter isNotNull(alert.message)
          | lookup [ load "/lookups/controlm/addresslist" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ Method }
          | lookup [ load "/lookups/controlm/job_definition" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ mem_lib, cmd_line, memname, node_id, host }
          | lookup [ load "/lookups/controlm/specific_contact" ], sourceField:job_name, lookupField:job_name, prefix:"", fields:{ Email }
          | fieldsAdd system = if(alert.data_center == "CEAA204D" or alert.data_center == "Server#1", "Open",
                               else: if(alert.data_center == "mainframe#1", "MF#1",
                               else: if(alert.data_center == "mainframe#3", "MF#3", else: "unknown")))
          | fieldsAdd RUN_COUNT = if(application == "NO_APPL", toLong(alert.run_counter) + 1, else: toLong(alert.run_counter))
          | fieldsAdd PrimarySupport = if(application == "NO_APPL", "", else: concat(":", coalesce(Method, "N/A")))
          | fieldsAdd END_HMS = concat(substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
          | fieldsAdd CMD_STRING = if(isNull(mem_lib), cmd_line, else: concat(mem_lib, "\\", memname))
          | fieldsAdd TITLE = if(status == "Ended OK",
                                concat(job_name, " (", system, ")正常終了 (", toString(RUN_COUNT), ")[", END_HMS, "]"),
                                else: concat(job_name, " (", system, ")異常終了 (", toString(RUN_COUNT), PrimarySupport, ") [", END_HMS, "]"))
          | fieldsAdd BODY = if(status == "Ended OK",
                               concat(toString(alert.abend_time), "にアベンドした", job_name, "は正常終了しました"),
                               else: concat(job_name, "が", toString(alert.abend_time), "に異常終了しました"))
          | fieldsAdd recipients = if(isNull(Email) or Email == "",
                                     array("tadashi.yoshida@axa.co.jp"),
                                     else: array("tadashi.yoshida@axa.co.jp", Email))
          | fields TITLE, BODY, recipients, job_name, group_name, owner, odate, status, CMD_STRING, node_id, host
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email_per_job"
      description = "One email per job result"
      action      = "dynatrace.email:send-email"
      active      = true
      with_items  = "rec in {{ result(\"get_job_results\").records }}"
      concurrency = "1"
      input = jsonencode({
        # Whole-field expression so the array keeps its type; test once with a real record
        to      = "{{ _.rec.recipients }}"
        cc      = []
        bcc     = []
        subject = "{{ _.rec.TITLE }}"
        content = "{{ _.rec.BODY }}\n\nJob: {{ _.rec.job_name }}\nGroup: {{ _.rec.group_name }}\nOwner: {{ _.rec.owner }}\nOrder date: {{ _.rec.odate }}\nStatus: {{ _.rec.status }}\nCommand: {{ _.rec.CMD_STRING }}\nNode: {{ _.rec.node_id }}  Host: {{ _.rec.host }}"
      })
      conditions {
        states = {
          get_job_results = "OK"
        }
        custom = "{{ result(\"get_job_results\").records | length > 0 }}"
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
        cron = "*/5 * * * *"
      }
    }
  }
}

# Splunk: Claim Job Over Run Alert   index=controlm* + claims_jobs.csv, Last 24 hours, */5, no throttle
#   A claims job whose latest run has no end time and has been running 15+ minutes.
#   Splunk grouped by job_name (misses a new run when yesterday's run has an end time) and
#   compared elapsed with the text "15". Here it groups by run (order_id) and emails once per run:
#   only when the run crosses 15 minutes (between 15 and 20 minutes old, matching the 5-minute schedule).
resource "dynatrace_automation_workflow" "claims_job_overrun" {
  title       = "Prod_Claims_JobOverRun_Normal"
  description = "Every 5 minutes: email when a claims Control-M job has been running for 15 minutes without ending."

  tasks {
    task {
      name        = "get_overruns"
      description = "Claims jobs running 15+ minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-24h
          | filter ${local.cm_activejobs}
          | lookup [ load "/lookups/controlm/claims_jobs" ], sourceField:job_name, lookupField:job_name, prefix:"claims."
          | filter isNotNull(claims.job_name)
          | sort timestamp asc
          | summarize first_seen = min(timestamp), job_name = takeLast(job_name),
                      start_time = takeLast(start_time), end_time = takeLast(end_time),
                      by:{ order_id }
          | filter isNull(end_time) or end_time == ""
          | filter first_seen <= now() - 15m and first_seen > now() - 20m
          | fieldsAdd starttime = ${local.cm_start_fmt}
          | fields job_name, starttime, order_id
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the claims incident list"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = ["all_jp_dl_incident_claims@axa.co.jp"] # CONFIRM, partly unreadable
        cc      = []
        bcc     = []
        subject = "Prod_Claims_JobOverRun: {{ result(\"get_overruns\").records | length }} jobs running 15+ minutes"
        content = "Claims jobs still running after 15 minutes:\n\n{% for r in result(\"get_overruns\").records %}{{ r.job_name }}  started {{ r.starttime }}  order {{ r.order_id }}\n{% endfor %}"
      })
      conditions {
        states = {
          get_overruns = "OK"
        }
        custom = "{{ result(\"get_overruns\").records | length > 0 }}"
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
        cron = "*/5 * * * *"
      }
    }
  }
}
