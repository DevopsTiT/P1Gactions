# IWFM-related Splunk alerts -> 3 Dynatrace Records detectors
#
#   1. EIP - IWFM : EIP006 service Failure Alert      -> eip_iwfm_eip006_service_failure
#   2. [Prod]ALJ-Compass-IWFMReportException発生       -> compass_iwfm_report_exception
#   3. IWFM_Errors                                    -> iwfm_errors
#
# Replaces 2026-10-05 seq 32 (static threshold + makeTimeseries, renamed titles).
#   If seq 32 was applied, destroy it first (see 69.sh), or both versions will alert.
#
# pagerduty "0" for all three: the only action is Send email (recipients not copied).
#
# CONFIRM before apply (check.dql):
#   1. EIP006: Status is an attribute or only text in content (query 1)
#   2. Compass: which k8s.namespace.name / log.source holds index compass-prod-axa-li-jp (query 2)
#   3. IWFM: log.source of sourcetype fmwsagentlog and how LOGLEVEL appears (query 3)

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk: EIP - IWFM : EIP006 service Failure Alert
#   Description: checks EIP006 services that depend on backend provider system IWFM
#   index=eip1015 sourcetype=eip_mediator_serverlog jp-Distributing-Sell-GenerateFormImage-v2-vs* Status=FAILURE
#   cron */1, Last 1 minute, Expires 24h, results > 2, Once, For each result, no throttle
#   Action: Send email, Priority High
resource "dynatrace_davis_anomaly_detectors" "eip_iwfm_eip006_service_failure" {
  title       = "EIP - IWFM : EIP006 service Failure Alert"
  description = "EIP006 (jp-Distributing-Sell-GenerateFormImage-v2) logged more than 2 FAILURE results in 1 minute. It depends on the backend system IWFM."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1m
          | filter contains(content, "jp-Distributing-Sell-GenerateFormImage-v2-vs")
          | filter toString(Status) == "FAILURE" or contains(content, "Status=FAILURE")
          | summarize failures = count(), first_seen = min(timestamp), last_seen = max(timestamp)
          | filter failures > 2
          | fieldsAdd check = "eip_iwfm_eip006_service_failure"
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
        value = "EIP - IWFM : EIP006 service Failure Alert"
      }
      property {
        key   = "event.description"
        value = "EIP006 GenerateFormImage returned more than 2 FAILURE results in 1 minute. Check the backend IWFM system. See failures and last_seen on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "EIP IWFM EIP006"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# Splunk: [Prod]ALJ-Compass-IWFMReportException発生
#   index=compass-prod-axa-li-jp "IWFMReportException"
#   cron */5, Last 5 minutes, Expires 1500 days, results > 15, Once, For each result, no throttle
#   Action: Send email, Priority Normal
resource "dynatrace_davis_anomaly_detectors" "compass_iwfm_report_exception" {
  title       = "[Prod]ALJ-Compass-IWFMReportException発生"
  description = "Compass (prod) logged more than 15 IWFMReportException lines in 5 minutes."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(content, "IWFMReportException")
          | summarize exceptions = count(), first_seen = min(timestamp), last_seen = max(timestamp)
          | filter exceptions > 15
          | fieldsAdd check = "compass_iwfm_report_exception"
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
        value = "[Prod]ALJ-Compass-IWFMReportException発生"
      }
      property {
        key   = "event.description"
        value = "Compass (prod) logged more than 15 IWFMReportException lines in 5 minutes. Report generation through IWFM is failing. See exceptions and last_seen on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "Compass"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}

# Splunk: IWFM_Errors
#   index=iwfm sourcetype=fmwsagentlog earliest=-1h (LOGLEVEL="Caution" OR LOGLEVEL="Fatal")
#   | transaction host AGENTID maxspan=1s
#   Run every hour at :15, Expires 24h, results > 0, Once, For each result, throttle 1 hour
#   Action: Send email, Priority Normal
#   transaction only groups lines within 1 second; "> 0" still means "any Caution or Fatal line".
#   The open problem stays open while errors exist in the last hour, which replaces the 1-hour throttle.
resource "dynatrace_davis_anomaly_detectors" "iwfm_errors" {
  title       = "IWFM_Errors"
  description = "IWFM agent (fmwsagentlog) logged LOGLEVEL Caution or Fatal in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter matchesValue(log.source, "*fmwsagentlog*")
          | filter in(toString(LOGLEVEL), {"Caution", "Fatal"}) or contains(content, "Caution") or contains(content, "Fatal")
          | summarize errors = count(), hosts = collectDistinct(host.name), first_seen = min(timestamp), last_seen = max(timestamp)
          | filter errors > 0
          | fieldsAdd check = "iwfm_errors"
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
        value = "IWFM_Errors"
      }
      property {
        key   = "event.description"
        value = "IWFM agent logged Caution or Fatal in the last hour. See hosts, errors and last_seen on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "IWFM"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
