# Splunk: controlm_job_update_infomation
#   index=controlm_temp (sourcetype=controlm_def_ver_jobs is_current_version=Y)
#                    OR (sourcetype=controlm_def_ver_lnki_p is_current_version=Y)
#   | c_date = change_date, else creation_date ; c_time = first 4 chars of change_time, else creation_time
#   | c_day_time = c_date.c_time
#   | change_date / creation_date = "%Y/%m/%d %H:%M:%S"
#   | CMDLINE = cmd_line if not empty, else "mem_lib\memname" (or memname) ; MONTH = month_1 .. month_12 joined
#   | rex field=condition "L-(?<pre_job>.*)-OK"
#   | stats values(job_name, pre_job, application, group_name, c_day_time, change_date, creation_date, node_id,
#           owner, days_cal, w_day_str, max_wait, cyclic_type, version_user, status, from_time, day_str)
#           MIN(CMDLINE) MIN(MONTH) by job_id table_id
#   | where pre_job!="YC-D-001-F"
#   | append [ same sources | rex field=condition "L-(?<condition>.*)-OK"
#              | stats values(job_name) as post_job values(condition) as job_name by job_id table_id ]
#   | ... (rest of the search is cut off on the screenshot)
#   Cron */30 * * * *, Last 60 minutes, Expires 24h, results > 0, Once, For each result, no throttle
#   Action: Send email, Priority Normal, subject "Splunk Alert: CTL-M更新ジョブ一覧...", Link to Results, Attach CSV
#   (recipients not copied)
#
# What it is: a list of Control-M job definitions that were created or changed in the last hour,
# with their predecessor (pre_job) and successor (post_job) jobs.
# Dynatrace: one problem per changed job definition (job_id + table_id + c_day_time).
#   The post_job list comes from a lookup over the same definitions (the Splunk append).
#
# CONFIRM before apply (check.dql):
#   1. log.source values for controlm_def_ver_jobs and controlm_def_ver_lnki_p (query 1)
#   2. is_current_version, condition, change_date/change_time, creation_date/creation_time are attributes (query 2)
#   3. The rest of the Splunk search after "append [...]" is not visible. Send a screenshot of the end of the search.
#      If it filters c_day_time to the last 30 minutes, add that filter here.
#   4. Splunk "where pre_job!=..." drops jobs with no predecessor at all. The query keeps that behavior.
#   5. Severity: email priority Normal → medium. This is a change notice; low is also reasonable.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "controlm_job_update_information" {
  title       = "controlm_job_update_infomation"
  description = "Control-M job definitions created or changed in the last 60 minutes (current version), with predecessor and successor jobs."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter matchesValue(log.source, "*controlm_def_ver_jobs*") or matchesValue(log.source, "*controlm_def_ver_lnki_p*")
          | filter is_current_version == "Y"
          | fieldsAdd c_date = coalesce(change_date, creation_date),
                      c_time = substring(coalesce(change_time, creation_time), from:0, to:4)
          | fieldsAdd c_day_time = concat(c_date, c_time)
          | fieldsAdd change_dt = concat(substring(change_date, from:0, to:4), "/", substring(change_date, from:4, to:6), "/", substring(change_date, from:6, to:8), " ",
                                         substring(change_time, from:0, to:2), ":", substring(change_time, from:2, to:4), ":", substring(change_time, from:4, to:6))
          | fieldsAdd creation_dt = concat(substring(creation_date, from:0, to:4), "/", substring(creation_date, from:4, to:6), "/", substring(creation_date, from:6, to:8), " ",
                                           substring(creation_time, from:0, to:2), ":", substring(creation_time, from:2, to:4), ":", substring(creation_time, from:4, to:6))
          | fieldsAdd CMDLINE = if(stringLength(cmd_line) > 0, cmd_line,
                                   else: if(isNotNull(mem_lib), concat(mem_lib, "\\", memname), else: memname))
          | fieldsAdd MONTH = concat(month_1, month_2, month_3, month_4, month_5, month_6,
                                     month_7, month_8, month_9, month_10, month_11, month_12)
          | parse condition, "'L-' LD:pre_job '-OK'"
          | lookup [
              fetch logs, from:now()-60m
              | filter matchesValue(log.source, "*controlm_def_ver_jobs*") or matchesValue(log.source, "*controlm_def_ver_lnki_p*")
              | filter is_current_version == "Y"
              | parse condition, "'L-' LD:pred_job '-OK'"
              | filter isNotNull(pred_job)
              | summarize post_job = collectDistinct(job_name), by:{ pred_job }
            ], sourceField:job_name, lookupField:pred_job, prefix:"succ.", fields:{ post_job }
          | summarize job_name = collectDistinct(job_name), pre_job = collectDistinct(pre_job), post_job = takeFirst(succ.post_job),
                      application = collectDistinct(application), group_name = collectDistinct(group_name),
                      c_day_time = max(c_day_time), change_date = collectDistinct(change_dt), creation_date = collectDistinct(creation_dt),
                      node_id = collectDistinct(node_id), owner = collectDistinct(owner), CMDLINE = min(CMDLINE),
                      days_cal = collectDistinct(days_cal), w_day_str = collectDistinct(w_day_str), max_wait = collectDistinct(max_wait),
                      cyclic_type = collectDistinct(cyclic_type), MONTH = min(MONTH), version_user = collectDistinct(version_user),
                      status = collectDistinct(status), from_time = collectDistinct(from_time), day_str = collectDistinct(day_str),
                      by:{ job_id, table_id }
          | filter arraySize(pre_job) > 0 and not contains(toString(pre_job), "YC-D-001-F")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_id"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "table_id"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[2]"
        value = "c_day_time"
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
        value = "CTL-M更新ジョブ一覧 controlm_job_update_infomation"
      }
      property {
        key   = "event.description"
        value = "A Control-M job definition was created or changed. See job_name, pre_job, post_job, application, group_name, CMDLINE, change_date and version_user on the problem."
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
