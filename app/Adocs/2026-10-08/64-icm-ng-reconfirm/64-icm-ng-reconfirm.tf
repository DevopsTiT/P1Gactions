# Splunk: Prod_Life_ICM_RealTimeAndFunctionalCheck_NG
#   Same jenkins_statistics template as FCR (2026-10-08 seq 26), except:
#     | where application="Claims ICM"
#   index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)
#   | where isnotnull(job_duration) | rex tempname from "Building ...", remarks "OKメンテナンス中"
#   | applications/ = Functional, group-jobs = Real Time; job_name = tempname with " » " -> "/"
#   | lookup configuration -> application | streamstats ... where index<=2 (last 2 runs)
#   | status OK if any SUCCESS, else NG | check_maintenance_window | add_alert_info
#   | search event > 0 OR (status="OK" AND prev_status="NG")
#   cron */3, Last 2 hours, Expires 24h, results > 0, For each result, no throttle
#   Actions: "Add to Triggered Alerts" with Severity Medium, AND Alert Status Manager
#            (Alert Status Manager email mode and PagerDuty setting are below the visible area)
#
# Seq 40 corrects seq 30: seq 30 said Triggered Alerts was the only action. There is also an
#   Alert Status Manager, so the team is notified. Same resource name -> in-place update.
#   Apply from ONE folder only (30 or 40).
#
# Seq 64 = seq 40 unchanged. The new screenshot (title cut off) shows the same tail
#   (test_result from teststatus "PASSED", type "Functionally", search event > 0 OR OK-after-NG),
#   cron */3, Last 2 hours, Expires 24h, Triggered Alerts Medium + Alert Status Manager.
#   PagerDuty is still below the visible area, so pagerduty.enabled stays "0" until confirmed.
#
# Dynatrace: one problem per application + name (project).
#   Opens when the Real Time (group-jobs) run returned 2+ non-SUCCESS results in 2 hours with no SUCCESS.
#   Closes on the first SUCCESS. remarks shows "OKメンテナンス中" if a run was in maintenance.
#
# Severity medium = the Severity Splunk sets on the triggered alert.
#
# CONFIRM before apply (check.dql):
#   1. PagerDuty Enable or Disable on the Alert Status Manager; set pagerduty.enabled
#   2. /lookups/jenkins/configuration has rows with application "Claims ICM" (exact spelling, with the space)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "icm_realtime_functional_ng" {
  title       = "Prod_Life_ICM_RealTimeAndFunctionalCheck_NG"
  description = "Claims ICM Real Time check returned 2 or more non-SUCCESS results in the last 2 hours with no SUCCESS. One problem per project."
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
          | filter contains(content, "job_duration")
          | filter not contains(content, "audit_trail")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), job_duration = j[job_duration]
          | filter matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")
          | filter isNotNull(job_duration)
          | parse content, "LD '\"name\":\"Building ' LD:tempname '\"'"
          | fieldsAdd is_realtime = matchesValue(job_name, "group-jobs*")
          | fieldsAdd name = if(isNotNull(tempname), replaceString(tempname, " » ", "/"), else: job_name)
          | fieldsAdd remark = if(contains(content, "OKメンテナンス中"), "OKメンテナンス中")
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter cfg.application == "Claims ICM"
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
        value = "Prod_Life_ICM_RealTimeAndFunctionalCheck_NG"
      }
      property {
        key   = "event.description"
        value = "Claims ICM Real Time check is NG (2+ non-SUCCESS results, no SUCCESS, last 2 hours). See name, rt_fails and remarks on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Claims ICM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
