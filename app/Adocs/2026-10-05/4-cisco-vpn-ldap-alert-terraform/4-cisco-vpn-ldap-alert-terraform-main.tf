terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

# Auth comes from env vars: DT_ENV_URL plus DT_PLATFORM_TOKEN (or DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_ID)
provider "dynatrace" {}

variable "bucket_pattern" {
  description = "Grail bucket(s) holding network syslog. Splunk used index=network*"
  type        = string
  default     = "network*"
}

variable "sourcetype_filter" {
  description = "Extra DQL filter for the ASA source. Set to empty string if your logs have no sourcetype field"
  type        = string
  default     = "| filter sourcetype == \"asa_networksyslog\""
}

variable "actor_id" {
  description = "UUID of the service user the query runs as. Leave null to use the token owner"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Turn the alert on or off"
  type        = bool
  default     = true
}

locals {
  ldap_failed_query = join(" ", compact([
    "fetch logs",
    "| filter matchesValue(dt.system.bucket, \"${var.bucket_pattern}\")",
    var.sourcetype_filter,
    "| filter contains(content, \"Windows_LDAP as FAILED\")",
    "| makeTimeseries count = count(default: 0), interval:1m",
  ]))
}

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users"
  description = "Converted from Splunk: index=network* sourcetype=asa_networksyslog *Windows_LDAP as FAILED*, more than 3 results in 1 minute, severity Critical."
  enabled     = var.enabled
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = local.ldap_failed_query
      }
      analyzer_input_field {
        key   = "threshold"
        value = "3"
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
        value = "5"
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
        value = "This alert monitors the VPN in case LDAP connections are failing due to backend system issues, which impacts VPN users and business users. More than 3 'Windows_LDAP as FAILED' messages from Cisco ASA in 1 minute."
      }
      property {
        key   = "alert.severity"
        value = "critical"
      }
      property {
        key   = "alert.source"
        value = "splunk-migrated networksyslog asa"
      }
    }
  }

  execution_settings {
    actor = var.actor_id
  }
}

output "anomaly_detector_id" {
  value = dynatrace_davis_anomaly_detectors.cisco_vpn_ldap_failed.id
}
