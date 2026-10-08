# Splunk: Prod_Life_Compass_RealTimeAndFunctionalCheck_NG
#   Same template as Prod_Life_Cockpit360ALL_RealTimeAndFunctionalCheck_NG (2026-10-08 seq 22), except:
#     | where application="Compass"
#   index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)
#   | where isnotnull(job_duration) | rex tempname from "Building ...", remarks "OKメンテナンス中"
#   | applications/ = Functional, group-jobs = Real Time; job_name = tempname with " » " -> "/"
#   | lookup configuration -> application | streamstats ... where index<=2 (last 2 runs)
#   | status OK if any SUCCESS, else NG | check_maintenance_window | add_alert_info
#   | search event > 0 OR (status="OK" AND prev_status="NG")
#   cron */1, Last 2 hours, results > 0, Once, no throttle
#   Action: Alert Status Manager, email Production (PagerDuty setting cut off in the screenshot)
#
# Dynatrace: one problem per application + name (project).
#   Opens when the Real Time (group-jobs) run returned 2+ non-SUCCESS results in 2 hours with no SUCCESS.
#   Closes on the first SUCCESS. remarks shows "OKメンテナンス中" if a run was in maintenance.
#
# CONFIRM before apply (check.dql):
#   1. PagerDuty Enable or Disable on the Alert Status Manager; set pagerduty.enabled
#   2. /lookups/jenkins/configuration has rows with application "Compass" (not "Compass AG") (query 2)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "compass_realtime_functional_ng" {
  title       = "Prod_Life_Compass_RealTimeAndFunctionalCheck_NG"
  description = "Compass Real Time check returned 2 or more non-SUCCESS results in the last 2 hours with no SUCCESS. One problem per project."
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
          | filter contains(content, "job_name")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), job_duration = j[job_duration]
          | filter matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")
          | filter isNotNull(job_duration)
          | parse content, "LD '\"name\":\"Building ' LD:tempname '\"'"
          | fieldsAdd is_realtime = matchesValue(job_name, "group-jobs*")
          | fieldsAdd name = if(isNotNull(tempname), replaceString(tempname, " » ", "/"), else: job_name)
          | fieldsAdd remark = if(contains(content, "OKメンテナンス中"), "OKメンテナンス中")
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter cfg.application == "Compass"
          | fieldsAdd application = cfg.application
          | summarize rt_fails = countIf(is_realtime and job_result != "SUCCESS"),
                      rt_oks = countIf(is_realtime and job_result == "SUCCESS"),
                      functional_runs = countIf(not is_realtime),
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
        value = "Prod_Life_Compass_RealTimeAndFunctionalCheck_NG"
      }
      property {
        key   = "event.description"
        value = "Compass Real Time check is NG (2+ non-SUCCESS results, no SUCCESS, last 2 hours). See name, rt_fails and remarks on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Compass"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
