# Splunk: Application Monitoring Alert - URL
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]"
#   | name = source without "job/", "%20" → " ", and without "/<build>/console"
#   | rename status as responsecode
#   | lookup configuration job_name as name OUTPUT application, job_name
#   | streamstats count as index by name | where index<=2        (last 2 runs per URL check)
#   | stats ... values(responsecode) as Response_Code by application, name
#   | eval status=if(Response_Code="200","OK","NG"), event=mvcount(job_results)
#   | check_maintenance_window | add_alert_info
#   | search status="NG" OR (status="OK" AND prev_status="NG")    (alert, then recovery)
#   cron */1, Last 15 minutes
#   Jenkins server is fixed: ceaa2099.prprivmgmt.intraxa (host filter added)
#
# Dynatrace: one problem per application + URL check.
#   Opens when the check failed 2+ times in the last 15 minutes with no 200 response.
#   Closes on the first 200 response (that replaces the Splunk recovery email).
#   Two keys only to split paging: configuration.pager_duty = 0 → no PagerDuty.
#
# CONFIRM before apply (check.dql):
#   1. log.source format for jenkins console lines (query 1)
#   2. where the HTTP status sits in the "[HTTP Monitor]" line (query 2)
#   3. /lookups/jenkins/configuration uploaded (job_name, application, pager_duty) (query 3)
#   4. Macros check_maintenance_window and add_alert_info: ask for definitions; not migrated

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  jenkins_url_base_query = <<-EOT
    fetch logs, from:now()-15m
    | filter matchesValue(host.name, "ceaa2099*")
    | filter contains(log.source, "/console")
    | filter contains(content, "[HTTP Monitor]")
    | fieldsAdd src = replaceString(replaceString(log.source, "job/", ""), "%20", " ")
    | parse src, "LD:name '/' INT '/console'"
    | parse content, "LD 'status' LD INT:responsecode"
    | lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
    | fieldsAdd application = coalesce(cfg.application, "-"), pager_duty = coalesce(toString(cfg.pager_duty), "1")
    | summarize fails = countIf(responsecode != 200), oks = countIf(responsecode == 200),
                last_code = takeLast(responsecode), last_seen = max(timestamp),
                by:{ application, name, pager_duty }
    | filter fails >= 2 and oks == 0
  EOT

  jenkins_url_alerts = {
    page = {
      title     = "Application Monitoring Alert - URL"
      filter    = "pager_duty != \"0\""
      pagerduty = "1"
    }
    no_page = {
      title     = "Application Monitoring Alert - URL (no PagerDuty)"
      filter    = "pager_duty == \"0\""
      pagerduty = "0"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "jenkins_url_monitor" {
  for_each = local.jenkins_url_alerts

  title       = each.value.title
  description = "Jenkins HTTP Monitor URL check failed 2 or more times in the last 15 minutes with no 200 response. One problem per application and check."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = "${local.jenkins_url_base_query}| filter ${each.value.filter}\n"
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
        value = each.value.title
      }
      property {
        key   = "event.description"
        value = "A Jenkins HTTP Monitor URL check failed twice or more with no successful response in the last 15 minutes. See application and name on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "Jenkins URL Monitor"
      }
      property {
        key   = "pagerduty.enabled"
        value = each.value.pagerduty
      }
    }
  }

  execution_settings {}
}
