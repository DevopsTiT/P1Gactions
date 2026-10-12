terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

# Splunk:
#   index="myaxabackend-prod-axa-li-jp" api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"
#   | append [search index="apigw_syslog" sourcetype=apigw_syslog_prod "Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"]
# Backend part: hosts are pods named myaxabackend-<replicaset>-<pod> (17 values).
# Gateway part: index apigw_syslog has 1 host (EEAA2015.ppprivmgmt.intraxa)
#               and 1 source (/SYSLOG/APIGW/prod/local4.log).
resource "dynatrace_davis_anomaly_detectors" "emma_be_timeout_to_esg_production" {
  title       = "Prod_Life_Emma_EmmaBETmeoutToESGProduction_High"
  description = "Monitors the ESG calls from Emma BE (OpenPaaS) to ESG (CoreIT) for timeouts. Fires when more than 20 timeouts are logged in 5 minutes, counting myaxabackend pods and the API gateway host EEAA2015 together."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter (
                (startsWith(host.name, "myaxabackend-") or startsWith(k8s.pod.name, "myaxabackend-"))
                and contains(content, "api-jp-cert.corp.intraxa", caseSensitive:false)
                and contains(content, "java.net.SocketTimeoutException", caseSensitive:false)
              ) or (
                contains(host.name, "EEAA2015", caseSensitive:false)
                and contains(log.source, "/SYSLOG/APIGW/prod/local4.log", caseSensitive:false)
                and contains(content, "Problem routing to", caseSensitive:false)
                and contains(content, "timed out", caseSensitive:false)
                and contains(content, "myaxa-api.alj.intraxa", caseSensitive:false)
              )
          | fieldsAdd part = if(contains(host.name, "EEAA2015", caseSensitive:false), "apigw", else:"myaxabackend")
          | summarize timeouts = count(),
                      backend_timeouts = countIf(part == "myaxabackend"),
                      apigw_timeouts = countIf(part == "apigw"),
                      hosts = collectDistinct(host.name),
                      sample = takeFirst(content)
          | filter timeouts > 20
          | fieldsAdd scope = "emma-be-to-esg-timeout"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "Emma BE timeout to ESG Production"
      }
      property {
        key   = "event.description"
        value = "More than 20 timeouts in 5 minutes on calls from Emma BE (myaxabackend pods on OpenPaaS) to ESG (CoreIT), counted from the pods and the API gateway host EEAA2015. See timeouts, backend_timeouts, apigw_timeouts, hosts and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "emma"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
