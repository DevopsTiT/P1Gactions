# Splunk: Prod_Life_AGPortalNTTGW_RealTimeAndFunctionalCheck_NG
#   index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE
#   | App-Ops-OpenOps Functional jobs: job_result emptied (they do not decide OK/NG)
#   | App-Ops-OpenOps Real Time Check: renamed to its Functional project name
#   | name = job_name without "job/", %20 -> space, trailing "/" removed
#   | lookup configuration name -> application, pager_duty | where application="AG Portal NTTGW"
#   | streamstats ... where index<=2 (last 2 runs) | status OK if any SUCCESS, else NG
#   | check_maintenance_window | add_alert_info | search event=2 OR (status="OK" AND prev_status="NG")
#   cron */30, Last 30 minutes, Expires 24h, results > 0, Once, For each result, no throttle
#   Action: not visible in the screenshot (ends at Trigger Actions); pagerduty.enabled "0" until confirmed
#
# Data confirmed (search screenshot): index=jenkins source=jenkins/test, sourcetype jenkins:build_report,
#   host ceaa2099.prprivmgmt.intraxa, event_tag "build_report", 168,553 events since 10/1.
#
# Note: FAILURE and ABORTED are excluded exactly like Splunk, so NG comes only from other non-SUCCESS
#   results (for example UNSTABLE). A job that hard-fails every run is invisible to this alert.
#
# Dynatrace: one problem per application + name.
#   Opens when the counted jobs (everything except App-Ops Functional jobs) returned 2+ non-SUCCESS
#   results in 30 minutes with no SUCCESS. Closes on the first SUCCESS.
#
# CONFIRM before apply (check.dql):
#   1. /lookups/jenkins/configuration has rows with application "AG Portal NTTGW" (exact spelling, with spaces)
#   2. AG Portal NTTGW jobs run at least twice per 30 minutes; if not, widen to from:now()-60m
#   3. Trigger actions: PagerDuty Enable -> set pagerduty.enabled to "1"; email Debug or TEST -> lower severity

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
  description = "AG Portal NTTGW Jenkins check returned 2 or more non-SUCCESS results in the last 30 minutes with no SUCCESS. One problem per job."
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
          | filter contains(content, "build_report")
          | parse content, "JSON:j"
          | filter isNull(j[job_duration])
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result])
          | filter isNotNull(job_name) and job_result != "ABORTED" and job_result != "FAILURE"
          | fieldsAdd is_functional = contains(job_name, "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd project = replaceString(replaceString(job_name, "%20", " "), "App-Ops-OpenOps/app-check-group/Real Time Check/", "App-Ops-OpenOps/app-check-jobs/Functional/")
          | fieldsAdd name = replaceString(replaceString(project, "job/", ""), "/App", "App")
          | fieldsAdd name = if(endsWith(name, "/"), substring(name, from:0, to:stringLength(name) - 1), else: name)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter cfg.application == "AG Portal NTTGW"
          | fieldsAdd application = cfg.application
          | summarize fails = countIf(not is_functional and job_result != "SUCCESS"),
                      oks = countIf(not is_functional and job_result == "SUCCESS"),
                      functional_runs = countIf(is_functional),
                      last_seen = max(timestamp),
                      by:{ application, name }
          | filter fails >= 2 and oks == 0
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
        value = "AG Portal NTTGW Jenkins check is NG (2+ non-SUCCESS results, no SUCCESS, last 30 minutes). See name and fails on the problem."
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
        value = "0"
      }
    }
  }

  execution_settings {}
}
