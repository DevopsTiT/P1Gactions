# Splunk: Application Monitoring Alert - URL
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]"
#   | eval name=replace(source,"job/",""), name=replace(name,"%20"," "), name=replace(name,"/\d+/console","")
#   | eval build_url=replace(source,"/console","")
#   | rename status as responsecode
#   | lookup configuration job_name as name OUTPUT application, job_name | where isnotnull(job_name)
#   | streamstats count as index by name | where index<=2          <- newest 2 runs per job
#   | stats ... values(responsecode) as Response_Code by application, name
#   | eval status=if(Response_Code="200","OK","NG"), type="URL"
#   | check_maintenance_window | add_alert_info | search status="NG" OR (status="OK" AND prev_status="NG")
#   cron */1, Last 15 minutes, Expires 24h, results > 0, For each result, no throttle
#   Action: Alert Status Manager, email Production, PagerDuty Disable (recipients not copied)
#
# Dynatrace: one problem per application + name (monitored URL job).
#   Opens when the job's HTTP Monitor returned non-200 at least twice in 15 minutes with no 200.
#   Closes when a 200 comes back (replaces Splunk's "OK after NG" mail).
#   pagerduty "0": Splunk shows PagerDuty Disable.
#
# CONFIRM before apply (check.dql):
#   1. The "[HTTP Monitor]" line format: the parse expects "status=<code>" (query 1 shows real lines)
#   2. Console path field: log.source should look like job/applications/job/.../<build>/console
#   3. Each job runs at least twice per 15 minutes (query 2); if not, widen to from:now()-30m

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "application_monitoring_alert_url" {
  title       = "Application Monitoring Alert - URL"
  description = "Jenkins HTTP Monitor for an application URL returned non-200 at least twice in the last 15 minutes with no 200. One problem per application and job."
  enabled     = true
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
          | parse content, "LD 'status=' INT:responsecode"
          | filter isNotNull(responsecode)
          | fieldsAdd src = toString(log.source)
          | fieldsAdd name = replaceString(replaceString(src, "job/", ""), "%20", " ")
          | fieldsAdd name = replacePattern(name, "'/' INT '/console' EOS", "")
          | fieldsAdd build_url = replaceString(src, "/console", "")
          | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, job_name }
          | filter isNotNull(cfg.job_name)
          | fieldsAdd application = coalesce(cfg.application, "-")
          | fieldsAdd code = toString(responsecode)
          | sort timestamp asc
          | summarize fails = countIf(code != "200"),
                      oks = countIf(code == "200"),
                      Response_Code = collectDistinct(code),
                      last_code = takeLast(code),
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
        value = "Application Monitoring Alert - URL"
      }
      property {
        key   = "event.description"
        value = "Application URL check (Jenkins HTTP Monitor) is NG: non-200 at least twice in 15 minutes, no 200. See application, name, Response_Code and last_build on the problem."
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
