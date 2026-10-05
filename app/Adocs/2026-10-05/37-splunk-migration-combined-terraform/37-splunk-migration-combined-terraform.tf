# ==========================================================================
# Splunk → Dynatrace migration, 2026-10-05: all converted alerts in one file
#
#   Section  Source seq  Splunk group                          Dynatrace objects
#   A        27          OpenPaaS / ESG (7 alerts)             5 detectors        dynatrace_davis_anomaly_detectors.openpaas[*]
#   B        28          PowerCenter service down (3 alerts)   1 detector         dynatrace_davis_anomaly_detectors.powercenter_master_elect_lock
#   C        29          Datalake batch result (1 alert)       1 workflow         dynatrace_automation_workflow.datalake_batch_result
#   D        31          Control-M (13 alerts, v2)             1 detector         dynatrace_davis_anomaly_detectors.controlm_job_abend
#                                                              6 workflows        controlm_daily_report[*], controlm_job_result_notify, claims_job_overrun
#   E        32          IWFM (3 alerts)                       3 detectors        dynatrace_davis_anomaly_detectors.iwfm[*]
#   F        34          Jenkins Application Monitoring (10)   2 detectors        dynatrace_davis_anomaly_detectors.jenkins_app_monitoring[*]
#   G        35          HTTP Response Check Outlier (1)       1 detector         dynatrace_davis_anomaly_detectors.jenkins_aggw_lb_response_outlier
#   H        36          Broker Policy undefined error (1)     1 detector         dynatrace_davis_anomaly_detectors.broker_policy_undefined_error
#
#   Seq 30 is NOT included: seq 31 is its v2 and replaces it.
#
# CONFIRM before apply:
#   Every section still has its own "CONFIRM" lines (log.source / namespace guesses,
#   recipients, lookup file paths). Run each source seq's check.dql first.
#   Lookups used: /lookups/controlm/* (section D), /lookups/jenkins/configuration (section F).
#
# No secrets in this file. PagerDuty keys from the Splunk screenshots were not copied.
# ==========================================================================

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}


# ##########################################################################
# SECTION: from seq 27-openpaas-splunk-alerts-transform
# ##########################################################################

# ==========================================
# OpenPaaS / ESG Splunk alerts → Dynatrace detectors (Terraform only, no workflows)
# 7 Splunk alerts → 5 detectors (3 "Emma BE timeout to ESG" alerts had the same search)
#
# CONFIRM BEFORE APPLY: the Splunk index / sourcetype / host filters below are mapped to
# Dynatrace fields by guess. Run check.dql query 1 and replace each line marked CONFIRM.
# ==========================================

