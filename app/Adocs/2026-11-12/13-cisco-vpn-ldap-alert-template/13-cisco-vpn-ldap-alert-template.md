# Cisco VPN LDAP Alert Template

```
Splunk alert
  search finds Windows_LDAP and FAILED
  last 1 minute
  more than 3 results
  trigger once
    detector returns one row only when the count is greater than 3
    event.type is CUSTOM_ALERT
    title starts with ALJ_VPN
  profile
    severity level ERROR
    title begins with ALJ_VPN
  email
    same profile
    addresses are inside the collapsed Send email action
```

| Splunk field | Template field |
|---|---|
| Last 1 minute | `from: now()-1m` |
| Number of results greater than 3 | `summarize` then `filter failed_count > 3` |
| Trigger once | One row, identity `alert_key` |
| Add to Triggered Alerts, Critical | `event.type` `CUSTOM_ALERT` |
| PagerDuty action is present | `pagerduty.enabled` is `1` |
| Send email is collapsed | `to` is not filled in |

## Summary

The detector stays quiet until the last minute has more than 3 lines that contain `Windows_LDAP` and `FAILED`. It then raises one `CUSTOM_ALERT` whose name starts with `ALJ_VPN`. A new profile matches that prefix. The OCP4 profile stays on the happy-future alerts.

## Investigation

| Item on the Splunk form | Value |
|---|---|
| Name | Cisco VPN : LDAP Connections are failing which will impact end users using windows basic |
| Search | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` |
| Schedule | Every minute. Time range Last 1 minute. |
| Trigger | Number of results is greater than 3, once. |
| Throttle | Unchecked. |
| Actions | Triggered Alerts at Critical, PagerDuty, Send email. |
| Description | LDAP failures caused by backend issues that affect VPN users and business users. The box is cut off after "that are us". |

The index and sourcetype are not in the DQL yet. The Dynatrace field names for those two Splunk fields are not on this screen.

## Result

The file [13-cisco-vpn-ldap-alert.tf](13-cisco-vpn-ldap-alert.tf) has the detector and the profile. Paste the email addresses from the Splunk **Send email** action into `to` before use.

`pagerduty.enabled` is `1` because this alert has a PagerDuty action. The happy-future detector used `0`. The PagerDuty integration key is inside the collapsed action and is not in this file.

`alert.severity` stays `medium`, and the profile severity level stays `ERROR`, matching the working pair. The Splunk label Critical is the Triggered Alerts severity.

Throttle is off in Splunk, so Splunk can send again every minute. The identity field keeps one Dynatrace problem open while the count stays above 3. A new mail is sent when that problem opens, and when it closes, because `notify_closed_problems` is true.

## Data flow map

```
cisco:asa syslog line
  contains Windows_LDAP
  contains FAILED
        |
        v
last 1 minute
  count greater than 3
        |
        v
one CUSTOM_ALERT
  name starts with ALJ_VPN
        |
        v
ALJ_VPN profile
  severity level ERROR
        |
        v
email
  PagerDuty flag is 1
```

## Related files

| File | Purpose |
|---|---|
| `13-cisco-vpn-ldap-alert.tf` | Detector and alerting profile. |
| `0-pic.md` | How the Splunk trigger maps. |
| `1-investigation.md` | The values read from the form. |
| `2-result.md` | What is included and what is still blank. |
| `3-glossary.md` | The words. |
| `13-cisco-vpn-ldap-alert-template-follow.txt` | The same notes for a phone. |
| `13.sh` | Copy commands. |

Commands: [13.sh](13.sh)
