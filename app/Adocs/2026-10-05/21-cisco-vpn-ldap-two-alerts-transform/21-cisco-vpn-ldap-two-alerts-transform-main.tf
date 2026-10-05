# Cisco VPN LDAP failure: 2 Splunk alerts → 1 Dynatrace detector + 1 email workflow
# Splunk A: index=network*       sourcetype=asa_networksyslog *Windows_LDAP as FAILED*
# Splunk B: index="networksyslog" sourcetype=cisco:asa         *Windows_LDAP as FAILED*
# Both: every 1 min, last 1 min, results > 3, Critical, PagerDuty + email.
# PagerDuty and SILVA come from the tenant's standard problem workflow (preview then post), not from here.

variable "network_bucket_pattern" {
  description = "Grail bucket(s) with Cisco ASA syslog. Confirm with check.dql query 1."
  type        = string
  default     = "network*"
}

variable "ldap_alert_email_to" {
  description = "Recipients from the Splunk 'Send email' action (not visible in the screenshot)."
  type        = list(string)
  default     = ["<network-team-dl>@axa.co.jp"]
}

locals {
  ldap_name = "Cisco VPN : LDAP Connections are failing which will impact end users"

  # dedup stops one ASA line that arrived through two syslog paths from being counted twice
  ldap_filter = <<-EOT
    | filter matchesValue(dt.system.bucket, "${var.network_bucket_pattern}")
    | filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
    | dedup timestamp, content
  EOT
}

resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_failed" {
  title       = local.ldap_name
  description = "VPN users who log in with Windows credentials cannot connect: Cisco ASA marked the Windows_LDAP server group FAILED more than 3 times in 1 minute."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query"
        value = <<-EOT
          fetch logs
          ${local.ldap_filter}
          | makeTimeseries count = count(default: 0), interval:1m
        EOT
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
        value = local.ldap_name
      }
      property {
        key   = "event.description"
        value = "More than 3 'Windows_LDAP as FAILED' messages from Cisco ASA in 1 minute (ASA-2-113022). VPN users and business users using Windows login are impacted."
      }
      property {
        key   = "alert.severity"
        value = "critical"
      }
    }
  }

  execution_settings {}
}

resource "dynatrace_automation_workflow" "cisco_vpn_ldap_failed_email" {
  title       = "${local.ldap_name} - email"
  description = "Emails the network team with the recent ASA LDAP failure lines. Paging is done by the standard SILVA and PagerDuty workflow."

  tasks {
    task {
      name        = "recent_failures"
      description = "LDAP FAILED lines from the last 10 minutes"
      action      = "dynatrace.automations:execute-dql-query"
      active      = true
      input = jsonencode({
        query = <<-EOT
          fetch logs, from:now()-10m
          ${local.ldap_filter}
          | fields timestamp, log.source, content
          | sort timestamp desc
          | limit 50
        EOT
      })
      position {
        x = 0
        y = 1
      }
    }
    task {
      name        = "send_email"
      description = "Email the network team"
      action      = "dynatrace.email:send-email"
      active      = true
      input = jsonencode({
        to      = var.ldap_alert_email_to
        cc      = []
        bcc     = []
        subject = "[CRITICAL] {{ event()[\"event.name\"] }}"
        content = "Problem {{ event()[\"display_id\"] }}: Cisco ASA is marking the Windows_LDAP server group FAILED. VPN logins with Windows credentials are failing.\n\n{% for r in result(\"recent_failures\").records %}{{ r.timestamp }}  {{ r.content }}\n{% endfor %}"
      })
      conditions {
        states = {
          recent_failures = "OK"
        }
      }
      position {
        x = 0
        y = 2
      }
    }
  }

  trigger {
    event {
      active = true
      config {
        davis_problem {
          categories {
            custom = true
          }
          custom_filter = "matchesPhrase(event.name, \"Windows_LDAP\") or matchesPhrase(event.name, \"LDAP Connections are failing\")"
          trigger_on    = "open"
        }
      }
    }
  }
}
