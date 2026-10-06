# Control-M Splunk alerts → Dynatrace Records detectors (re-evaluated, detectors only)
#
#   Splunk alert                                         Dynatrace key
#   CTL-M アベンドアラート + CTL-M アベンドアラートV2      job_abend
#   CTL-M:ジョブ実行結果通知                               job_result_after_abend
#   Claim Job Over Run Alert                              claims_job_overrun
#   CH:UL Email Job status                                chde010m_no_success   (report → missing-success alert)
#   CHDE010MJob Status for MyAXA UL Email                 chde010m_no_success   (merged)
#   Job Status for MyAXA UL Email                         chde010m_no_success   (merged)
#   CHDR010MJob Status for MyAXA User Registration Batch  chdr010m_no_success
#   Claims Status Service PDDW0100 Status                 pddw_no_success
#
# Not migrated: CTL-M:リラン確認 (CSV only), PDDW0100 Status_test, PDDW0100 Status複製, Job Status for MyAXA UL Email複製
#
# CONFIRM before apply:
#   1. log.source values for controlm_activejobs and controlm_alert (check.dql query 1)
#   2. job_name, status, message, order_id, end_time exist as log attributes (check.dql query 2)
#   3. /lookups/controlm/claims_jobs uploaded to Grail (claims_job_overrun)
#   4. Run days of CHDE010M, CHDR010M and PDDW jobs (lookback windows below)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  cm_activejobs = "matchesValue(log.source, \"*controlm_activejobs*\")"
  cm_alert      = "matchesValue(log.source, \"*controlm_alert*\")"

  controlm_alerts = {

    # Splunk V1 and V2 run the same search: message="Ended not OK", last 5 min, every minute
    job_abend = {
      title       = "Prod_ControlM_JobAbend_High"
      description = "A Control-M job ended not OK in the last 5 minutes. One problem per job."
      severity    = "high"
      pagerduty   = "0" # CONFIRM: Splunk action was not visible in the screenshots
      identity    = "job_name"
      query       = <<-EOT
        fetch logs, from:now()-5m
        | filter ${local.cm_alert}
        | filter lower(message) == "ended not ok"
        | summarize count = count(), by:{ job_name }
      EOT
    }

    # Splunk: a job that abended in the last 24 h has now ended (recovered or failed again)
    job_result_after_abend = {
      title       = "Prod_ControlM_JobResultAfterAbend_Normal"
      description = "A Control-M job that abended in the last 24 hours has ended again. result shows recovered or failed again. One problem per run."
      severity    = "medium"
      pagerduty   = "0"
      identity    = "order_id"
      query       = <<-EOT
        fetch logs, from:now()-30m
        | filter ${local.cm_activejobs}
        | filter isNotNull(job_name) and job_name != ""
        | filter not endsWith(job_name, "-F") and not endsWith(job_name, "-S")
        | filter status == "Ended OK" or lower(status) == "ended not ok"
        | summarize first_seen = min(timestamp), job_name = takeLast(job_name), status = takeLast(status), by:{ order_id }
        | filter first_seen >= now() - 10m
        | lookup [ fetch logs, from:now()-24h
                   | filter ${local.cm_alert}
                   | summarize abend_time = max(timestamp), by:{ order_id } ],
                 sourceField:order_id, lookupField:order_id, prefix:"alert."
        | filter isNotNull(alert.abend_time)
        | fieldsAdd result = if(status == "Ended OK", "recovered", else:"failed again")
        | fields order_id, job_name, status, result, alert.abend_time
      EOT
    }

    # Splunk: claims job running 15+ minutes without an end time. Problem closes when the run ends.
    claims_job_overrun = {
      title       = "Prod_Claims_JobOverRun_Normal"
      description = "A claims Control-M job has been running for 15 minutes or more without ending. One problem per run."
      severity    = "medium"
      pagerduty   = "0"
      identity    = "order_id"
      query       = <<-EOT
        fetch logs, from:now()-24h
        | filter ${local.cm_activejobs}
        | lookup [ load "/lookups/controlm/claims_jobs" ], sourceField:job_name, lookupField:job_name, prefix:"claims."
        | filter isNotNull(claims.job_name)
        | sort timestamp asc
        | summarize first_seen = min(timestamp), job_name = takeLast(job_name), end_time = takeLast(end_time), by:{ order_id }
        | filter isNull(end_time) or end_time == ""
        | filter first_seen <= now() - 15m
        | fields order_id, job_name, first_seen
      EOT
    }

    # Splunk had 3 status-report emails for CHDE010M. As an alert: no "Ended OK" run in the lookback.
    # 74h covers a Tuesday-to-Saturday job across the weekend gap. CONFIRM run days.
    chde010m_no_success = {
      title       = "Prod_MyAXA_UL_CHDE010M_NoSuccess_Normal"
      description = "Control-M job CHDE010M has no Ended OK run in the last 74 hours."
      severity    = "medium"
      pagerduty   = "0"
      identity    = "check"
      query       = <<-EOT
        fetch logs, from:now()-74h
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDE010M"
        | summarize ok = countIf(status == "Ended OK")
        | filter ok == 0
        | fieldsAdd check = "chde010m_no_success"
      EOT
    }

    # Daily job (Splunk report every day 06:00). 26h gives a 2-hour grace period.
    chdr010m_no_success = {
      title       = "Prod_MyAXA_UserRegistration_CHDR010M_NoSuccess_Normal"
      description = "Control-M job CHDR010M (emma registration batch) has no Ended OK run in the last 26 hours."
      severity    = "medium"
      pagerduty   = "0"
      identity    = "check"
      query       = <<-EOT
        fetch logs, from:now()-26h
        | filter ${local.cm_activejobs}
        | filter job_name == "CHDR010M"
        | summarize ok = countIf(status == "Ended OK")
        | filter ok == 0
        | fieldsAdd check = "chdr010m_no_success"
      EOT
    }

    # Daily PDDW claims jobs (Splunk report every day 08:15).
    pddw_no_success = {
      title       = "Prod_Claims_PDDW0100_NoSuccess_Normal"
      description = "No PDDW claims Control-M job has an Ended OK run in the last 26 hours."
      severity    = "medium"
      pagerduty   = "0"
      identity    = "check"
      query       = <<-EOT
        fetch logs, from:now()-26h
        | filter ${local.cm_activejobs}
        | filter startsWith(job_name, "PDDW")
        | filter not endsWith(job_name, "-S") and not endsWith(job_name, "-F") and job_name != "TEST001"
        | summarize ok = countIf(status == "Ended OK")
        | filter ok == 0
        | fieldsAdd check = "pddw_no_success"
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "controlm_alerts" {
  for_each = local.controlm_alerts

  title       = each.value.title
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = each.value.identity
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
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
      property {
        key   = "app.name"
        value = "Control-M"
      }
      property {
        key   = "pagerduty.enabled"
        value = each.value.pagerduty
      }
    }
  }

  execution_settings {}
}
