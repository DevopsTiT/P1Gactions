# Splunk: Application Monitoring Alert - function
#   index=jenkins_statistics sourcetype="json:jenkins:old" (job_name=applications* OR job_name=group-jobs*)
#   | where isnotnull(job_duration)
#   | join type=left build_url [ search index=jenkins_console source="job/applications/job/*" "Application is in mantenance"
#                               | rex field=source "(?P<build_url>.*)console" | stats values(_raw) as remarks by build_url ]
#   | rex tempname from "Building ..." | eval job_result=if(match(job_name,"group-jobs"),"",job_result)   <- Real Time results emptied
#   | lookup configuration job_name as name OUTPUT application, pager_duty
#   | where pager_duty="0"                                                                                <- every non-PagerDuty app
#   | streamstats ... where index<=2 (last 2 runs) | status OK if any SUCCESS, else NG
#   | check_maintenance_window | add_alert_info | search event > 0 OR (status="OK" AND prev_status="NG")
#   cron */1, Last 120 minutes, Expires 24h, results > 0, For each result, no throttle
#   Action: Alert Status Manager, email Production
#
# Differences from the per-app jenkins_statistics detectors (seq 26, 30-33):
#   1. Counts FUNCTIONAL (applications*) results, not Real Time (group-jobs*) results
#   2. No application filter: every app whose configuration pager_duty is "0"
#   3. Maintenance note comes from jenkins_console "Application is in mantenance" (Splunk's spelling), joined on build_url
#
# Dynatrace: one problem per application + name.
#   Opens when a Functional job returned 2+ non-SUCCESS results in 2 hours with no SUCCESS.
#   in_maintenance > 0 means at least one failing build printed the maintenance message (shown, not filtered, like Splunk).
#   pagerduty "0" by definition: this alert only covers apps with pager_duty = 0.
#
# CONFIRM before apply (check.dql):
#   1. jenkins_statistics events carry build_url (query 1)
#   2. jenkins_console lines reach Grail and which field holds "job/.../console" (query 2)
#   3. Apps with pager_duty "0" in the lookup (query 3)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "application_monitoring_alert_function" {
  title       = "Application Monitoring Alert - function"
  description = "Functional Jenkins check for a non-PagerDuty application returned 2 or more non-SUCCESS results in the last 2 hours with no SUCCESS. One problem per application and job."
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
          | filter contains(content, "job_duration")
          | filter not contains(content, "audit_trail")
          | parse content, "JSON:j"
          | fieldsAdd job_name = toString(j[job_name]), job_result = toString(j[job_result]), job_duration = j[job_duration], build_url = toString(j[build_url])
          | filter matchesValue(job_name, "applications*") or matchesValue(job_name, "group-jobs*")
          | filter isNotNull(job_duration)
          | lookup [
              fetch logs, from:now()-120m
              | filter contains(content, "Application is in mantenance")
              | fieldsAdd src = toString(coalesce(log.source, source))
              | filter contains(src, "job/applications/job/") and contains(src, "console")
              | fieldsAdd build_url = substring(src, from:0, to:indexOf(src, "console"))
              | summarize maintenance_note = takeLast(content), by:{ build_url }
            ], sourceField:build_url, lookupField:build_url, prefix:"mnt.", fields:{ maintenance_note }
          | parse content, "LD '\"name\":\"Building ' LD:tempname '\"'"
          | fieldsAdd is_realtime = matchesValue(job_name, "group-jobs*")
          | fieldsAdd name = if(isNotNull(tempname), replaceString(tempname, " » ", "/"), else: job_name)
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
          | filter toString(cfg.pager_duty) == "0"
          | fieldsAdd application = coalesce(cfg.application, "-")
          | summarize fn_fails = countIf(not is_realtime and job_result != "SUCCESS"),
                      fn_oks = countIf(not is_realtime and job_result == "SUCCESS"),
                      realtime_runs = countIf(is_realtime),
                      in_maintenance = countIf(isNotNull(mnt.maintenance_note)),
                      remarks = collectDistinct(mnt.maintenance_note),
                      last_seen = max(timestamp),
                      by:{ application, name }
          | filter fn_fails >= 2 and fn_oks == 0
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
        value = "Application Monitoring Alert - function"
      }
      property {
        key   = "event.description"
        value = "Functional check is NG (2+ non-SUCCESS results, no SUCCESS, last 2 hours) for a non-PagerDuty application. See application, name, fn_fails and remarks (maintenance note) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
