# Splunk: Prod_Life_HPM_RealTimeAndFunctionalCheck_NG
#   Same search as Prod_Life_HPM_Owner_Portal_RealTimeAndFunctionalCheck_NG (2026-10-08 seq 27), including
#   where application="HPM_Owner_Portal". Differences: cron "0 * * * *" (hourly at :00), Expires 1 hour.
#   Trigger actions were not visible in the screenshot.
#
# Recommendation: do not migrate. The seq 27 detector hpm_owner_portal_realtime_functional_ng already checks
# the same jobs every minute and keeps one problem open until SUCCESS, which covers the hourly reminder.
# This file is only for the case where the team needs a separate, differently routed detector.
# It is created disabled so it never double-alerts by accident. Place it next to the seq 27 files
# (which hold the provider block) if you decide to keep it.

resource "dynatrace_davis_anomaly_detectors" "hpm_hourly_realtime_functional_ng" {
  title       = "Prod_Life_HPM_RealTimeAndFunctionalCheck_NG"
  description = "Hourly copy of the HPM Owner Portal Jenkins NG check. Disabled: seq 27 detector covers the same jobs every minute."
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-2h
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
          | filter cfg.application == "HPM_Owner_Portal"
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
        value = "Prod_Life_HPM_RealTimeAndFunctionalCheck_NG"
      }
      property {
        key   = "event.description"
        value = "HPM Owner Portal Jenkins check is NG (2+ non-SUCCESS results, no SUCCESS, last 2 hours). Hourly copy."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "HPM_Owner_Portal"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
