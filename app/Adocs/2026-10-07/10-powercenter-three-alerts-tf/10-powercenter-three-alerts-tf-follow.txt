# PowerCenter Three Alerts

## Decision Tree

```
3 Splunk alerts, same search "ISP_MASTER_ELECT_LOCK", different window and threshold
 → 1 file, for_each, 3 Records detectors (summarize count → filter count > threshold)
 overlap: ProcessStop (> 0 in 15 min) fires whenever the other two fire
   → recommended: keep ProcessStop only, set enabled = false on the other two
 check.dql query 1 → which host and log file?
   → add that filter so other indexes can't match
 query 4 empty → PowerCenter logs not in Dynatrace → ingest first
```

## Short Takeaway

| Question | Answer |
|---|---|
| What ISP_MASTER_ELECT_LOCK means | The Informatica domain is trying to elect a new master node, which usually means a node or service went down |
| How many Splunk alerts | 3, same search |
| Difference | Time window, threshold, email priority and recipients |
| Dynatrace | 3 detectors from one `locals` map with `for_each` |
| Recommendation | Keep only PowerCenter-ProcessStop: it catches every case the other two catch |
| Notification | Email only for all three: `pagerduty.enabled = "0"` |

## Summary

All three Splunk alerts watch for the Informatica message `ISP_MASTER_ELECT_LOCK`, which shows up when the PowerCenter domain loses its master node. They differ only in sensitivity: more than 2 in 1 minute, more than 0 in 15 minutes, and more than 3 in 1 minute. The one-file Terraform keeps all three for a faithful migration. ProcessStop is the most sensitive, so the other two only add duplicate emails.

## The Three Alerts

| Splunk alert | Window | Fires when | Severity | Recipients (not copied) |
|---|---|---|---|---|
| 0031_MWSP-PowerCenter-Service-Down-Alert | Last 1 minute, every minute | More than 2 lines | medium (Normal) | bom_cts and pd_mw_extended lists |
| PowerCenter-ProcessStop | Last 15 minutes, every minute | More than 0 lines | high (High) | infra_mwsp list |
| Powercenter down | Last 1 minute, every minute | More than 3 lines | medium (Normal) | pd_mw_extended and infra_mwsp lists |

## Why ProcessStop Covers The Other Two

| Situation | 0031 (> 2 in 1 min) | ProcessStop (> 0 in 15 min) | Powercenter down (> 3 in 1 min) |
|---|---|---|---|
| 1 line | No | Yes | No |
| 3 lines in 1 minute | Yes | Yes | No |
| 4 lines in 1 minute | Yes | Yes | Yes |

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index="powercenter"` | Not mapped yet; add a host or log.source filter after check.dql query 1 |
| `ISP_MASTER_ELECT_LOCK` | `contains(content, "ISP_MASTER_ELECT_LOCK")` |
| Last 1 or 15 minutes | `from:now()-1m` or `from:now()-15m` (`window` in locals) |
| Number of results > N | `summarize count = count()` then `filter count > N` (`threshold` in locals) |
| Runs every minute | Records detector runs every minute |
| For each result | One problem per alert (`alertIdentityFields[0] = check`) |
| Priority High or Normal | `alert.severity` high or medium |
| Send email only | `pagerduty.enabled 0` |

## Query (per detector)

```
fetch logs, from:now()-<window>
| filter contains(content, "ISP_MASTER_ELECT_LOCK")
| summarize count = count()
| filter count > <threshold>
| fieldsAdd check = "<alert key>"
```

## Data Flow

```
Informatica domain (PowerCenter) → master node lost → ISP_MASTER_ELECT_LOCK in logs → Grail
  → every minute, per detector: count in window > threshold?
      0031:        > 2 in 1 min  → medium → email
      ProcessStop: > 0 in 15 min → high   → email
      Down:        > 3 in 1 min  → medium → email
```

## Investigation

| Checked | Finding |
|---|---|
| 0031 screenshot | Last 1 minute, */1, > 2, Once, For each result, email Normal |
| ProcessStop screenshot | Last 15 minutes, cron * * * * *, > 0, email High |
| Powercenter down screenshot | Last 1 minute, */1, > 3, email Normal, subject "Splunk Alert Middleware Alert" |
| Sample events | None shown, so the host and log file are unknown |
| 1-minute windows | Late log arrival can make 1-minute counts miss; 2 to 5 minutes is safer |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql queries 1 and 4 to find the PowerCenter log source |
| 2 | Add that host or log.source filter to the query |
| 3 | Agree with the middleware team to keep only ProcessStop; set `enabled = false` on the others |
| 4 | `terraform plan` shows 3 to add |

## Related Files

| File | Purpose |
|---|---|
| `10-powercenter-three-alerts-tf.tf` | Three detectors in one file |
| `10-powercenter-three-alerts-tf-check.dql` | Check queries |
| `10.sh` | Commands |
