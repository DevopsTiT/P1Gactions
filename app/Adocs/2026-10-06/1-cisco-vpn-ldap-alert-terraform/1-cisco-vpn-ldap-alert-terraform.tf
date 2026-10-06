# Splunk alert → Dynatrace detector (Terraform only, no workflow)
#
#   Cisco VPN : LDAP Connections are failing which will impact end users using windows basic
#     index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*
#     Last 1 minute, cron */1, results > 3, Once, no throttle
#     Actions: Add to Triggered Alerts (Critical), PagerDuty, Send email
#
# Real events seen in Splunk (search 9/6 to 10/6, 2 events):
#   Sep 24 20:29:04 10.15.66.91 %ASA-2-113022: AAA Marking LDAP server 10.3.87.2 in aaa-server group Windows_LDAP as FAILED
#   Sep 23 20:46:02 10.15.66.91 %ASA-2-113022: AAA Marking LDAP server 10.3.87.1 in aaa-server group Windows_LDAP as FAILED
#   host = ljcmgt14.ads-jp.intraxa   source = /var/log/ASA/JPNDH-VASA19-ALJ.log   sourcetype = cisco:asa
#
# IMPORTANT: the ASA writes ONE line each time it marks ONE LDAP server as FAILED.
# Splunk's "> 3 in 1 minute" therefore never fired on these real events.
# Set ldap_failed_threshold to "0" to alert on the first FAILED line (recommended),
# or keep "3" to copy Splunk exactly.
#
# PagerDuty key is NOT copied. Paging and email go through the standard SILVA / PagerDuty flow.
#
# CONFIRM before apply (check.dql query 1):
#   How the syslog file from ljcmgt14 arrives in Dynatrace: log.source path, host.name, or a bucket.

terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}

locals {
  # "3" = same as Splunk (results > 3 in 1 minute). "0" = any FAILED line (recommended, see header).
  ldap_failed_threshold = "3"
}

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title       = "Prod_Network_CiscoVPN_LDAPFailed_Critical"
  description = "Cisco ASA marked a Windows_LDAP server as FAILED (%ASA-2-113022). VPN users who log in with Windows credentials may be unable to connect."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          | filter contains(log.source, "/var/log/ASA/") or matchesValue(host.name, "ljcmgt14*")
          | filter contains(content, "%ASA-2-113022")
          | filter contains(content, "Windows_LDAP as FAILED")
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
      }
      analyzer_input_field {
        key   = "threshold"
        value = local.ldap_failed_threshold
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
        value = "1"
      }
      analyzer_input_field {
        key   = "slidingWindow"
        value = "1"
      }
      analyzer_input_field {
        key   = "dealertingSamples"
        value = "15"
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
        value = "Cisco VPN : LDAP Connections are failing which will impact end users"
      }
      property {
        key   = "event.description"
        value = "Cisco ASA (JPNDH-VASA19) marked a Windows_LDAP aaa-server as FAILED (%ASA-2-113022). VPN and business users using Windows login may be impacted. Check the LDAP servers 10.3.87.1 and 10.3.87.2."
      }
      property {
        key   = "alert.severity"
        value = "critical"
      }
      property {
        key   = "app.name"
        value = "Cisco VPN"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
