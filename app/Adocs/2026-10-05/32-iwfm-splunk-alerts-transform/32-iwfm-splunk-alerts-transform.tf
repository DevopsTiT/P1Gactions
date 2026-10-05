# IWFM-related Splunk alerts → Dynatrace detectors (3 Splunk alerts → 3 detectors, no workflows)
#
#   EIP - IWFM : EIP006 service Failure Alert      → iwfm_alerts["eip006_service_failure"]
#   [Prod]ALJ-Compass-IWFMReportException発生       → iwfm_alerts["compass_iwfm_report_exception"]
#   IWFM_Errors                                    → iwfm_alerts["iwfm_agent_errors"]
#
# CONFIRM before apply (check.dql query 1 and 2):
#   index=eip1015 sourcetype=eip_mediator_serverlog   → log.source guess "*eip_mediator_serverlog*"
#   index=compass-prod-axa-li-jp                      → k8s.namespace.name guess
#   index=iwfm sourcetype=fmwsagentlog                → log.source guess "*fmwsagentlog*"
#   Status and LOGLEVEL are Splunk field extractions  → may only exist inside content

locals {
  iwfm_alerts = {

    # Splunk: index=eip1015 sourcetype=eip_mediator_serverlog jp-Distributing-Sell-GenerateFormImage-v2-vs* Status=FAILURE
    #   Last 1 minute, every minute, results > 2, High, email alj_jp_dl_infra_mwss
    eip006_service_failure = {
      name        = "Prod_EIP_IWFM_EIP006ServiceFailure_High"
      description = "More than 2 FAILURE results in 1 minute from EIP006 (jp-Distributing-Sell-GenerateFormImage-v2), which depends on the backend IWFM system."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*eip_mediator_serverlog*")
        | filter contains(content, "jp-Distributing-Sell-GenerateFormImage-v2-vs", caseSensitive: false)
        | filter contains(content, "Status=FAILURE", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "2"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=compass-prod-axa-li-jp "IWFMReportException"
    #   Last 5 minutes, every 5 minutes, results > 15, Normal, email compass IT member + aog list
    compass_iwfm_report_exception = {
      name        = "Prod_Compass_IWFMReportException_Normal"
      description = "More than 15 IWFMReportException lines in 5 minutes in Compass (prod)."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "compass-prod-axa-li-jp"
        | filter contains(content, "IWFMReportException", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      threshold   = "15"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: index=iwfm sourcetype=fmwsagentlog earliest=-1h (LOGLEVEL="Caution" OR LOGLEVEL="Fatal")
    #         | transaction host AGENTID maxspan=1s
    #   Every hour at :15, results > 0, throttle 1 hour, Normal, email raju.kolukuluri
    #   transaction only groups lines that arrive within 1 second; "> 0" still means "any line".
    iwfm_agent_errors = {
      name        = "Prod_IWFM_AgentErrors_Normal"
      description = "IWFM agent (fmwsagentlog) logged LOGLEVEL Caution or Fatal."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*fmwsagentlog*")
        | filter contains(content, "LOGLEVEL=\"Caution\"", caseSensitive: false)
              or contains(content, "LOGLEVEL=\"Fatal\"", caseSensitive: false)
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "iwfm" {
  for_each = local.iwfm_alerts

  title       = each.value.name
  description = each.value.description
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = each.value.query
      }
      analyzer_input_field {
        key   = "threshold"
        value = each.value.threshold
      }
      analyzer_input_field {
        key   = "alertCondition"
        value = each.value.condition
      }
      analyzer_input_field {
        key   = "alertOnMissingData"
        value = "false"
      }
      analyzer_input_field {
        key   = "violatingSamples"
        value = each.value.violating
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = each.value.window
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = each.value.dealerting
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
        value = each.value.name
      }
      property {
        key   = "event.description"
        value = each.value.description
      }
      property {
        key   = "alert.severity"
        value = each.value.severity
      }
    }
  }

  execution_settings {}
}
