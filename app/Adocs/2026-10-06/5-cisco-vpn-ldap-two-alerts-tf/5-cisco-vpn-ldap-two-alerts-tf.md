# Cisco VPN LDAP Two Alerts

## Decision Tree

```
2 Splunk alerts, same text "Windows_LDAP as FAILED", different index and sourcetype
 → 1 Terraform file, for_each over 2 Records detectors
 check.dql query 3:
   two different log.source values → keep both
   one log.source only → both fire on the same line → keep only one enabled
 alert 1 finds nothing → fix its first filter with the log.source from query 3
```

## Short Takeaway

| Question | Answer |
|---|---|
| How many detectors | 2, in one resource with `for_each` |
| Query style | 3 lines, no makeTimeseries (Records data type) |
| Alert 1 | Splunk `index=*network* sourcetype=asa_networksyslog` |
| Alert 2 | Splunk `index="networksyslog" sourcetype=cisco:asa` ("using windows basic") |
| Settings | Same for both: critical, pages, one problem per host |
| Risk | Double paging if both match the same log lines |

## Summary

The two Splunk alerts differ only in the alert name and in the index and sourcetype they search. Every other setting is the same. In Dynatrace they become two Records detectors created from one `locals` map. The first filter line in alert 1 is a best guess for where the `asa_networksyslog` data lands, so confirm it before applying.

## Splunk To Dynatrace

| Splunk | Alert 1 | Alert 2 |
|---|---|---|
| Name | ...impact end users | ...impact end users using windows basic |
| Search scope | `index=*network* sourcetype=asa_networksyslog` | `index="networksyslog" sourcetype=cisco:asa` |
| Dynatrace first filter | log.source contains networksyslog or /var/log/ASA/ | log.source /var/log/ASA/ or host ljcmgt14 |
| Text filter | `Windows_LDAP as FAILED` | `Windows_LDAP as FAILED` |

| Splunk setting (both) | Dynatrace |
|---|---|
| Last 1 minute, every minute | Records detector runs every minute and looks back 2 hours |
| Results > 3 | Not used; any FAILED line alerts |
| Expires 24 hours | No equivalent; the problem history stays in Dynatrace |
| Trigger For each result | `alertIdentityFields[0] = host.name`, one problem per host |
| Critical, PagerDuty, email | `alert.severity critical`, `pagerduty.enabled 1`, standard flow |

## Data Flow

```
ASA syslog → Grail
  ├─ detector 1 (asa_networksyslog filter) → critical problem → page
  └─ detector 2 (windows basic filter)     → critical problem → page
  same line in both? → 2 pages → disable one
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot 1 | index=*network*, sourcetype=asa_networksyslog |
| Screenshot 2 | index="networksyslog", sourcetype=cisco:asa |
| Other settings | Identical in both screenshots |
| PagerDuty key | Not visible and not copied |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 3 to see which log.source values exist |
| 2 | Adjust the alert 1 first filter if needed |
| 3 | `terraform plan` shows 2 to add |
| 4 | Don't apply in the same folder as seq 1 to seq 4 |

## Related Files

| File | Purpose |
|---|---|
| `5-cisco-vpn-ldap-two-alerts-tf.tf` | Two detectors in one file |
| `5-cisco-vpn-ldap-two-alerts-tf-check.dql` | Check queries |
| `5.sh` | Commands |
