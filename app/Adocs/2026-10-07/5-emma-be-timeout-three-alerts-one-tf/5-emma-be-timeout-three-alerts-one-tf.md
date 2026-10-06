# Emma BE Timeout Three Alerts One Detector

## Decision Tree

```
3 Splunk alerts, identical search and trigger, different actions
 → 1 Dynatrace detector, pagerduty.enabled = "1"
   standard flow sends SILVA + PagerDuty + email → covers every action of the 3
 migrate all 3? → same timeout pages on-call 3 times → don't
 PagerDuty integration key visible in Splunk → never copy; the standard flow owns PagerDuty
```

## Short Takeaway

| Question | Answer |
|---|---|
| How many Splunk alerts | 3 with the same search |
| How many Dynatrace detectors | 1 |
| PagerDuty | "1" |
| Severity | high |
| Which file to apply | This one only (replaces 2026-10-07 seq 1 and seq 4) |
| Secrets | PagerDuty integration key not copied |

## Summary

Splunk has three alerts with the same search, threshold and throttle. They differ only in how they notify: email plus Alert Status Manager, Triggered Alerts plus PagerDuty plus email, and PagerDuty alone. In Dynatrace, notification is handled by the standard flow, so one detector with `pagerduty.enabled = "1"` gives SILVA, PagerDuty and email together. All three Splunk alerts can be retired against this one detector.

## The Three Splunk Alerts

| Splunk alert | Actions | Covered by the one detector |
|---|---|---|
| ESG - Emma BE timeout to ESG Production | Send email (High), Alert Status Manager with PagerDuty Enable | Yes |
| Prod_Life_Emma_EmmaBETmeoutToESGProduction_High | Triggered Alerts (High), PagerDuty, Send email | Yes |
| Prod_Life_Emma_EmmaBETmeoutToESGProduction_High_PagerDuty | PagerDuty only | Yes |

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| Search part 1 (backend SocketTimeoutException) | `startsWith(host.name, "myaxabackend-")` plus two `contains` checks |
| `append` search part 2 (API gateway timed out) | `or` with `/SYSLOG/APIGW/prod/` plus three `contains` checks |
| Last 5 minutes, cron */5 | `from:now()-5m`, checked every minute |
| Results > 20 | `summarize count`, then `filter count > 20` |
| Throttle 60 seconds | Identity field `check`: one open problem |
| High | `alert.severity high` |
| PagerDuty (with integration key) | `pagerduty.enabled 1`; the key lives in the standard flow, not here |
| Send email | Standard flow email |

## Data Flow

```
Emma BE pods → S3 log forwarder → Grail ─┐
API gateway → /SYSLOG/APIGW/prod/local4.log ─┴→ timeouts in last 5 min
   > 20 → ONE High problem → standard flow → SILVA + PagerDuty + email
```

## Investigation

| Checked | Finding |
|---|---|
| New alert | _High_PagerDuty: same search, > 20, throttle 60 seconds, PagerDuty action only |
| PagerDuty action | Integration URL empty; integration key filled in (not copied) |
| Backend search | 5 events on 10/6, Read timed out, nested java.net.SocketTimeoutException |
| API gateway search | 322,863 events from /SYSLOG/APIGW/prod/local4.log |
| Earlier answers | Seq 1 and seq 4 today use the same resource name and logic |

## Result

| Step | What to do |
|---|---|
| 1 | Apply only this file; don't apply seq 1 or seq 4 alongside it |
| 2 | Run check.dql queries 1 and 2 to confirm both sources |
| 3 | Review the threshold with query 3 |
| 4 | `terraform plan` shows 1 to add (or 1 to change) |
| 5 | Retire all three Splunk alerts once the detector is live |

## Related Files

| File | Purpose |
|---|---|
| `5-emma-be-timeout-three-alerts-one-tf.tf` | One detector for all three |
| `5-emma-be-timeout-three-alerts-one-tf-check.dql` | Check queries |
| `5.sh` | Commands |
