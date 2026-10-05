# Cisco VPN LDAP Two Alerts Transform

## Decision tree

```
2 Splunk alerts, same message "Windows_LDAP as FAILED"
 A: index=network*        sourcetype=asa_networksyslog
 B: index="networksyslog" sourcetype=cisco:asa
 same ASA events through two syslog paths?  → very likely (network* includes networksyslog) → today they double page
   → ONE Dynatrace detector across network* buckets, dedup identical lines
 every 1 min, last 1 min, > 3, once, no throttle → threshold 3, window 1, violating 1, dealerting 5
 Critical + PagerDuty                        → problem goes through the standard SILVA + PagerDuty workflow
   custom alert has no entity → no AGO tags  → SILVA group missing → standard flow skips → fix routing (see below)
 Send email                                   → small email workflow (recipients not visible in screenshot)
 repo still uses dynatrace_log_alert style?   → house-style.tf provided, but only main.tf really applies
```

## Short takeaway

| Question | Answer |
|---|---|
| What do the 2 alerts watch? | Cisco ASA marking the `Windows_LDAP` server group FAILED, so VPN users with Windows login can't connect |
| Why are there 2? | Same message, two indexes and sourcetypes (old and new syslog path). `network*` already includes `networksyslog` |
| Dynatrace shape | 1 detector (count > 3 per minute) plus 1 email workflow |
| Duplicates | `dedup timestamp, content` so one ASA line counted twice doesn't trigger early |
| Paging | Through the standard SILVA and PagerDuty workflow. Needs a routing fix because the ASA has no AGO tags |
| Files | `main.tf` (real resources), `house-style.tf` (repo layout), `check.dql` |

## Summary

Both Splunk alerts look for the same ASA message; they only differ in which index and sourcetype they read. Because `index=network*` already covers `networksyslog`, an LDAP outage probably paged twice. In Dynatrace there's one copy of the log data, so one detector is enough: count "Windows_LDAP as FAILED" lines per minute across the network buckets and open a critical problem above 3. The `dedup` step protects against the same line arriving through both syslog paths. Paging and the SILVA ticket come from your standard problem workflow, but that workflow finds the support group from entity tags, and a log-based custom alert has no entity, so you must give it a route.

## The two Splunk alerts

| Setting | Alert A | Alert B |
|---|---|---|
| Name | ...impact end users | ...impact end users using windows basic |
| Index | `network*` | `networksyslog` |
| Sourcetype | `asa_networksyslog` | `cisco:asa` |
| Search text | `*Windows_LDAP as FAILED*` | `*Windows_LDAP as FAILED*` |
| Schedule | Every minute, last 1 minute | Same |
| Trigger | More than 3 results, once | Same |
| Throttle | Off | Off |
| Actions | Triggered alert Critical, PagerDuty, email | Same |

## Splunk to Dynatrace mapping

| Splunk | Dynatrace |
|---|---|
| `index=network*` and `index=networksyslog` | `matchesValue(dt.system.bucket, "network*")` (confirm with `check.dql` query 1) |
| `sourcetype=...` | Dropped, so both paths are covered |
| `*Windows_LDAP as FAILED*` | `contains(content, "Windows_LDAP as FAILED", caseSensitive: false)` |
| Cron every minute, last 1 minute | `makeTimeseries ... interval:1m`, sliding window 1 |
| Results greater than 3 | Threshold 3, Above, violating samples 1 |
| Trigger once, throttle off | One problem stays open while it breaches; closes after 5 clean minutes |
| Triggered alert Critical | `alert.severity = critical` |
| PagerDuty | Standard SILVA and PagerDuty workflow |
| Send email | Email workflow |

## Detector query

```dql
fetch logs
| filter matchesValue(dt.system.bucket, "network*")
| filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
| dedup timestamp, content
| makeTimeseries count = count(default: 0), interval:1m
```

| Setting | Value |
|---|---|
| Threshold | 3, Above |
| Sliding window | 1 |
| Violating samples | 1 |
| Dealerting samples | 5 |
| alert.severity | critical |

If `check.dql` query 2 shows no duplicates, you can drop the `dedup` line.

## Routing gap: PagerDuty and SILVA

| Step in the standard flow | What happens for this alert |
|---|---|
| Trigger on any new problem (custom included) | Fires |
| extract-event-tags looks for `AGO_AXA_SupportGroup` and similar tags | None: the problem comes from a log query, not a monitored host |
| SILVA preview | Not ready (no assignment group), so the SILVA post is skipped |
| PagerDuty severity | Standard flow sends `error` only for Infrastructure impact, otherwise `warning`. Splunk sent Critical |

Options, from simplest:

| Option | What you do |
|---|---|
| 1. Add a fallback in the standard flow | When no group tag is found, read an event property such as `ago.support_group` set by the detector (needs a new numbered version of the standard workflow) |
| 2. Tie the event to a tagged entity | If the ASA exists as a custom device or network device entity with AGO tags, set `dt.source_entity` in the detector event so tags flow to the problem |
| 3. Direct PagerDuty task | Add a PagerDuty Events v2 task (severity critical, sensitive routing key) to the email workflow, like the BRE alert. SILVA ticket still needs option 1 or 2 |

## Data flow

```
Cisco ASA (ASA-2-113022 "... Windows_LDAP as FAILED")
  → syslog (old path and new path) → Dynatrace → Grail bucket network*
  → detector every minute: dedup, count > 3 in 1 minute
  → problem "Cisco VPN : LDAP Connections are failing..." (critical)
  → standard flow: SILVA incident + PagerDuty (after routing fix)
  → email workflow → network team with the last 10 minutes of lines
  → 5 clean minutes → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Screenshot 1 | Alert A: `index=network* sourcetype=asa_networksyslog`, every minute, > 3, Critical, PagerDuty, email |
| Screenshot 2 | Alert B: `index="networksyslog" sourcetype=cisco:asa`, same settings, name ends "using windows basic" |
| Earlier answers | Seq 3 (conversion) and seq 4 (Terraform for alert A) |
| Standard flow v7.1 | Support group comes only from entity tags; PagerDuty severity is error or warning |
| Email recipients | Collapsed in the screenshot, so a placeholder is used |

## Result

Merge both Splunk alerts into one detector with dedup, add the email workflow, and fix routing so the critical problem reaches SILVA and PagerDuty. Run `check.dql` first to confirm the bucket name and whether lines are duplicated.

## Related files

| File | Purpose |
|---|---|
| `21-cisco-vpn-ldap-two-alerts-transform-main.tf` | Real detector and email workflow |
| `21-cisco-vpn-ldap-two-alerts-transform-house-style.tf` | Same alert in the repo's `dynatrace_log_alert` layout |
| `21-cisco-vpn-ldap-two-alerts-transform-check.dql` | Bucket, duplicate and frequency checks |
| `21.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/3-cisco-vpn-ldap-alert-to-dynatrace/` | First conversion |
| `2026-10-05/4-cisco-vpn-ldap-alert-terraform/` | Earlier Terraform for alert A |
| `2026-10-01/36-standard-flow-preview-then-post/` | Standard SILVA and PagerDuty workflow |

## Commands

See `21.sh` (not run).
