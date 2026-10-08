# Splunk: HTTP Response Check Outlier
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]" job_name="HTTP Monitor - AGGW LB"
#   | eval duration=replace(duration,"s","")
#   | timechart span=10m max(duration) as responsetime | head 1000
#   | streamstats window=200 median(responsetime) as median | absDev=abs(responsetime-median)
#   | streamstats window=200 median(absDev) as medianAbsDev
#   | lowerBound = median - medianAbsDev*20, upperBound = median + medianAbsDev*20
#   | isOutlier = responsetime outside the bounds (computed twice, same result)
#   | head 1 | search isOutlier="1"
#   cron */10, Last 24 hours, results > 0, Once
#   Action: Send email to one person, Priority Normal, Subject "[TEST] Splunk Alert: $name$ ..."
#
# Findings:
#   1. sourcetype "text:jenkins" does not exist in jenkins_console (seq 45) -> alert never matches
#   2. Subject says [TEST] and it mails one person -> it was an experiment, not on-call alerting
#   3. "head 1" after timechart keeps the OLDEST 10-minute bucket (timechart sorts oldest first),
#      so even with data it judged the bucket from 24 hours ago, not the latest one
#
# Recommendation: do not migrate as a real alert. This tf is an optional, corrected version
#   (judges the LATEST bucket) created with enabled = false, severity low, no paging.
#
# Logic here: 10-minute buckets of max response time over 24 hours,
#   median and MAD (median absolute deviation) over all buckets,
#   problem when the newest bucket is outside median +/- 20 * MAD.
#
# CONFIRM before enabling (check.dql):
#   1. "[HTTP Monitor]" lines for "HTTP Monitor - AGGW LB" exist and carry "duration=<n>s"
#   2. Which field holds the job name (log.source path with %20, or a job_name in the text)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "http_response_check_outlier" {
  title       = "HTTP Response Check Outlier (AGGW LB)"
  description = "Newest 10-minute max response time of HTTP Monitor - AGGW LB is outside median +/- 20 x MAD over the last 24 hours."
  enabled     = false
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter matchesValue(host.name, "ceaa2099*")
          | filter contains(content, "[HTTP Monitor]")
          | filter contains(replaceString(toString(log.source), "%20", " "), "HTTP Monitor - AGGW LB")
          | parse content, "LD 'duration=' DOUBLE:duration"
          | filter isNotNull(duration)
          | fieldsAdd bucket = bin(timestamp, 10m)
          | summarize responsetime = max(duration), by:{ bucket }
          | sort bucket asc
          | summarize med = median(responsetime),
                      latest_bucket = takeLast(bucket),
                      latest = takeLast(responsetime),
                      buckets = collectArray(responsetime)
          | expand buckets
          | fieldsAdd absdev = abs(buckets - med)
          | summarize mad = median(absdev),
                      med = takeAny(med),
                      latest = takeAny(latest),
                      latest_bucket = takeAny(latest_bucket)
          | fieldsAdd lowerBound = med - mad * 20, upperBound = med + mad * 20
          | filter mad > 0 and (latest < lowerBound or latest > upperBound)
          | fieldsAdd check = "http_response_check_outlier_aggw_lb"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "check"
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
        value = "HTTP Response Check Outlier (AGGW LB)"
      }
      property {
        key   = "event.description"
        value = "AGGW LB response time outlier: newest 10-minute max is outside median +/- 20 x MAD (24h). See latest, med, lowerBound and upperBound on the problem."
      }
      property {
        key   = "alert.severity"
        value = "low"
      }
      property {
        key   = "app.name"
        value = "AGGW LB"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