locals {
  openpaas_alerts = {

    # Splunk: ALJ OpenPaaS Egress Proxy Public IP Usage Alert
    # index=apigw_syslog sourcetype=apigw_syslog_prod /maam/* (*52.76.125.86* OR *54.179.120.88*)
    # | stats count | where count <= 0   → every 15 min over 15 min, High, email
    # Absence alert: fires when neither egress IP was used for 15 minutes.
    egress_proxy_ip_absent = {
      name        = "Prod_OpenPaaS_EgressProxyPublicIPUsage_High"
      description = "Only one egress proxy public IP is in use: neither 52.76.125.86 nor 54.179.120.88 appeared in ESG (/maam/) logs for 15 minutes."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*apigw_syslog*")
        | filter contains(content, "/maam/")
        | filter contains(content, "52.76.125.86") or contains(content, "54.179.120.88")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM line 1 (Splunk index=apigw_syslog sourcetype=apigw_syslog_prod)
      threshold   = "1"
      condition   = "BELOW"
      violating   = "15"
      window      = "15"
      dealerting  = "5"
    }

    # Splunk (3 alerts, same search):
    #   ESG - Emma BE timeout to ESG Production                       (email)
    #   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High               (High, PagerDuty, email)
    #   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High_PagerDuty     (PagerDuty)
    # index="myaxabackend-prod-axa-li-jp" "api-jp-cert.corp.intraxa" AND "java.net.SocketTimeoutException"
    # | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
    # every 5 min over 5 min, results > 20, throttle 60 s
    emma_be_timeout_to_esg = {
      name        = "Prod_Life_Emma_EmmaBETimeoutToESGProduction_High"
      description = "More than 20 timeouts in 5 minutes on calls from Emma BE (OpenPaaS) to ESG (CoreIT)."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter (k8s.namespace.name == "myaxabackend-prod-axa-li-jp"
                  and contains(content, "api-jp-cert.corp.intraxa", caseSensitive: false)
                  and contains(content, "java.net.SocketTimeoutException", caseSensitive: false))
              or (matchesValue(log.source, "*apigw_syslog*")
                  and contains(content, "Problem routing to", caseSensitive: false)
                  and contains(content, "timed out", caseSensitive: false)
                  and contains(content, "myaxa-api.alj.intraxa", caseSensitive: false))
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      # CONFIRM: k8s.namespace.name (Splunk index=myaxabackend-prod-axa-li-jp) and log.source (apigw_syslog)
      threshold   = "20"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: PIS Connection Issue (Batch->OpenPaaS) Alert
    # index=claims host="CEAA2058.prprivmgmt.intraxa" sourcetype=pis_defaultlog
    # | regex _raw="\"errorCode\":\s\"ESG120\""   → every 5 min over 5 min, > 0, email (Normal)
    pis_connection_esg120 = {
      name        = "Prod_Claims_PISConnectionIssueBatchToOpenPaaS_Normal"
      description = "PIS batch on CEAA2058 logged errorCode ESG120 (connection issue from Batch to OpenPaaS)."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(host.name, "ceaa2058*")
        | filter matchesValue(log.source, "*pis_default*")
        | filter contains(content, "errorCode") and contains(content, "\"ESG120\"")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: host.name and log.source (Splunk host=CEAA2058.prprivmgmt.intraxa sourcetype=pis_defaultlog)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: eopt - OpenPaaS Pod Error (Backend)
    # index="eopt-prod-axa-li-jp" | rex "(?<timestamp>ISO8601 ms Z)\s+(?<level>[A-Z]+)" | eval level=upper(level) | search level="ERROR"
    # every hour at :00, > 0, email (Normal)
    eopt_pod_error_backend = {
      name        = "Prod_eopt_OpenPaaSPodErrorBackend_Normal"
      description = "eopt backend pod on OpenPaaS logged a line with level ERROR."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
        | parse content, "LD ISO8601:log_ts SPACE+ WORD:level"
        | filter upper(level) == "ERROR"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: k8s.namespace.name (Splunk index=eopt-prod-axa-li-jp) and that the parse matches (check.dql query 3)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }

    # Splunk: eopt - OpenPaaS Pod Error (Frontend)
    # index="eopt-prod-axa-li-jp" | spath | eval level=upper(level) | search level="ERROR"
    # every hour at :00, > 0, email (Normal)
    eopt_pod_error_frontend = {
      name        = "Prod_eopt_OpenPaaSPodErrorFrontend_Normal"
      description = "eopt frontend pod on OpenPaaS logged a JSON line with level ERROR."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
        | parse content, "JSON:j"
        | filter upper(toString(j[level])) == "ERROR"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: k8s.namespace.name and that JSON lines have a "level" key (check.dql query 3)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "openpaas" {
  for_each = local.openpaas_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = each.value.condition
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = each.value.violating
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = each.value.window
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
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
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: from seq 28-powercenter-down-alerts-check
# ##########################################################################

# Replaces 3 Splunk alerts that all run: index="powercenter" ISP_MASTER_ELECT_LOCK
#   0031_MWSP-PowerCenter-Service-Down-Alert  last 1 min,  every 1 min, results > 2, Normal
#   PowerCenter-ProcessStop                   last 15 min, every 1 min, results > 0, High
#   Powercenter down                          last 1 min,  every 1 min, results > 3, Normal
# ProcessStop (> 0) already fires whenever the other two would, so one detector covers all three.

resource "dynatrace_davis_anomaly_detectors" "powercenter_master_elect_lock" {
  title       = "Prod_MWSP_PowerCenter_ServiceDown_High"
  description = "PowerCenter logged ISP_MASTER_ELECT_LOCK. The PowerCenter service or process may be down."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key = "query"
        # CONFIRM line 2: Splunk index="powercenter" → real Dynatrace field (check.dql query 1)
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*powercenter*")
          | filter contains(content, "ISP_MASTER_ELECT_LOCK", caseSensitive: false)
          | makeTimeseries count = count(default: 0), by:{ dt.entity.host }, interval:1m
        EOT
      }
      analyzer_input_field {
        # Use "2" instead if check.dql query 2 shows 1-2 lines per minute is normal background
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
        value = "15"
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
        value = "Prod_MWSP_PowerCenter_ServiceDown_High"
      }
      property {
        key   = "event.description"
        value = "PowerCenter logged ISP_MASTER_ELECT_LOCK on {dims:dt.entity.host}. The PowerCenter service or process may be down."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "dt.source_entity"
        value = "{dims:dt.entity.host}"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: from seq 29-datalake-batch-result-transfer
# ##########################################################################

# Replaces Splunk alert "Datalake_Batch Result"
#   index="batch_monitoring_logs" | table _time _raw
#   Time range: Today (midnight to now)   Cron: 0 8 * * *   Fires when results > 0   Email, Normal
# This is a daily report (a table of lines), so it is a scheduled workflow, not a detector.

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
        # Runs at 08:00 JST, so now()-8h is midnight JST (same as Splunk "Today")
        # CONFIRM line 3: Splunk index="batch_monitoring_logs" → real Dynatrace field (check.dql query 1)
        query = <<-EOT
          fetch logs, from:now()-8h
          | filter matchesValue(log.source, "*batch_monitoring*")
          | sort timestamp asc
          | fields timestamp, content
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
        # CONFIRM the address spelling from the Splunk screenshot
        to      = ["masayuki.yasuda@axa.co.jp"]
        cc      = []
        bcc     = []
        subject = "Prod_Datalake_BatchResult_Normal: {{ result(\"get_batch_lines\").records | length }} lines since midnight"
        content = "Datalake batch monitoring lines since 00:00 JST:\n\n{% for r in result(\"get_batch_lines\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
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

# ##########################################################################
# SECTION: from seq 31-controlm-alerts-full-inventory-v2
# ##########################################################################

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

# ##########################################################################
# SECTION: from seq 32-iwfm-splunk-alerts-transform
# ##########################################################################

# IWFM-related Splunk alerts → Dynatrace detectors (3 Splunk alerts → 3 detectors, no workflows)
#
#   EIP - IWFM : EIP006 service Failure Alert      → iwfm_alerts["eip006_service_failure"]
#   [Prod]ALJ-Compass-IWFMReportException発生       → iwfm_alerts["compass_iwfm_report_exception"]
#   IWFM_Errors                                    → iwfm_alerts["iwfm_agent_errors"]
#
# CONFIRM before apply (check.dql query 1 and 2):
#   index=eip1015 sourcetype=eip_mediator_serverlog   → log.source guess "*eip_mediator_serverlog*"
#   index=compass-prod-axa-li-jp                      → k8s.namespace.name guess
#   index=iwfm sourcetype=fmwsagentlog                → log.source guess "*fmwsagentlog*"
#   Status and LOGLEVEL are Splunk field extractions  → may only exist inside content

locals {
  iwfm_alerts = {

    # Splunk: index=eip1015 sourcetype=eip_mediator_serverlog jp-Distributing-Sell-GenerateFormImage-v2-vs* Status=FAILURE
    #   Last 1 minute, every minute, results > 2, High, email alj_jp_dl_infra_mwss
    eip006_service_failure = {
      name        = "Prod_EIP_IWFM_EIP006ServiceFailure_High"
      description = "More than 2 FAILURE results in 1 minute from EIP006 (jp-Distributing-Sell-GenerateFormImage-v2), which depends on the backend IWFM system."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*eip_mediator_serverlog*")
        | filter contains(content, "jp-Distributing-Sell-GenerateFormImage-v2-vs", caseSensitive: false)
        | filter contains(content, "Status=FAILURE", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "2"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=compass-prod-axa-li-jp "IWFMReportException"
    #   Last 5 minutes, every 5 minutes, results > 15, Normal, email compass IT member + aog list
    compass_iwfm_report_exception = {
      name        = "Prod_Compass_IWFMReportException_Normal"
      description = "More than 15 IWFMReportException lines in 5 minutes in Compass (prod)."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "compass-prod-axa-li-jp"
        | filter contains(content, "IWFMReportException", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      threshold   = "15"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=iwfm sourcetype=fmwsagentlog earliest=-1h (LOGLEVEL="Caution" OR LOGLEVEL="Fatal")
    #         | transaction host AGENTID maxspan=1s
    #   Every hour at :15, results > 0, throttle 1 hour, Normal, email raju.kolukuluri
    #   transaction only groups lines that arrive within 1 second; "> 0" still means "any line".
    iwfm_agent_errors = {
      name        = "Prod_IWFM_AgentErrors_Normal"
      description = "IWFM agent (fmwsagentlog) logged LOGLEVEL Caution or Fatal."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*fmwsagentlog*")
        | filter contains(content, "LOGLEVEL=\"Caution\"", caseSensitive: false)
              or contains(content, "LOGLEVEL=\"Fatal\"", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "iwfm" {
  for_each = local.iwfm_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = each.value.condition
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = each.value.violating
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = each.value.window
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
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
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: from seq 34-jenkins-app-monitoring-alerts-transform
# ##########################################################################

# Jenkins "Application Monitoring Alert" family → Dynatrace (10 Splunk alerts → 2 detectors)
#
#   Application Monitoring Alert - URL                     → jenkins_url_check_failed
#   Application Monitoring Alert - URL for MyAXA           → jenkins_url_check_failed
#   Application Monitoring Alert - function                → jenkins_functional_check_failed (pager_duty = 0 apps)
#   ... - function for AG Portal      (AG Portal NTTGW)    → jenkins_functional_check_failed
#   ... - function for BancaPotal     (Banca Portal)       → jenkins_functional_check_failed
#   ... - function for Cockpit360     (Cockpit360)         → jenkins_functional_check_failed
#   ... - function for Compass        (Compass)            → jenkins_functional_check_failed
#   ... - function for Compass PB     (Compass AG)         → jenkins_functional_check_failed
#   ... - function for FCR            (FCR)                → jenkins_functional_check_failed
#   ... - function for ICM            (Claims ICM)         → jenkins_functional_check_failed
#
# Splunk pattern in all 10: keep the last 2 results per check (streamstats index<=2),
# alert when both are NG (event=2 and status=NG), send recovery when OK follows NG,
# Alert Status Manager pages PagerDuty per application.
# Dynatrace: one problem per application + check, opens on 2 failed runs with no OK run in the
# look-back window, closes on the first OK run. PagerDuty keys from the screenshots are NOT copied:
# paging goes through the standard flow, using the pager_duty property (0 = do not page).
#
# CONFIRM before apply:
#   1. log.source for jenkins_console "[HTTP Monitor]" lines and for source="jenkins/test"   (check.dql 1)
#   2. HTTP Monitor line format (where the response code sits)                              (check.dql 2)
#   3. jenkins/test JSON keys: job_name, job_result, testsuite.testcase[].testname/status   (check.dql 3)
#   4. Upload the Splunk "configuration" lookup as /lookups/jenkins/configuration
#      (key job_name, columns application, pager_duty)                                       (check.dql 5)
#   5. Macros check_maintenance_window and add_alert_info: ask for their definitions
#   6. "function" (generic) reads index=jenkins_statistics sourcetype json:jenkins:old. Confirm that
#      source is still written; if yes, add it as a second branch of the functional query.

locals {
  jenkins_url_window_min        = 15  # Splunk: Last 15 minutes
  jenkins_functional_window_min = 120 # Splunk: Last 2 hours

  jenkins_detectors = {

    jenkins_url_check_failed = {
      name        = "Prod_Jenkins_AppMonitoring_URLCheckFailed_High"
      description = "Jenkins HTTP Monitor for {dims:application} ({dims:name}) failed twice in a row with no OK result."
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*jenkins*console*")
        | filter contains(content, "[HTTP Monitor]")
        | parse log.source, "LD 'job/' LD:job_path '/' INT '/console'"
        | fieldsAdd name = replaceString(job_path, "%20", " ")
        | parse content, "LD 'status' LD INT:responsecode"
        | fieldsAdd failed = if(responsecode == 200, 0, else: 1)
        | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
        | fieldsAdd application = coalesce(cfg.application, "-"), pager_duty = coalesce(toString(cfg.pager_duty), "1")
        | makeTimeseries fail = sum(failed, default: 0), ok = sum(1 - failed, default: 0), by:{ application, name, pager_duty }, interval:1m
        | fieldsAdd fail_n = arrayMovingSum(fail, ${local.jenkins_url_window_min}), ok_n = arrayMovingSum(ok, ${local.jenkins_url_window_min})
        | fieldsAdd consecutive_ng = if(fail_n[] >= 2 and ok_n[] == 0, 1, else: 0)
        | fieldsKeep timeframe, interval, application, name, pager_duty, consecutive_ng
      EOT
    }

    jenkins_functional_check_failed = {
      name        = "Prod_Jenkins_AppMonitoring_FunctionalCheckFailed_High"
      description = "Jenkins functional test {dims:testname} for {dims:application} failed twice in a row with no PASSED result."
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*jenkins/test*")
        | filter job_result != "ABORTED" and job_result != "FAILURE"
        | parse content, "JSON:j"
        | expand tc = j[testsuite][testcase]
        | fieldsAdd testname = toString(tc[testname]), failed = if(toString(tc[status]) == "PASSED", 0, else: 1)
        | fieldsAdd name = replaceString(replaceString(job_name,
                            "App-Ops-OpenOps/app-check-group/Real Time Check/", "App-Ops-OpenOps/app-check-jobs/Functional/"),
                            "%20", " ")
        | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
        | filter isNotNull(cfg.application)
        | fieldsAdd application = cfg.application, pager_duty = coalesce(toString(cfg.pager_duty), "1")
        | makeTimeseries fail = sum(failed, default: 0), ok = sum(1 - failed, default: 0), by:{ application, testname, pager_duty }, interval:1m
        | fieldsAdd fail_n = arrayMovingSum(fail, ${local.jenkins_functional_window_min}), ok_n = arrayMovingSum(ok, ${local.jenkins_functional_window_min})
        | fieldsAdd consecutive_ng = if(fail_n[] >= 2 and ok_n[] == 0, 1, else: 0)
        | fieldsKeep timeframe, interval, application, testname, pager_duty, consecutive_ng
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "jenkins_app_monitoring" {
  for_each = local.jenkins_detectors

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
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
        value = "3"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "1"
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
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "{dims:application}"
      }
      property {
        # 0 = Splunk "PagerDuty Disable" apps; the standard flow needs a rule to skip paging for these
        key   = "pagerduty.enabled"
        value = "{dims:pager_duty}"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: from seq 35-http-response-outlier-alert-transform
# ##########################################################################

# Splunk "HTTP Response Check Outlier" → Dynatrace auto-adaptive detector
#
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]" job_name="HTTP Monitor - AGGW LB"
#   | eval duration=replace(duration,"s","")
#   | timechart span=10m max(duration) as responsetime | head 1000
#   | streamstats window=200 median, median absolute deviation (MAD)
#   | outlier if responsetime < median - 20*MAD or > median + 20*MAD
#   | head 1 | search isOutlier=1
#   Last 24 hours, every 10 minutes, email masayuki.yasuda, subject 【TEST】 (a test alert)
#
# Dynatrace: the auto-adaptive analyzer learns the baseline and the normal fluctuation itself,
# which is what the streamstats median and MAD code did by hand. ABOVE only: the analyzer
# supports ABOVE or BELOW, and a faster-than-usual response is not an incident.
#
# CONFIRM before apply:
#   1. log.source for jenkins_console, and how the AGGW LB job is identified   (check.dql 1)
#   2. How duration appears in the line (e.g. "duration=0.532s")             (check.dql 2)

resource "dynatrace_davis_anomaly_detectors" "jenkins_aggw_lb_response_outlier" {
  title       = "Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal"
  description = "HTTP Monitor - AGGW LB response time is far above its learned baseline."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.AutoAdaptiveAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*jenkins*console*")
          | filter contains(content, "[HTTP Monitor]")
          | filter contains(log.source, "HTTP%20Monitor%20-%20AGGW%20LB") or contains(content, "HTTP Monitor - AGGW LB")
          | parse content, "LD 'duration' LD DOUBLE:responsetime 's'"
          | makeTimeseries responsetime = max(responsetime), interval:1m
        EOT
      }
      analyzer_input_field {
        # How many "normal fluctuations" above the baseline count as a violation.
        # Splunk used 20 x MAD, which is very wide; start at 5 and tune with the preview.
        key   = "numberOfSignalFluctuations"
        value = "5"
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
        value = "5"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "10"
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
        value = "Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal"
      }
      property {
        key   = "event.description"
        value = "HTTP Monitor - AGGW LB response time is far above its learned baseline ({violating_samples} of the last 10 minutes)."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "AGGW LB"
      }
    }
  }

  execution_settings {}
}

# ##########################################################################
# SECTION: from seq 36-broker-policy-undefined-error-alert
# ##########################################################################

# Splunk alert → Dynatrace detector (1 Splunk alert → 1 detector, no workflow)
#
#   ALJ Broker Policy Maintenance: Cannot read properties of undefined
#     index=brokerpolicymaintenance-prod-axa-li-jp *Cannot read properties of undefined*
#     | timechart span=1m count | where count > 50
#     Last 5 minutes, cron */1, results > 0, trigger "For each result", no throttle
#     Email: Splunk Alert: $name$ (Normal) to 2 recipients
#
# CONFIRM before apply (check.dql query 1):
#   The Splunk index name looks like an OpenShift (OCP) namespace → guessed k8s.namespace.name.
#   If the logs arrive with another attribute, change the first filter line only.

resource "dynatrace_davis_anomaly_detectors" "broker_policy_undefined_error" {
  title       = "Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal"
  description = "More than 50 'Cannot read properties of undefined' errors in one minute in brokerpolicymaintenance (prod). Check the OCP pod status."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter k8s.namespace.name == "brokerpolicymaintenance-prod-axa-li-jp"
          | filter contains(content, "Cannot read properties of undefined", caseSensitive: false)
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = "50"
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
        value = "5"
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
        value = "Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal"
      }
      property {
        key   = "event.description"
        value = "More than 50 'Cannot read properties of undefined' errors in one minute in brokerpolicymaintenance (prod). Check the OCP pod status."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Broker Policy Maintenance"
      }
    }
  }

  execution_settings {}
}
