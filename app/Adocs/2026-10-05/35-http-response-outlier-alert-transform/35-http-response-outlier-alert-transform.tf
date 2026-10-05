# Splunk "HTTP Response Check Outlier" → Dynatrace auto-adaptive detector
#
#   index="jenkins_console" sourcetype="text:jenkins" "[HTTP Monitor]" job_name="HTTP Monitor - AGGW LB"
#   | eval duration=replace(duration,"s","")
#   | timechart span=10m max(duration) as responsetime | head 1000
#   | streamstats window=200 median, median absolute deviation (MAD)
#   | outlier if responsetime < median - 20*MAD or > median + 20*MAD
#   | head 1 | search isOutlier=1
#   Last 24 hours, every 10 minutes, email masayuki.yasuda, subject 【TEST】 (a test alert)
#
# Dynatrace: the auto-adaptive analyzer learns the baseline and the normal fluctuation itself,
# which is what the streamstats median and MAD code did by hand. ABOVE only: the analyzer
# supports ABOVE or BELOW, and a faster-than-usual response is not an incident.
#
# CONFIRM before apply:
#   1. log.source for jenkins_console, and how the AGGW LB job is identified   (check.dql 1)
#   2. How duration appears in the line (e.g. "duration=0.532s")             (check.dql 2)

resource "dynatrace_davis_anomaly_detectors" "jenkins_aggw_lb_response_outlier" {
  title       = "Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal"
  description = "HTTP Monitor - AGGW LB response time is far above its learned baseline."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.AutoAdaptiveAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter matchesValue(log.source, "*jenkins*console*")
          | filter contains(content, "[HTTP Monitor]")
          | filter contains(log.source, "HTTP%20Monitor%20-%20AGGW%20LB") or contains(content, "HTTP Monitor - AGGW LB")
          | parse content, "LD 'duration' LD DOUBLE:responsetime 's'"
          | makeTimeseries responsetime = max(responsetime), interval:1m
        EOT
      }
      analyzer_input_field {
        # How many "normal fluctuations" above the baseline count as a violation.
        # Splunk used 20 x MAD, which is very wide; start at 5 and tune with the preview.
        key   = "numberOfSignalFluctuations"
        value = "5"
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = "ABOVE"
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = "5"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "10"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "10"
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
        value = "Prod_Jenkins_AGGWLB_ResponseTimeOutlier_Normal"
      }
      property {
        key   = "event.description"
        value = "HTTP Monitor - AGGW LB response time is far above its learned baseline ({violating_samples} of the last 10 minutes)."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "AGGW LB"
      }
    }
  }

  execution_settings {}
}
