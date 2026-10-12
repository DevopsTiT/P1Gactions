terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: index="controlm*" [| inputlookup claims_jobs | table job_name]
#   | eval elapsed = minutes since start_time
#   | stats latest(starttime), latest(end_time), latest(elapsed) by job_name
#   | where isnull(endtime) | where elapsed >= 15
# Last 24 hours, cron every 5 minutes, more than 0 results, email.
#
# Dynatrace version uses the Control-M agent daily log
#   /opt/ctmhlx/ctm/dailylog/daily_ctmag_YYYYMMDD.log
#   "JOB DYDB033A (ORDERID 31777, RUNNO 00001) STARTED (3867048), OWNER ..."
#   "JOB DYDB033A (ORDERID 31777, RUNNO 00001) EXECUTION ENDED"
# A run is over-running when it has STARTED, has no ENDED line, and started 15+ minutes ago.
#
# claims_jobs: replace the placeholder names in claims_jobs with the job names
# from the Splunk lookup (| inputlookup claims_jobs).
resource "dynatrace_davis_anomaly_detectors" "claim_job_over_run" {
  title       = "Claim Job Over Run Alert"
  description = "A claims Control-M job started 15 or more minutes ago and has not ended. One problem per job_name."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-24h
          | filter contains(log.source, "daily_ctmag_", caseSensitive:false)
          | filter contains(content, ") STARTED (") or contains(content, ") EXECUTION ENDED")
              or contains(content, ") ENDED OK") or contains(content, ") ENDED NOTOK")
          | parse content, "LD 'JOB ' NSPACE:job_name SPACE '(ORDERID ' INT:order_id ', RUNNO ' INT:run_no ')'"
          | fieldsAdd claims_jobs = array("CLAIMJOB01", "CLAIMJOB02")
          | filter in(job_name, claims_jobs)
          | fieldsAdd is_start = contains(content, ") STARTED ("),
                      is_end = contains(content, " ENDED")
          | summarize started = min(if(is_start, timestamp)),
                      ended = max(if(is_end, timestamp)),
                      host = takeFirst(host.name),
                      by:{ job_name, order_id, run_no }
          | filter isNotNull(started) and isNull(ended)
          | fieldsAdd elapsed_min = toLong((now() - started) / 1m),
                      starttime = formatTimestamp(started, format:"yyyy/MM/dd HH:mm:ss", timezone:"Asia/Tokyo")
          | filter elapsed_min >= 15
          | fields job_name, order_id, run_no, starttime, elapsed_min, host
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
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
        value = "Claim job over run"
      }
      property {
        key   = "event.description"
        value = "A claims Control-M job has been running 15 minutes or more without an ENDED line. See job_name, starttime and elapsed_min on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "claims"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
