# Cisco VPN LDAP Log Source Alert

## Decision tree

```
Your DQL: log.source contains /var/log/ASA + content "Windows_LDAP as FAILED"
 Splunk index + sourcetype → replaced by log.source "/var/log/ASA"
   covers 4 files → VASA19-ALJ, VASA19-ADJ, VASA19, VASA17
 add time window → from:now()-5m (late syslog safety)
 threshold → none, any line opens a problem (old "> 3" never reachable)
 identity → log.source → one problem per ASA log file
 check query 1 empty? → ASA files not ingested → fix OneAgent log ingest first
 one failed server too noisy to page? → medium, PagerDuty 0
```

## Short takeaway

| Question | Answer |
|---|---|
| Based on | Your query in `6.sh`, lines 9 to 11. |
| What was added | A 5 minute window and the detector wrapper. |
| Identity | `log.source`, one problem per ASA log file. |
| Severity | high, PagerDuty on (Splunk Critical). |
| Replaces | Answers 18 and 19. Same resource name, apply one only. |

## Summary

Your two filters are the right Dynatrace replacement for the Splunk index and sourcetype. `log.source` containing `/var/log/ASA` matches all four ASA files Splunk shows, and the content filter matches the FAILED line. I only added a time window and wrapped it in a Records detector.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| `log.source` | The file path or source name Dynatrace stores with each log line. | Replaces Splunk's `source`, and here also the index and sourcetype. |
| `/var/log/ASA` | Folder on collector ljcmgt14 where the Cisco ASA syslog files are written. | Every ASA file lives under it. |
| Records detector | Dynatrace rule that runs DQL every minute and opens a problem when rows return. | Replacement for the Splunk alert. |
| Identity field | Field that decides one problem or many. | Here one problem per ASA file. |

### Splunk sources covered

| Splunk source | Share of events | Matched by `/var/log/ASA` |
|---|---|---|
| /var/log/ASA/JPNDH-VASA19-ALJ.log | 88.6% | Yes |
| /var/log/ASA/JPNDH-VASA19-ADJ.log | 10.5% | Yes |
| /var/log/ASA/JPNDH-VASA19.log | 0.9% | Yes |
| /var/log/ASA/JPNDH-VASA17.log | under 0.1% | Yes |

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index="networksyslog" sourcetype=cisco:asa` | `contains(log.source, "/var/log/ASA", caseSensitive:false)` |
| `*Windows_LDAP as FAILED*` | `contains(content, "Windows_LDAP as FAILED", caseSensitive:false)` |
| Last 1 minute, cron every minute | `from:now()-5m`, detector runs every minute. |
| More than 3 results | Dropped. Only 2 events in a month, one per server, so it could never fire. |
| Severity Critical | `alert.severity = "high"` |
| PagerDuty | `pagerduty.enabled = "1"` |
| Send email | Workflow. No recipients copied. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN in case LDAP connections fail due to backend system issues, which impacts VPN users and business users. Fires when a Cisco ASA log under /var/log/ASA reports Windows_LDAP as FAILED."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(log.source, "/var/log/ASA", caseSensitive:false)
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "log.source"
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
        value = "A Cisco ASA marked a Windows_LDAP server as FAILED. VPN users who sign in with Windows basic auth may be unable to connect. See the log line (content) and log.source on the problem."
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

### Optional tweaks

| Tweak | How |
|---|---|
| One problem per LDAP server instead of per file | Add `\| parse content, "LD 'LDAP server ' NSPACE:ldap_server"` and use `ldap_server` as the identity field. |
| Do not page for a single server | Set `alert.severity = "medium"` and `pagerduty.enabled = "0"`. |

## Data flow map

```
Cisco ASA VASA19 / VASA17 cannot reach a Windows LDAP server
  → ASA writes "... Windows_LDAP as FAILED"
  → collector ljcmgt14 → /var/log/ASA/*.log
  → Dynatrace Grail logs (log.source = file path)
  → detector every minute, last 5 min
       one problem per log.source (high)
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → no new line for 5 min → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `20-cisco-vpn-ldap-logsource-tf.tf` | Full Terraform. |
| `20-cisco-vpn-ldap-logsource-tf-check.dql` | Two check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `20.sh` | Commands, one per line. |

## Commands

All commands are in [`20.sh`](./20.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/20-cisco-vpn-ldap-logsource-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/20-cisco-vpn-ldap-logsource-tf
git commit -m "Cisco VPN LDAP failed detector on log.source"
git push
```
