# Splunk: Prod_Life_CCIGoalManagement_URLCheck_NG
#   index="jenkins" source="jenkins/test" job_result!=ABORTED job_name="*Management*"
#   | eval name=replace(source,"job/",""), name=replace(name,"%20"," "), name=replace(name,"/\d+/console","")
#   | eval build_url=replace(source,"/console","")
#   | rename status as responsecode
#   | lookup configuration job_name as name OUTPUT application, job_name | fields - job_name | fillnull application value="-"
#   | streamstats count as index by name | where index<=2
#   | stats ... values(responsecode) as Response_Code by application, name
#   | eval status=if(Response_Code="200","OK","NG"), type="URL"
#   | check_maintenance_window | add_alert_info | search status="NG" OR (status="OK" AND prev_status="NG")
#   cron */1, Last 24 hours, Expires 24h, results > 0, Once, For each result, no throttle
#   Action: Add to Triggered Alerts + Alert Status Manager, email Production, PagerDuty Disable
#   (recipients and PagerDuty URL not copied)
#
# Finding: the search is the jenkins_console URL template pointed at index=jenkins source=jenkins/test.
#   1. source is always "jenkins/test" here, so name = "jenkins/test" for every job (no job/.../console path)
#   2. the lookup on "jenkins/test" matches nothing, so application = "-" (there is no where isnotnull(job_name))
#   3. build_report events have no "status" field, so Response_Code is empty and status is always "NG"
#   -> one row (application "-", name "jenkins/test") that is NG forever, whatever the jobs do.
#   Alert Status Manager most likely sent one NG long ago and never a recovery.
#
# Dynatrace: rebuilt on what the data actually has: build_report job_result per job.
#   One problem per job whose name contains "management" (Splunk wildcard match is case-insensitive)
#   when it returned 2+ non-SUCCESS results in 60 minutes with no SUCCESS. Closes on the first SUCCESS.
#   enabled = false: this is new logic, not a copy. Turn it on after check.dql query 1 lists the expected jobs.
#
# CONFIRM before enabling (check.dql):
#   1. Which jobs match "management" (narrow the filter to the CCI Goal Management job if others match)
#   2. Each matched job runs at least twice per 60 minutes; if not, widen the window
#   3. Splunk scheduler history (spl line 3): result_count 1 on every run proves the stuck-NG finding

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "cci_goal_management_url_check_ng" {
  title       = "Prod_Life_CCIGoalManagement_URLCheck_NG"
  description = "CCI Goal Management URL check job returned 2 or more non-SUCCESS results in the last 60 minutes with no SUCCESS. One problem per job."
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-60m
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "build_report")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), build_url = toString(j[build_url])
          | filter isNotNull(job_name) and contains(lower(job_name), "management")
          | filter job_result != "ABORTED"
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:job_name, lookupField:job_name, prefix:"cfg.", fields:{ application }
          | fieldsAdd application = coalesce(cfg.application, "-")
          | sort timestamp asc
          | summarize fails = countIf(job_result != "SUCCESS"),
                      oks = countIf(job_result == "SUCCESS"),
                      application = takeAny(application),
                      job_results = collectDistinct(job_result),
                      last_build = takeLast(build_url),
                      last_seen = max(timestamp),
                      by:{ job_name }
          | filter fails >= 2 and oks == 0
          | fieldsAdd type = "URL"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_name"
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
        value = "Prod_Life_CCIGoalManagement_URLCheck_NG"
      }
      property {
        key   = "event.description"
        value = "CCI Goal Management URL check is NG: 2+ non-SUCCESS results, no SUCCESS, last 60 minutes. See job_name, job_results and last_build on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "CCI Goal Management"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
