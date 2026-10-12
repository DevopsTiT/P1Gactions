# Cisco VPN LDAP Failed Per Server

## Decision tree

```
Splunk search result: 2 events in 1 month
 each event = one LDAP server marked FAILED (ASA-2-113022)
 only 2 servers seen → 10.3.87.1 and 10.3.87.2
   old rule "more than 3 in 1 minute" → can never fire → broken alert
   new rule → any FAILED line → problem per LDAP server
 lines missing in Dynatrace? → check query 1 → ASA syslog not ingested yet → fix ingest first
 paging for one server is too noisy? → set severity medium, PagerDuty 0
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from answer 18? | Threshold removed. Any FAILED line opens a problem. |
| Why? | The old "more than 3 per minute" rule could never be met. |
| Identity | `ldap_server`, so each failed server gets its own problem. |
| Severity | high, PagerDuty on, same as Splunk Critical. |
| Biggest risk | The ASA syslog may not be in Dynatrace yet. Check query 1 tells you. |

## Summary

The Splunk screenshot shows the real log line: the ASA writes one line each time it marks an LDAP server as failed. Only two events happened in a month, and there are only two LDAP servers. More than 3 lines in one minute is basically impossible, so the old alert never fired. The new detector opens one problem per failed server.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| ASA-2-113022 | Cisco message ID for "AAA Marking server as FAILED". The 2 means severity critical. | A unique, reliable filter. |
| aaa-server group | The list of login servers the VPN uses, here `Windows_LDAP`. | When every server in the group is failed, nobody can log in. |
| Marking FAILED | The ASA stops using that server for a while after it does not answer. | One line per server, not per user. |
| `parse` | DQL command that pulls a value out of the text. | Gets the server IP into `ldap_server`. |
| `NSPACE` | DQL pattern matching everything up to the next space. | Captures `10.3.87.2` cleanly. |
| Identity field | Field that decides one problem or many. | One problem per LDAP server. |

### What the Splunk results showed

| Fact from screenshot | What it means |
|---|---|
| 2 events from 9/12 to 10/12 | Very rare. Each event matters. |
| Sep 23, server 10.3.87.1 | One server failed. |
| Sep 24, server 10.3.87.2 | The other server failed on a different day. |
| host `ljcmgt14.ads-jp.intraxa` | The syslog collector that received the line. |
| source `/var/log/ASA/JPNDH-VASA19-ALJ.log` | The file on that collector. Useful if Dynatrace reads it with OneAgent. |
| Old threshold more than 3 in 1 minute | Neither event would have fired the alert. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "cisco_vpn_ldap_connections_failing" {
  title       = "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic"
  description = "Monitors the VPN in case LDAP connections fail due to backend system issues, which impacts VPN users and business users. Fires when the Cisco ASA marks a Windows_LDAP server as FAILED (ASA-2-113022)."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter contains(content, "113022")
          | filter contains(content, "Windows_LDAP as FAILED", caseSensitive:false)
          | parse content, "LD 'LDAP server ' NSPACE:ldap_server"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "ldap_server"
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
        value = "Cisco VPN : LDAP server {ldap_server} marked FAILED"
      }
      property {
        key   = "event.description"
        value = "The Cisco ASA marked LDAP server {ldap_server} in group Windows_LDAP as FAILED. VPN users who sign in with Windows basic auth may be unable to connect. See the log line (content) on the problem."
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

### Changes from answer 18

| Part | Answer 18 | Now |
|---|---|---|
| Filter | Phrase only | Message ID 113022 plus the phrase |
| Window | 1 minute | 5 minutes, so late syslog lines are not missed |
| Count | `summarize` then more than 3 | Removed. Raw rows. |
| Identity | `scope` | `ldap_server` from `parse` |
| Event name | Fixed text | Includes the server IP |

### Things to check

| Check | Why |
|---|---|
| Check query 1 | If it returns nothing for the last 35 days, the ASA syslog is not in Dynatrace. The detector would stay silent. Fix ingestion first. |
| Check query 3 | Confirms the parse gives 10.3.87.1 or 10.3.87.2. |
| Paging decision | One failed server out of two still lets users log in. If the team only wants a page when users are affected, set severity medium and PagerDuty 0. |
| `{ldap_server}` placeholder | If your workflow does not fill placeholders, the text shows literally. The IP is still on the problem as a field. |

## Data flow map

```
Cisco ASA (JPNDH-VASA19) cannot reach LDAP server 10.3.87.x
  → ASA marks it FAILED → syslog %ASA-2-113022
  → collector ljcmgt14 → /var/log/ASA/JPNDH-VASA19-ALJ.log
  → Dynatrace Grail logs
  → detector every minute, last 5 min, parse ldap_server
       one problem per failed server (high)
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → no new FAILED line for 5 min → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `19-cisco-vpn-ldap-failed-per-server-tf.tf` | Full Terraform. |
| `19-cisco-vpn-ldap-failed-per-server-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `19.sh` | Commands, one per line. |

This replaces answer 18. Apply from one folder only, because both use the same resource name.

## Commands

All commands are in [`19.sh`](./19.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/19-cisco-vpn-ldap-failed-per-server-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/19-cisco-vpn-ldap-failed-per-server-tf
git commit -m "Cisco VPN LDAP failed per server detector"
git push
```
