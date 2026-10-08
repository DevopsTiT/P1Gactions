# Splunk: Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG
#   Same template as Prod_Life_BancaPortal_RealTimeAndFunctionalCheck_NG (2026-10-08 seq 20), except:
#     | rex field=_raw ".+?(?<remarks>OKメンテナンス中)"     (maintenance remark, kept in stats and table)
#     | where application="Compass AG"
#   index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE
#   | Functional jobs: job_result emptied; Real Time jobs renamed to the Functional project name
#   | lookup configuration name -> application | streamstats ... where index<=2 (last 2 runs)
#   | status OK if any SUCCESS, else NG | check_maintenance_window | add_alert_info
#   | search event=2 OR (status="OK" AND prev_status="NG")
#   cron */1, Last 2 hours, results > 0, Once, no throttle
#   Action: Alert Status Manager, email Production, PagerDuty Notification Enable (URL not copied)
#
# Dynatrace: one problem per application + name (project).
#   Opens when the Real Time job returned 2+ non-SUCCESS results in 2 hours with no SUCCESS.
#   Closes on the first SUCCESS. remarks shows "OKメンテナンス中" if a run was in maintenance.
#
# CONFIRM before apply (check.dql):
#   1. job_name values for Compass Real Time and Functional jobs (query 1)
#   2. /lookups/jenkins/configuration has these names with application "Compass AG" (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "compass_pb_realtime_functional_ng" {
  title       = "Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG"
  description = "Compass AG Real Time check returned 2 or more non-SUCCESS results in the last 2 hours with no SUCCESS. One problem per project."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-2h
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "App-Ops-OpenOps")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result])
          | filter job_result != "ABORTED" and job_result != "FAILURE"
          | fieldsAdd is_functional = contains(job_name, "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd is_realtime = contains(replaceString(job_name, "%20", " "), "App-Ops-OpenOps/app-check-group/Real Time Check")
          | filter is_functional or is_realtime
          | fieldsAdd remark = if(contains(content, "OKメンテナンス中"), "OKメンテナンス中")
          | fieldsAdd project = replaceString(replaceString(job_name, "%20", " "), "App-Ops-OpenOps/app-check-group/Real Time Check/", "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd name = replaceString(replaceString(project, "job/", ""), "/App", "App")
          | fieldsAdd name = if(endsWith(name, "/"), substring(name, from:0, to:stringLength(name) - 1), else: name)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter cfg.application == "Compass AG"
          | fieldsAdd application = cfg.application
          | summarize rt_fails = countIf(is_realtime and job_result != "SUCCESS"),
                      rt_oks = countIf(is_realtime and job_result == "SUCCESS"),
                      functional_runs = countIf(is_functional),
                      remarks = collectDistinct(remark),
                      last_seen = max(timestamp),
                      by:{ application, name }
          | filter rt_fails >= 2 and rt_oks == 0
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "application"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "name"
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
        value = "Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG"
      }
      property {
        key   = "event.description"
        value = "Compass AG Real Time check is NG (2+ non-SUCCESS results, no SUCCESS, last 2 hours). See name, rt_fails and remarks on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Compass AG"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
