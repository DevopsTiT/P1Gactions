# Splunk: Prod_Life_Emma_MyAXAUserRegistrationBatchStatus_Normal
#   Description: This is an alert to detect issues regarding the emma registration batch
#   index=controlm_temp sourcetype=controlm_activejobs job_name=CHDR010M
#   | dedup job_name                                   (latest CHDR010M record in the time range)
#   | StartTime / EndTime = MM/dd HH:mm:ss from start_time / end_time (yyyyMMddHHmmss)
#   | table job_name status StartTime EndTime
#   Run every day at 6:00, Expires 24h, results > 0, Once, For each result, no throttle
#   Actions: Add to Triggered Alerts, Send email (Priority Normal, recipients not copied)
#
# Splunk mails the latest status every morning, OK or not.
# Dynatrace: one problem only when the latest CHDR010M record is NOT Ended OK.
#   Time gate: judged from 06:00 JST every day, like the Splunk schedule.
#   Identity job_name + odate: one problem per order date; it closes when a rerun ends OK or the record ages out.
#
# Replaces 2026-10-07 seq 14 controlm_alerts["chdr010m_no_success"]; remove that key if applied.
# Also covers 2026-10-05 seq 31 "CHDR010MJob Status for MyAXA User Registration Batch" (same job, same 06:00).
#
# CONFIRM before apply (check.dql):
#   1. The Splunk time range is not visible on the screenshot. 1 day is assumed (query 1 shows run times).
#   2. start_time / end_time are 14 digits and odate exists on CHDR010M rows (query 2)
#   3. Severity: Triggered Alerts severity is not visible; email priority Normal → medium

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

resource "dynatrace_davis_anomaly_detectors" "chdr010m_emma_user_registration_status" {
  title       = "Prod_Life_Emma_MyAXAUserRegistrationBatchStatus_Normal"
  description = "Control-M job CHDR010M (emma MyAXA user registration batch): latest run in the last day is not Ended OK. Checked every day from 06:00 JST."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1d
          | filter matchesValue(log.source, "*controlm_activejobs*")
          | filter job_name == "CHDR010M"
          | filter formatTimestamp(now(), format:"HHmm", timezone:"Asia/Tokyo") >= "0600"
          | sort timestamp asc
          | summarize status = takeLast(status), start_time = takeLast(start_time), end_time = takeLast(end_time),
                      odate = takeLast(odate), last_seen = max(timestamp), by:{ job_name }
          | filter status != "Ended OK"
          | fieldsAdd StartTime = concat(substring(start_time, from:4, to:6), "/", substring(start_time, from:6, to:8), " ",
                                         substring(start_time, from:8, to:10), ":", substring(start_time, from:10, to:12), ":", substring(start_time, from:12, to:14))
          | fieldsAdd EndTime = concat(substring(end_time, from:4, to:6), "/", substring(end_time, from:6, to:8), " ",
                                       substring(end_time, from:8, to:10), ":", substring(end_time, from:10, to:12), ":", substring(end_time, from:12, to:14))
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "job_name"
      }
      analyzer_input_field {
        key   = "alertIdentityFields[1]"
        value = "odate"
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
        value = "Prod_Life_Emma_MyAXAUserRegistrationBatchStatus_Normal"
      }
      property {
        key   = "event.description"
        value = "The emma registration batch (Control-M CHDR010M) has not Ended OK. Check job_name, status, StartTime and EndTime on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "MyAXA emma"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
