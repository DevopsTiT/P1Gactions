# Splunk: MYAXA NG state for 10min
#   index=jenkins latest=-10m job_result!="SUCCESS" job_name=".../External%20Check%20-%20MyAXA%20login-check/"
#     | JobName="Login_Check" | head 1
#   | append [ same for ".../External%20Check%20-%20MyAXA/" | JobName="Function_Check" | head 1 ]
#   | rename job_result as Job_Result_10min_ago, Time_10min_ago = _time
#   | join type=inner JobName [ inputlookup MYAXA_Monitoring.csv | job_result as Current_Job_Result, Current_Time ]
#   | join type=outer application [ inputlookup maintenance_window.csv | application="MyAXA", now between start and end ]
#   | where Time_10min_ago != Current_Time AND Job_Result_10min_ago == Current_Job_Result
#   | maintenance = "No" only
#   cron */5, Last 60 minutes, results > 0, Once, no throttle, email priority Normal
#
# Dynatrace: one problem per JobName (Login_Check, Function_Check).
#   Fires when the newest NG run older than 10 minutes has the same result as the current (newest) run,
#   the current run is a newer run, and MyAXA is not in a maintenance window.
#   MYAXA_Monitoring.csv (current state written by another Splunk search) is replaced by the newest log line.
#
# CONFIRM before apply (check.dql):
#   1. MyAXA External Check events reach Dynatrace on the Jenkins host and job_name values match (query 1)
#   2. /lookups/maintenance_window uploaded (application, start, end); start/end format "yyyy/MM/dd HH:mm" JST (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "myaxa_ng_state_10min" {
  title       = "MYAXA NG state for 10min"
  description = "MyAXA External Check (Login_Check or Function_Check) has been NG for 10 minutes or more: the newest NG run older than 10 minutes and the current run have the same result. Skipped during MyAXA maintenance."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "MyAXA", caseSensitive:false)
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result])
          | fieldsAdd JobName = if(job_name == "job/Functionally%20Check/job/External%20Check%20-%20MyAXA%20login-check/", "Login_Check",
                                else: if(job_name == "job/Functionally%20Check/job/External%20Check%20-%20MyAXA/", "Function_Check"))
          | filter isNotNull(JobName) and isNotNull(job_result)
          | sort timestamp asc
          | fieldsAdd ng_old_result = if(timestamp < now() - 10m and job_result != "SUCCESS", job_result)
          | fieldsAdd ng_old_time = if(timestamp < now() - 10m and job_result != "SUCCESS", timestamp)
          | summarize Job_Result_10min_ago = arrayLast(collectArray(ng_old_result)),
                      Time_10min_ago = max(ng_old_time),
                      Current_Job_Result = takeLast(job_result),
                      Current_Time = max(timestamp),
                      by:{ JobName }
          | filter isNotNull(Job_Result_10min_ago)
          | filter Current_Time > Time_10min_ago and Current_Job_Result == Job_Result_10min_ago
          | fieldsAdd application = "MyAXA"
          | lookup [ load "/lookups/maintenance_window"
                     | filter application == "MyAXA"
                     | fieldsAdd start_ts = toTimestamp(concat(replaceString(replaceString(toString(start), "/", "-"), " ", "T"), ":00+09:00")),
                                 end_ts = toTimestamp(concat(replaceString(replaceString(toString(end), "/", "-"), " ", "T"), ":00+09:00"))
                     | filter start_ts < now() and end_ts > now() ],
                   sourceField:application, lookupField:application, prefix:"mw."
          | filter isNull(mw.start_ts)
          | fields JobName, application, Time_10min_ago, Job_Result_10min_ago, Current_Time, Current_Job_Result
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "JobName"
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
        value = "MYAXA NG state for 10min"
      }
      property {
        key   = "event.description"
        value = "MyAXA External Check has stayed NG for 10 minutes or more. See JobName, Job_Result_10min_ago and Current_Job_Result on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "MyAXA"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
