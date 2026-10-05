# ==========================================
# OpenPaaS / ESG Splunk alerts → Dynatrace detectors (Terraform only, no workflows)
# 7 Splunk alerts → 5 detectors (3 "Emma BE timeout to ESG" alerts had the same search)
#
# CONFIRM BEFORE APPLY: the Splunk index / sourcetype / host filters below are mapped to
# Dynatrace fields by guess. Run check.dql query 1 and replace each line marked CONFIRM.
# ==========================================

locals {
  openpaas_alerts = {

    # Splunk: ALJ OpenPaaS Egress Proxy Public IP Usage Alert
    # index=apigw_syslog sourcetype=apigw_syslog_prod /maam/* (*52.76.125.86* OR *54.179.120.88*)
    # | stats count | where count <= 0   → every 15 min over 15 min, High, email
    # Absence alert: fires when neither egress IP was used for 15 minutes.
    egress_proxy_ip_absent = {
      name        = "Prod_OpenPaaS_EgressProxyPublicIPUsage_High"
      description = "Only one egress proxy public IP is in use: neither 52.76.125.86 nor 54.179.120.88 appeared in ESG (/maam/) logs for 15 minutes."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(log.source, "*apigw_syslog*")
        | filter contains(content, "/maam/")
        | filter contains(content, "52.76.125.86") or contains(content, "54.179.120.88")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM line 1 (Splunk index=apigw_syslog sourcetype=apigw_syslog_prod)
      threshold   = "1"
      condition   = "BELOW"
      violating   = "15"
      window      = "15"
      dealerting  = "5"
    }

    # Splunk (3 alerts, same search):
    #   ESG - Emma BE timeout to ESG Production                       (email)
    #   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High               (High, PagerDuty, email)
    #   Prod_Life_Emma_EmmaBETmeoutToESGProduction_High_PagerDuty     (PagerDuty)
    # index="myaxabackend-prod-axa-li-jp" "api-jp-cert.corp.intraxa" AND "java.net.SocketTimeoutException"
    # | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
    # every 5 min over 5 min, results > 20, throttle 60 s
    emma_be_timeout_to_esg = {
      name        = "Prod_Life_Emma_EmmaBETimeoutToESGProduction_High"
      description = "More than 20 timeouts in 5 minutes on calls from Emma BE (OpenPaaS) to ESG (CoreIT)."
      severity    = "high"
      query       = <<-EOT
        fetch logs
        | filter (k8s.namespace.name == "myaxabackend-prod-axa-li-jp"
                  and contains(content, "api-jp-cert.corp.intraxa", caseSensitive: false)
                  and contains(content, "java.net.SocketTimeoutException", caseSensitive: false))
              or (matchesValue(log.source, "*apigw_syslog*")
                  and contains(content, "Problem routing to", caseSensitive: false)
                  and contains(content, "timed out", caseSensitive: false)
                  and contains(content, "myaxa-api.alj.intraxa", caseSensitive: false))
        | makeTimeseries count = count(default: 0), interval:1m
        | fieldsAdd count = arrayMovingSum(count, 5)
      EOT
      # CONFIRM: k8s.namespace.name (Splunk index=myaxabackend-prod-axa-li-jp) and log.source (apigw_syslog)
      threshold   = "20"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: PIS Connection Issue (Batch->OpenPaaS) Alert
    # index=claims host="CEAA2058.prprivmgmt.intraxa" sourcetype=pis_defaultlog
    # | regex _raw="\"errorCode\":\s\"ESG120\""   → every 5 min over 5 min, > 0, email (Normal)
    pis_connection_esg120 = {
      name        = "Prod_Claims_PISConnectionIssueBatchToOpenPaaS_Normal"
      description = "PIS batch on CEAA2058 logged errorCode ESG120 (connection issue from Batch to OpenPaaS)."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter matchesValue(host.name, "ceaa2058*")
        | filter matchesValue(log.source, "*pis_default*")
        | filter contains(content, "errorCode") and contains(content, "\"ESG120\"")
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: host.name and log.source (Splunk host=CEAA2058.prprivmgmt.intraxa sourcetype=pis_defaultlog)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "5"
    }

    # Splunk: eopt - OpenPaaS Pod Error (Backend)
    # index="eopt-prod-axa-li-jp" | rex "(?<timestamp>ISO8601 ms Z)\s+(?<level>[A-Z]+)" | eval level=upper(level) | search level="ERROR"
    # every hour at :00, > 0, email (Normal)
    eopt_pod_error_backend = {
      name        = "Prod_eopt_OpenPaaSPodErrorBackend_Normal"
      description = "eopt backend pod on OpenPaaS logged a line with level ERROR."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
        | parse content, "LD ISO8601:log_ts SPACE+ WORD:level"
        | filter upper(level) == "ERROR"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: k8s.namespace.name (Splunk index=eopt-prod-axa-li-jp) and that the parse matches (check.dql query 3)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }

    # Splunk: eopt - OpenPaaS Pod Error (Frontend)
    # index="eopt-prod-axa-li-jp" | spath | eval level=upper(level) | search level="ERROR"
    # every hour at :00, > 0, email (Normal)
    eopt_pod_error_frontend = {
      name        = "Prod_eopt_OpenPaaSPodErrorFrontend_Normal"
      description = "eopt frontend pod on OpenPaaS logged a JSON line with level ERROR."
      severity    = "medium"
      query       = <<-EOT
        fetch logs
        | filter k8s.namespace.name == "eopt-prod-axa-li-jp"
        | parse content, "JSON:j"
        | filter upper(toString(j[level])) == "ERROR"
        | makeTimeseries count = count(default: 0), interval:1m
      EOT
      # CONFIRM: k8s.namespace.name and that JSON lines have a "level" key (check.dql query 3)
      threshold   = "0"
      condition   = "ABOVE"
      violating   = "1"
      window      = "5"
      dealerting  = "60"
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "openpaas" {
  for_each = local.openpaas_alerts

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
