# Emma BE Timeout To ESG High

## Decision Tree

```
Prod_Life_Emma_EmmaBETmeoutToESGProduction_High
 same search as "ESG - Emma BE timeout to ESG Production"? → yes
   → migrate ONCE: same resource name, apply only one file
 actions: Triggered Alerts High + PagerDuty + email → pagerduty.enabled = "1"
 check.dql query 3 → busiest 5 minutes far below 20? → agree a lower threshold
```

## Short Takeaway

| Question | Answer |
|---|---|
| What it watches | Emma BE (OpenPaaS) calls to ESG (CoreIT) timing out |
| Same as another alert? | Yes, same search as "ESG - Emma BE timeout to ESG Production" |
| PagerDuty | `"1"`: the alert has a PagerDuty action |
| Severity | high (Triggered Alerts severity High) |
| Threshold | More than 20 timeouts in 5 minutes |
| Real volume | 5 backend timeouts on 10/6, so this only fires in a big outage |

## Summary

This Splunk alert uses the same two-part search as the ESG alert converted in seq 1 today. Only the name and actions differ: this one adds Triggered Alerts (High) and a direct PagerDuty action. The Terraform keeps the same resource name, so applying it updates one detector instead of creating two that would page twice.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| Search part 1 (backend SocketTimeoutException) | `startsWith(host.name, "myaxabackend-")` plus two `contains` checks |
| `append` search part 2 (API gateway timed out) | `or` with `/SYSLOG/APIGW/prod/` plus three `contains` checks |
| Last 5 minutes, cron */5 | `from:now()-5m`, checked every minute |
| Results > 20 | `summarize count`, then `filter count > 20` |
| Throttle 60 seconds | Identity field `check`: one open problem |
| Add to Triggered Alerts, High | `alert.severity high` |
| PagerDuty | `pagerduty.enabled 1` (key not copied) |
| Send email | Standard flow email |

## Seq 1 Compared With Seq 4

| Topic | Seq 1 (ESG - Emma BE timeout) | Seq 4 (this alert) |
|---|---|---|
| Title | Prod_ESG_EmmaBETimeout_High | Prod_Life_Emma_EmmaBETmeoutToESGProduction_High |
| Query and threshold | Same | Same |
| PagerDuty | 1 (Alert Status Manager) | 1 (PagerDuty action) |
| Resource name | esg_emma_be_timeout | esg_emma_be_timeout |

## Data Flow

```
Emma BE pods → S3 log forwarder → Grail ─┐
API gateway → /SYSLOG/APIGW/prod/local4.log ─┴→ timeouts in last 5 min
   > 20 → High problem → standard flow → SILVA + PagerDuty + email
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | Same search, > 20, throttle 60 seconds; Triggered Alerts High, PagerDuty, Send email |
| Backend search | 5 events on 10/6: BusinessCalendarServiceException, Read timed out, nested java.net.SocketTimeoutException |
| API gateway search | 460,221 events; host EEAA2015.ppprivmgmt.intraxa, /SYSLOG/APIGW/prod/local4.log |
| Duplicate | Same logic as 2026-10-07 seq 1 |

## Result

| Step | What to do |
|---|---|
| 1 | Pick one title (this one or seq 1) and apply only that file |
| 2 | Run check.dql queries 1 and 2 to confirm both sources |
| 3 | Run query 3 to review the threshold |
| 4 | `terraform plan` shows 1 to add (or 1 to change if seq 1 was applied) |

## Related Files

| File | Purpose |
|---|---|
| `4-emma-be-timeout-esg-high-tf.tf` | Detector Terraform |
| `4-emma-be-timeout-esg-high-tf-check.dql` | Check queries |
| `4.sh` | Commands |
