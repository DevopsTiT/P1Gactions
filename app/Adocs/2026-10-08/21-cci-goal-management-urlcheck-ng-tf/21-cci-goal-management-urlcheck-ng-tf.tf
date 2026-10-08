# Splunk: Prod_Life_CCIGoalManagement_URLCheck_NG
#   index="jenkins" source="jenkins/test" job_result!=ABORTED job_name="*Management*"
#   | name = source without "job/", "%20" -> " ", no "/<build>/console"; build_url = source without "/console"
#   | rename status as responsecode
#   | lookup jenkins.main.url, lookup configuration job_name as name OUTPUT application, job_name
#   | sort name, -_time | streamstats count as index by name | where index<=2            (last 2 runs)
#   | add_alert_info | where time>prev_time OR isnull(prev_time)
#   | stats ... values(responsecode) as Response_Code by application, name
#   | status = OK if Response_Code has "200", else NG; type = "URL"
#   | check_maintenance_window | add_alert_info | search status="NG" OR (status="OK" AND prev_status="NG")
#   cron */1, Last 24 hours, results > 0, Once, no throttle
#   Actions: Add to Triggered Alerts; Alert Status Manager, email Production, PagerDuty Notification Disable
#
# Dynatrace: one problem per application + name.
#   Opens when the URL check returned 2+ non-200 responses and no 200 in the last 30 minutes
#   (Splunk "last 2 runs, none 200"). Closes on the first 200 (replaces the recovery mail).
#   Window: Splunk reads 24 hours but only uses the last 2 runs; 30 minutes assumes runs every few minutes.
#   If the job runs less often, widen from:now()-30m to about 2 run intervals.
#
# CONFIRM before apply (check.dql):
#   1. job_name values containing "Management" and the response code key (status) (query 1)
#   2. /lookups/jenkins/configuration row for the job, application name (query 2)
#   3. Run interval of the URL check job (query 3)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "cci_goal_management_urlcheck_ng" {
  title       = "Prod_Life_CCIGoalManagement_URLCheck_NG"
  description = "CCI Goal Management URL check returned 2 or more non-200 responses and no 200 in the last 30 minutes. One problem per application and job."
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
          | filter contains(content, "Management")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), responsecode = toString(j[status])
          | filter contains(job_name, "Management")
          | filter job_result != "ABORTED"
          | fieldsAdd name = replaceString(replaceString(job_name, "job/", ""), "%20", " ")
          | fieldsAdd name = if(endsWith(name, "/"), substring(name, from:0, to:stringLength(name) - 1), else: name)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application }
          | fieldsAdd application = coalesce(cfg.application, "-")
          | summarize fails = countIf(responsecode != "200"),
                      oks = countIf(responsecode == "200"),
                      Response_Code = collectDistinct(responsecode),
                      last_seen = max(timestamp),
                      by:{ application, name }
          | filter fails >= 2 and oks == 0
          | fieldsAdd type = "URL"
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
        value = "Prod_Life_CCIGoalManagement_URLCheck_NG"
      }
      property {
        key   = "event.description"
        value = "CCI Goal Management URL check is NG: no HTTP 200 in the last 2 or more runs (30 minutes). See name and Response_Code on the problem."
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
