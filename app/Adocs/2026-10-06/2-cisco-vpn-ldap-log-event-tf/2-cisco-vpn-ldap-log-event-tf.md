# Cisco VPN LDAP Log Event

## Decision Tree

```
Remove makeTimeseries and the %ASA-2-113022 filter?
 makeTimeseries removed → a detector can't work (it needs a time series)
   → use a log event instead: one event per matching line
 %ASA-2-113022 removed → match only "Windows_LDAP as FAILED", same as Splunk
 event never appears?
   check.dql query 1 empty → query 2 → fix the log.source in the matcher
   lines found but no event → logs may go through OpenPipeline → use the seq 1 detector
```

## Short Takeaway

| Question | Answer |
|---|---|
| What changed from seq 1 | Both lines are gone |
| Why makeTimeseries could go | The alert type changed from a detector to a log event |
| What a log event does | Raises an event on each log line that matches |
| Matcher | `matchesValue(log.source, "/var/log/ASA/*") AND matchesPhrase(content, "Windows_LDAP as FAILED")` |
| Threshold | None; each FAILED line alerts (what seq 1 called "0") |

## Summary

The anomaly detector in seq 1 needs a per-minute series, which is why it had `makeTimeseries`. The `dynatrace_log_events` resource has no such requirement. It checks every incoming log line against a matcher and raises a critical event when a line matches. The `%ASA-2-113022` filter was extra, so the matcher now matches the same text as the Splunk search.

## Detector vs Log Event

| Topic | Seq 1 detector | Seq 2 log event |
|---|---|---|
| Resource | `dynatrace_davis_anomaly_detectors` | `dynatrace_log_events` |
| Query type | DQL that returns a time series | Log matcher, no `fetch` and no `makeTimeseries` |
| Counting | "More than N per minute" | Every matching line |
| Splunk "> 3" | Possible | Not possible (never fired on real data anyway) |
| Close | After 15 quiet minutes | Event closes on its own; no dealerting setting |

## Data Flow

```
ASA → syslog ljcmgt14 (/var/log/ASA/...) → Dynatrace log ingest
  → matcher matches "Windows_LDAP as FAILED"? → CUSTOM_ALERT event (critical, Cisco VPN, page)
  → standard SILVA / PagerDuty flow
```

## Investigation

| Checked | Finding |
|---|---|
| Detector rules | Detector queries must return a time series |
| Provider docs | `dynatrace_log_events` takes a matcher and an event template with metadata |
| Splunk search | Filters only index, sourcetype and the text, with no message code |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. You should see the Sep 23 and Sep 24 lines. |
| 2 | If it is empty, use query 2 and fix the `log.source` value |
| 3 | `terraform plan` shows 1 to add |
| 4 | Do not apply together with seq 1 (same resource name) |

## Related Files

| File | Purpose |
|---|---|
| `2-cisco-vpn-ldap-log-event-tf.tf` | Log event Terraform |
| `2-cisco-vpn-ldap-log-event-tf-check.dql` | Check queries |
| `2.sh` | Commands |

## Commands

See `2.sh`.
