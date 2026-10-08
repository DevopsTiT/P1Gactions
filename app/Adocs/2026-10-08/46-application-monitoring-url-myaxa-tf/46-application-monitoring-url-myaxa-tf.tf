# Splunk: Application Monitoring Alert - URL for MyAXA
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]"
#   | eval name=replace(source,"job/",""), name=replace(name,"%20"," "), name=replace(name,"/\d+/console","")
#   | eval build_url=replace(source,"/console","")
#   | lookup configuration job_name as name OUTPUT application, job_name | where isnotnull(job_name)
#   | sort name, -_time | streamstats count as index by name | where index<=2     <- newest 2 runs per job
#   | stats ... list(job_result) as job_results ... by application, name
#   | eval status=if(mvcount(mvfilter(match(job_results,"OK")))>0,"OK","NG"), event=mvcount(job_results), type="URL"
#   | check_maintenance_window | add_alert_info | search event=2 OR (status="OK" AND prev_status="NG")
#   cron */1, Last 15 minutes, Expires 24h, results > 0, For each result, no throttle
#   Action: Alert Status Manager, email Production, PagerDuty ENABLE (URL and recipients not copied)
#
# Same dead sourcetype as seq 45: index=jenkins_console has no "text:jenkins", so this Splunk alert
#   has never matched and has never paged. The detector is created with enabled = false.
#
# Differences from "Application Monitoring Alert - URL" (seq 44/45):
#   - OK/NG comes from job_result containing "OK", not from HTTP status 200
#   - Splunk shows "event=2" (both of the last 2 runs present) for NG
#   - PagerDuty Enable -> pagerduty.enabled = "1"
#
# The Splunk search has NO application filter despite the "for MyAXA" title. Because this one pages,
#   the detector adds  filter cfg.application == "MyAXA"  so it cannot page for every app.
#   Remove that line only if the team confirms the alert should cover all apps.
#
# CONFIRM before enabling (check.dql):
#   1. "[HTTP Monitor]" lines exist and carry job_result (parse expects "job_result=<WORD>")
#   2. Which MyAXA jobs would fire right now (query 3)
#   3. The configuration application value is exactly "MyAXA"

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "application_monitoring_alert_url_myaxa" {
  title       = "Application Monitoring Alert - URL for MyAXA"
  description = "MyAXA URL check (Jenkins HTTP Monitor) had no OK result in its last runs: 2 or more non-OK results in 15 minutes with no OK. One problem per job."
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-15m
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "[HTTP Monitor]")
          | parse content, "LD 'job_result=' WORD:job_result"
          | filter isNotNull(job_result)
          | fieldsAdd src = toString(log.source)
          | fieldsAdd name = replaceString(replaceString(src, "job/", ""), "%20", " ")
          | fieldsAdd name = replacePattern(name, "'/' INT '/console' EOS", "")
          | fieldsAdd build_url = replaceString(src, "/console", "")
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, job_name }
          | filter isNotNull(cfg.job_name)
          | filter cfg.application == "MyAXA"
          | fieldsAdd application = cfg.application
          | fieldsAdd is_ok = contains(job_result, "OK")
          | sort timestamp asc
          | summarize fails = countIf(not is_ok),
                      oks = countIf(is_ok),
                      job_results = collectArray(job_result),
                      last_build = takeLast(build_url),
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
        value = "Application Monitoring Alert - URL for MyAXA"
      }
      property {
        key   = "event.description"
        value = "MyAXA URL check is NG: no OK result in the last runs (2+ non-OK in 15 minutes). See name, job_results and last_build on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "MyAXA"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
