# Splunk saved search (report, not an alert): Application Incident Analysis
#   | inputlookup monitor_logs
#   | eval ctime=strftime(time,"%Y-%m-%d") | eval yesterday=strftime(relative_time(now(),"-1d@d"),"%Y-%m-%d")
#   | where ctime = yesterday
#   | stats count(eval(status="OK")) as OK, count(eval(status="NG")) as NG,
#           count(eval(isMaintenance="true")) as Maintenance by ctime application
#   | collect index=monitoring_summary_idx sourcetype=application_summary
#   Runs about 01:00 daily, writes 1 row per application (46 rows on 10/8) into a summary index.
#   No email, no PagerDuty → no detector. Dynatrace equivalent: a dashboard that queries live data.
#
# CONFIRM before apply:
#   1. Where monitor_logs comes from (Splunk searches that outputlookup to it). See the .md.
#   2. /lookups/monitor_logs uploaded to Grail, or replace the load with the real log source.
#   3. Dashboard content format: export any dashboard from the UI (Download JSON) and compare "version".

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

locals {
  app_incident_daily_query = <<-EOT
    load "/lookups/monitor_logs"
    | fieldsAdd ctime = formatTimestamp(timestampFromUnixSeconds(toLong(time)), format:"yyyy-MM-dd", timezone:"Asia/Tokyo")
    | filter ctime == formatTimestamp(now() - 1d, format:"yyyy-MM-dd", timezone:"Asia/Tokyo")
    | summarize OK = countIf(status == "OK"),
                NG = countIf(status == "NG"),
                Maintenance = countIf(isMaintenance == "true"),
                by:{ ctime, application }
    | sort NG desc, application asc
  EOT

  app_incident_30d_query = <<-EOT
    load "/lookups/monitor_logs"
    | fieldsAdd ctime = formatTimestamp(timestampFromUnixSeconds(toLong(time)), format:"yyyy-MM-dd", timezone:"Asia/Tokyo")
    | filter timestampFromUnixSeconds(toLong(time)) >= now() - 30d
    | summarize NG = countIf(status == "NG"), by:{ ctime, application }
    | filter NG > 0
    | sort ctime desc, NG desc
  EOT
}

resource "dynatrace_document" "application_incident_analysis" {
  type = "dashboard"
  name = "Application Incident Analysis"
  content = jsonencode({
    version   = 15
    variables = []
    tiles = {
      "0" = {
        type          = "data"
        title         = "Yesterday: OK, NG and Maintenance per application"
        query         = local.app_incident_daily_query
        visualization = "table"
      }
      "1" = {
        type          = "data"
        title         = "Last 30 days: applications with NG"
        query         = local.app_incident_30d_query
        visualization = "table"
      }
    }
    layouts = {
      "0" = { x = 0, y = 0, w = 24, h = 10 }
      "1" = { x = 0, y = 10, w = 24, h = 10 }
    }
  })
}
