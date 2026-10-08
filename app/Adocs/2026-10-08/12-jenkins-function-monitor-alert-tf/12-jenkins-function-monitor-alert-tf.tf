# Splunk: Application Monitoring Alert - function
#   index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)
#   | where isnotnull(job_duration)
#   | join build_url [ console "Application is in maintenance" → remarks ]
#   | testname from "Building <name>" or metadata.YAML name
#   | lookup configuration job_name as name OUTPUT application, pager_duty | where pager_duty="0"
#   | streamstats count by job_name | where index<=2            (last 2 runs per job)
#   | status = OK if any job result is SUCCESS, else NG
#   | check_maintenance_window | add_alert_info
#   | search event > 0 OR (status="OK" AND prev_status="NG")
#   cron */1, Last 120 minutes, results > 0
#   Action: Alert Status Manager, email Production, PagerDuty Notification Disable
#
# Dynatrace: one problem per application + job.
#   Opens when the job failed 2+ times in the last 120 minutes with no SUCCESS. Closes on the first SUCCESS.
#   Only pager_duty = 0 applications (the generic alert); the per-app "function for X" alerts cover the rest.
#
# CONFIRM before apply (check.dql):
#   1. jenkins_statistics events reach Dynatrace and which log.source they use (query 1)
#   2. JSON keys job_name, job_result, job_duration in content (query 2)
#   3. /lookups/jenkins/configuration uploaded (job_name, application, pager_duty)
#   4. group-jobs (Real Time functional) report per test, not job_result: query 3
#   5. Macros check_maintenance_window and add_alert_info: definitions needed; not migrated

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "jenkins_function_monitor" {
  title       = "Application Monitoring Alert - function"
  description = "Jenkins functional job failed 2 or more times in the last 120 minutes with no SUCCESS. Applications with pager_duty = 0. One problem per application and job."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-120m
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "job_name")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), job_duration = j[job_duration]
          | filter matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")
          | filter isNotNull(job_duration)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:job_name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter toString(cfg.pager_duty) == "0"
          | fieldsAdd application = coalesce(cfg.application, "-")
          | summarize fails = countIf(job_result != "SUCCESS"), oks = countIf(job_result == "SUCCESS"),
                      last_result = takeLast(job_result), last_seen = max(timestamp),
                      by:{ application, job_name }
          | filter fails >= 2 and oks == 0
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "application"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
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
        value = "Application Monitoring Alert - function"
      }
      property {
        key   = "event.description"
        value = "A Jenkins functional check failed twice or more with no SUCCESS in the last 120 minutes. See application and job_name on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Jenkins Functional Monitor"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
