# Cisco VPN LDAP Alert Terraform

## Decision Tree

```
Splunk: index=networksyslog sourcetype=cisco:asa *Windows_LDAP as FAILED*, > 3 in 1 minute
 → Dynatrace static-threshold detector (critical, pages via standard flow)
   real data: 1 line per failed LDAP server, 2 lines in 30 days
     keep Splunk rule ("3")  → will almost never fire
     alert on first line ("0") → recommended
   detector shows no data? → check.dql query 1 → fix log.source / host filter
   seq 4, 21 or 22 (2026-10-05) applied? → remove; same resource name
```

## Short Takeaway

| Question | Answer |
|---|---|
| What does the alert watch? | Cisco ASA saying it marked a Windows LDAP server as FAILED |
| Real message | `%ASA-2-113022: AAA Marking LDAP server 10.3.87.2 in aaa-server group Windows_LDAP as FAILED` |
| Where it comes from | Host `ljcmgt14.ads-jp.intraxa`, file `/var/log/ASA/JPNDH-VASA19-ALJ.log` |
| Dynatrace shape | 1 static-threshold detector, no workflow |
| Biggest finding | One line per failed server, so "more than 3 in 1 minute" never fired on real events |
| Recommendation | Change `ldap_failed_threshold` from "3" to "0" |

## Summary

The Splunk search looks for ASA messages that mark the Windows LDAP server group as FAILED. The real events show the ASA writes one line per server, on separate days, so the Splunk condition "more than 3 per minute" would not have alerted even when a server really failed. The Terraform keeps "3" to copy Splunk, with a one-line switch to "0" so the first FAILED line raises a critical problem.

## What The Log Line Means

| Part | Value | What it means |
|---|---|---|
| Time | Sep 24 20:29:04 | When the ASA logged it |
| Sender | 10.15.66.91 | The ASA firewall |
| `%ASA-2-113022` | Severity 2 (critical), message 113022 | ASA stopped trusting an AAA server |
| `LDAP server 10.3.87.2` | The server that failed | The other server seen is 10.3.87.1 |
| `aaa-server group Windows_LDAP` | The login group for VPN | VPN logins with Windows credentials use it |
| `as FAILED` | Marked unusable | If both servers fail, Windows VPN logins fail |

## Splunk Settings Mapped

| Splunk | Dynatrace |
|---|---|
| `index="networksyslog" sourcetype=cisco:asa` | `contains(log.source, "/var/log/ASA/")` or `host.name` ljcmgt14 (confirm) |
| `*Windows_LDAP as FAILED*` | `contains(content, "Windows_LDAP as FAILED")` plus `%ASA-2-113022` |
| Last 1 minute, every minute | `slidingWindow = 1`, 1-minute series |
| Results > 3 | `threshold = local.ldap_failed_threshold` ("3", or "0" recommended) |
| Severity Critical | `alert.severity = critical` |
| PagerDuty and email | Standard flow, `pagerduty.enabled = 1`; key not copied |
| No throttle | `dealertingSamples = 15`: one problem until 15 quiet minutes |

## The Query

```
fetch logs
| filter contains(log.source, "/var/log/ASA/") or matchesValue(host.name, "ljcmgt14*")
| filter contains(content, "%ASA-2-113022")
| filter contains(content, "Windows_LDAP as FAILED")
| makeTimeseries count = count(default: 0), interval:1m
```

## Threshold Choice

| Setting | Behaviour on the Sep 23 and Sep 24 events | When to use |
|---|---|---|
| "3" (Splunk copy) | No alert | Only if the team wants identical behaviour |
| "0" (recommended) | Alert on each day | When any LDAP server marked FAILED should page |

## Differences From The 2026-10-05 Versions

| Topic | Seq 4, 21, 22 | This file |
|---|---|---|
| Filter | Guessed `dt.system.bucket` network* | Real path `/var/log/ASA/` and host ljcmgt14 |
| Message match | Text only | Text plus `%ASA-2-113022` |
| Threshold | Fixed 3 | Switch in `locals` |
| Email workflow | Seq 21 and 22 had one | None (Terraform detector only) |
| Provider block | Missing in 21 and 22 | Included |

## Data Flow

```
Cisco ASA JPNDH-VASA19 → syslog → ljcmgt14 (/var/log/ASA/JPNDH-VASA19-ALJ.log)
  → Dynatrace logs (Grail)
  → detector each minute: FAILED lines > threshold ?
      yes → problem (critical, Cisco VPN, page) → standard SILVA / PagerDuty flow
  → 15 quiet minutes → close
```

## Investigation

| Checked | Evidence |
|---|---|
| Splunk alert screen | Last 1 minute, cron */1, results > 3, Critical, PagerDuty and email |
| Splunk search results | 2 events between 9/6 and 10/6 |
| Event fields | host ljcmgt14.ads-jp.intraxa, source /var/log/ASA/JPNDH-VASA19-ALJ.log |
| Message pattern | One line per LDAP server (10.3.87.1 and 10.3.87.2), different days |
| Earlier answers | Seq 4, 21, 22 on 2026-10-05 used a guessed filter |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm how the ASA lines arrive |
| 2 | Run query 2; you should see the Sep 23 and Sep 24 lines |
| 3 | Decide on threshold "3" or "0" with the network team |
| 4 | `terraform plan` shows 1 to add |
| 5 | Remove any applied 2026-10-05 version first |

## Related Files

| File | Purpose |
|---|---|
| `1-cisco-vpn-ldap-alert-terraform.tf` | Detector Terraform |
| `1-cisco-vpn-ldap-alert-terraform-check.dql` | 4 check queries |
| `1.sh` | Commands |

## Commands

See `1.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/1-cisco-vpn-ldap-alert-terraform"
terraform init
terraform validate
terraform plan
```
