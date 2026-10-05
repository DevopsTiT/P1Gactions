# Cisco VPN LDAP Alert Terraform

## Decision tree

```
Create the Cisco VPN LDAP alert in Dynatrace with Terraform
 Step 1: confirm field names with DQL
   logs have a sourcetype field?          → keep sourcetype_filter
   no sourcetype field?                   → set sourcetype_filter = ""
   bucket not named network...?           → change bucket_pattern
 Step 2: auth
   platform token?                        → DT_ENV_URL + DT_PLATFORM_TOKEN
   OAuth client?                          → DT_ENV_URL + DT_CLIENT_ID + DT_CLIENT_SECRET + DT_ACCOUNT_ID
   permission error on apply?             → token needs anomaly detection settings write and storage:logs:read
 Step 3: terraform init → plan → apply
   plan shows 1 to add?                   → apply
   query error after apply?               → open the alert in the Anomaly Detection app and run the query there
 Step 4: routing (not in Terraform)
   SILVA group and PD critical            → add to OPEN workflow for this event.name
```

## Short takeaway

| Question | Answer |
|---|---|
| Terraform resource | `dynatrace_davis_anomaly_detectors` (Davis Anomaly Detection custom alert) |
| Provider | `dynatrace-oss/dynatrace` |
| Splunk `index=network*` | `matchesValue(dt.system.bucket, "network*")` |
| Splunk `sourcetype=asa_networksyslog` | `filter sourcetype == "asa_networksyslog"` (only if that field exists in Grail) |
| Splunk "results > 3 in last 1 minute" | threshold 3, ABOVE, sliding window 1, violating samples 1 |
| File | `4-cisco-vpn-ldap-alert-terraform-main.tf` |

## Summary

This edited Splunk alert searches `index=network*` with `sourcetype=asa_networksyslog` (the earlier one used `networksyslog` and `cisco:asa`). The Terraform file creates one Davis anomaly detector that counts `Windows_LDAP as FAILED` lines per minute and opens a problem when there are more than 3. The bucket pattern and sourcetype filter are variables, so you can match whatever your Grail data actually uses.

## What changed from the earlier version

| Setting | Earlier screenshot | This screenshot |
|---|---|---|
| Title | ...using windows basic | ...which will impact end users |
| Index | `networksyslog` | `network*` |
| Sourcetype | `cisco:asa` | `asa_networksyslog` |
| Schedule, trigger, actions | Same | Same |

## The Terraform file

`4-cisco-vpn-ldap-alert-terraform-main.tf`:

```hcl
terraform {
  required_providers {
    dynatrace = {
      source = "dynatrace-oss/dynatrace"
    }
  }
}

provider "dynatrace" {}

variable "bucket_pattern" {
  type    = string
  default = "network*"
}

variable "sourcetype_filter" {
  type    = string
  default = "| filter sourcetype == \"asa_networksyslog\""
}

variable "actor_id" {
  type    = string
  default = null
}

variable "enabled" {
  type    = bool
  default = true
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
```

## Splunk to Terraform mapping

| Splunk setting | Terraform field | Value |
|---|---|---|
| Alert name | `title` and `event.name` property | Cisco VPN : LDAP Connections are failing which will impact end users |
| Description | `description` and `event.description` | Same text |
| Search | `analyzer_input_field` key `query` | DQL built in `locals` |
| Cron every minute, last 1 minute | `slidingWindow` | 1 |
| Number of results greater than 3 | `threshold` and `alertCondition` | 3 and ABOVE |
| Trigger once | `violatingSamples` | 1 |
| (no Splunk equivalent) | `dealertingSamples` | 5 clean minutes to close |
| Severity Critical | `alert.severity` property | critical (your workflow must read it) |
| PagerDuty and email actions | Not in this resource | Handled by the OPEN workflow |

## Variables

| Variable | Default | When to change |
|---|---|---|
| `bucket_pattern` | `network*` | If the network syslog bucket has a different name |
| `sourcetype_filter` | `\| filter sourcetype == "asa_networksyslog"` | Set to `""` if Grail logs have no `sourcetype` field |
| `actor_id` | null | Set to a service user UUID so the query doesn't depend on a person's account |
| `enabled` | true | Set false to deploy it switched off first |

## Check the fields before apply

```dql
fetch logs, from:-24h
| filter contains(content, "Windows_LDAP as FAILED")
| fields timestamp, dt.system.bucket, sourcetype, log.source, content
| limit 20
```

| What you see | What to set |
|---|---|
| `dt.system.bucket` starts with network | Keep `bucket_pattern = "network*"` |
| Bucket has another name | Set `bucket_pattern` to that name |
| `sourcetype` column is empty | Set `sourcetype_filter = ""` |
| No rows at all | Network syslog isn't in Dynatrace yet; fix ingest first |

## Apply steps

| Step | Command | What it does |
|---|---|---|
| 1 | `export DT_ENV_URL=https://<env-id>.apps.dynatrace.com` | Points Terraform at your tenant |
| 2 | `export DT_PLATFORM_TOKEN=<token>` | Auth (needs anomaly detection write and logs read) |
| 3 | `terraform init` | Downloads the Dynatrace provider |
| 4 | `terraform plan -var-file=terraform.tfvars` | Shows 1 resource to add |
| 5 | `terraform apply -var-file=terraform.tfvars` | Creates the alert |

If your team repo (`dynatrace-terraform/applications`) already has a provider block, copy only the `variable`, `locals`, `resource` and `output` blocks into it.

## Common mistakes

| Mistake | Fix |
|---|---|
| Using the old API token (`DT_API_TOKEN`) only | This resource needs a platform token or OAuth client |
| Leaving the sourcetype filter when the field doesn't exist | Query returns 0 forever and never alerts |
| Threshold written as number | Values are strings in this resource: `"3"` |
| Expecting PagerDuty critical automatically | The workflow decides PD severity; add a rule for this alert |
| Committing tfvars with tokens | Keep tokens in env vars, never in tfvars |

## Data flow

```
terraform apply
  → Dynatrace Settings API (builtin:davis.anomaly-detectors)
  → custom alert created in Anomaly Detection app
  → every minute: DQL on network* bucket, "Windows_LDAP as FAILED", count per minute
  → count > 3
  → Davis event CUSTOM_ALERT, alert.severity critical
  → Problem → OPEN workflow → SILVA + PagerDuty + email
  → 5 clean minutes → problem closes → CLOSE workflow
```

## Investigation

| Checked | Finding |
|---|---|
| New screenshot | Index `network*`, sourcetype `asa_networksyslog`, title shortened, trigger and actions unchanged |
| Provider docs (`dynatrace_davis_anomaly_detectors`) | Needs `analyzer`, `event_template`, `execution_settings`, `title`, `description`, `enabled`, `source`; auth by platform token or OAuth |
| Analyzer | `StaticThresholdAnomalyDetectionAnalyzer` with string input fields |

## Result

Copy `4-cisco-vpn-ldap-alert-terraform-main.tf` into your Terraform folder, confirm the bucket and sourcetype with the DQL check, then run init, plan and apply. Routing (SILVA group, PagerDuty critical, email) still lives in the workflow.

## Related files

| File | Purpose |
|---|---|
| `4-cisco-vpn-ldap-alert-terraform-main.tf` | The Terraform resource |
| `4-cisco-vpn-ldap-alert-terraform.tfvars.example` | Example variable values |
| `4.sh` | Init, plan, apply, export and mirror one-liners |
| `2026-10-05/3-cisco-vpn-ldap-alert-to-dynatrace/` | The conversion logic and routing notes |

## Commands

See `4.sh` (not run).
