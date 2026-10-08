# Splunk: Prod_Life_AGPortalNTTGW_RealTimeAndFunctionalCheck_NG
#   index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE
#   | rename testsuite.* as job_duration, testname, teststatus, testduration
#   | Functional jobs (App-Ops-OpenOps/app-check-jobs/Functional/): job_result emptied, _time flagged "0"
#   | Real Time jobs (App-Ops-OpenOps/app-check-group/Real Time Check/): job_duration emptied,
#     job_name rewritten to the Functional project name, so both kinds share one "name"
#   | name = job_name without "job/", "%20" -> " ", no trailing "/"
#   | lookup jenkins.main.url, lookup configuration name -> application, job_name, pager_duty
#   | where application="AG Portal NTTGW"
#   | streamstats count by job_name | where index<=2                       (last 2 runs per job)
#   | test_result per testname: OK if any PASSED, else NG
#   | status per name: OK if any job_result is SUCCESS, else NG; event = number of job results
#   | check_maintenance_window | add_alert_info | search event=2 OR (status="OK" AND prev_status="NG")
#   cron */30, Last 30 minutes, results > 0, Once, no throttle
#   Action: Alert Status Manager, email Production, PagerDuty Notification Enable (URL not copied)
#
# Dynatrace: one problem per application + name (project).
#   Opens when the Real Time job for the project returned 2+ non-SUCCESS results in 30 minutes with no SUCCESS.
#   Closes on the first SUCCESS, which replaces the Splunk "status OK and prev_status NG" recovery mail.
#   Failed Functional test case names (testsuite.testcase{} array) are not on the problem: use check query 3.
#
# CONFIRM before apply (check.dql):
#   1. job_name values for Real Time and Functional jobs (query 1)
#   2. /lookups/jenkins/configuration has these names with application "AG Portal NTTGW" (query 2)
#   3. Macros check_maintenance_window and add_alert_info: definitions not migrated

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "ag_portal_nttgw_realtime_functional_ng" {
  title       = "Prod_Life_AGPortalNTTGW_RealTimeAndFunctionalCheck_NG"
  description = "AG Portal NTTGW Real Time check returned 2 or more non-SUCCESS results in the last 30 minutes with no SUCCESS. One problem per project."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-30m
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "App-Ops-OpenOps")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result])
          | filter job_result != "ABORTED" and job_result != "FAILURE"
          | fieldsAdd is_functional = contains(job_name, "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd is_realtime = contains(replaceString(job_name, "%20", " "), "App-Ops-OpenOps/app-check-group/Real Time Check")
          | filter is_functional or is_realtime
          | fieldsAdd project = replaceString(replaceString(job_name, "%20", " "), "App-Ops-OpenOps/app-check-group/Real Time Check/", "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd name = replaceString(replaceString(project, "job/", ""), "/App", "App")
          | fieldsAdd name = if(endsWith(name, "/"), substring(name, from:0, to:stringLength(name) - 1), else: name)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter cfg.application == "AG Portal NTTGW"
          | fieldsAdd application = cfg.application
          | summarize rt_fails = countIf(is_realtime and job_result != "SUCCESS"),
                      rt_oks = countIf(is_realtime and job_result == "SUCCESS"),
                      functional_runs = countIf(is_functional),
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
        value = "Prod_Life_AGPortalNTTGW_RealTimeAndFunctionalCheck_NG"
      }
      property {
        key   = "event.description"
        value = "AG Portal NTTGW Real Time check is NG (2+ non-SUCCESS results, no SUCCESS, last 30 minutes). See name and rt_fails on the problem; failed test cases are in the Jenkins build report."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "AG Portal NTTGW"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
