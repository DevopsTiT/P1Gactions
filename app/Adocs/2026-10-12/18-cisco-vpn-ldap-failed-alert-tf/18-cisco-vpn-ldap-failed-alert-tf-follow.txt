# Cisco VPN LDAP Failed Alert

## Decision tree

```
Splunk alert: Cisco VPN LDAP connections failing
 search → index=networksyslog sourcetype=cisco:asa *Windows_LDAP as FAILED*
   Dynatrace has no index or sourcetype → filter on content phrase
   want a source filter too? → run check query 1 → add log.source filter
 time range 1 minute, cron every minute → detector runs every minute anyway
 results greater than 3 → summarize count() → filter failures > 3
 severity Critical + PagerDuty → alert.severity high, pagerduty.enabled 1
 email action → workflow (recipients not visible, not copied)
 alerts too often or too rarely? → check query 2 → tune the 3
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it? | One Records detector replacing the Splunk scheduled search. |
| What does it catch? | More than 3 "Windows_LDAP as FAILED" lines in 1 minute. |
| Severity | high, because Splunk severity was Critical. |
| PagerDuty | On (`"1"`). |
| What needs checking? | Which Dynatrace field replaces `index` and `sourcetype`. |

## Summary

The Splunk search becomes a DQL content filter plus a count. Because the trigger was "more than 3", the query needs `summarize count()` and `filter failures > 3`. The phrase "Windows_LDAP as FAILED" is specific enough to work without the Splunk index, but you can add a source filter after check query 1.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Splunk index | A named bucket of logs in Splunk, here `networksyslog`. | Dynatrace has no index. You filter on fields like `log.source` instead. |
| sourcetype | Splunk's label for the log format, here `cisco:asa`. | Same: no direct match in Dynatrace. |
| Cisco ASA | The firewall and VPN appliance that writes these syslog lines. | The lines come from it, not from an app. |
| LDAP | The protocol the VPN uses to check user names and passwords against Windows Active Directory. | If LDAP fails, users cannot log in to the VPN. |
| Records detector | A Dynatrace rule that runs DQL every minute and opens a problem when rows come back. | Replacement for the Splunk alert. |
| Threshold | The number that must be passed before alerting, here 3. | Needs `summarize` because plain rows have no count. |

### How each Splunk field was mapped

| Splunk field | Dynatrace form |
|---|---|
| Alert name | `title` |
| Description | `description`, finished in full sentences. |
| `index="networksyslog" sourcetype=cisco:asa` | Not needed for the phrase filter. Optional `log.source` filter after check query 1. |
| `*Windows_LDAP as FAILED*` | `contains(content, "Windows_LDAP as FAILED", caseSensitive:false)`. Splunk search ignores case by default. |
| Run on cron schedule `*/1 * * * *` | Dropped. The detector runs every minute. |
| Time range Last 1 minute | `fetch logs, from:now()-1m` |
| Expires 24 hours | Dropped. The problem closes when the count drops to 3 or less. |
| Number of results greater than 3 | `summarize failures = count()` then `filter failures > 3`. |
| Trigger For each result | Not needed. The count gives one row, so one problem. |
| Throttle off | Identity field `scope` keeps it to one open problem. |
| Add to Triggered Alerts, Critical | `alert.severity = "high"` |
| PagerDuty | `pagerduty.enabled = "1"`. The workflow sends it. |
| Send email | Workflow. Recipients were not visible and are not copied. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN in case LDAP connections fail due to backend system issues, which impacts VPN users and business users. Fires when more than 3 Windows_LDAP FAILED lines arrive in 1 minute."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1m
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
          | summarize failures = count(), sample = takeFirst(content)
          | filter failures > 3
          | fieldsAdd scope = "cisco-vpn-windows-ldap"
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
        value = "Cisco VPN : LDAP Connections are failing"
      }
      property {
        key   = "event.description"
        value = "More than 3 Cisco ASA Windows_LDAP FAILED lines in 1 minute. VPN users who sign in with Windows basic auth may be unable to connect. See failures and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "cisco-vpn"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
```

The full file, with the `terraform` and `provider` blocks, is `18-cisco-vpn-ldap-failed-alert-tf.tf`.

### Things to check

| Check | Why |
|---|---|
| Run check query 1 | Shows which `log.source` or host the ASA lines use. Add it as a filter if other systems could log the same phrase. |
| Run check query 2 | Shows failures per minute over 7 days. If normal traffic often passes 3, raise the threshold. |
| Ingestion delay | Syslog can arrive a little late. If a 1 minute window misses bursts, use `from:now()-2m` and raise the threshold to match. |
| One problem or one per firewall? | Today it is one problem overall. To split per firewall, add `by:{ host.name }` to `summarize` and use `host.name` as the identity field. |

## Data flow map

```
Cisco ASA VPN tries LDAP login against Windows AD
  → LDAP fails → ASA writes syslog "Windows_LDAP as FAILED"
  → syslog ingest → Dynatrace Grail logs
  → detector every minute: count lines in last 1 min
       count > 3 → problem (high)
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → count back to 3 or less → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `18-cisco-vpn-ldap-failed-alert-tf.tf` | Full Terraform. |
| `18-cisco-vpn-ldap-failed-alert-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `18.sh` | Commands, one per line. |

## Commands

All commands are in [`18.sh`](./18.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/18-cisco-vpn-ldap-failed-alert-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/18-cisco-vpn-ldap-failed-alert-tf
git commit -m "Cisco VPN LDAP failed alert detector"
git push
```
