# IWFM Three Alerts Records

## Decision tree

```
3 IWFM-related Splunk alerts (search=iwfm)
 converted before? → yes, 2026-10-05 seq 32, but static threshold + makeTimeseries + renamed titles
   → rebuild as Records detectors (today's standard), keep Splunk titles
   → seq 32 applied? → destroy it first, or both versions alert

 EIP006 service Failure     → GenerateFormImage-v2 + Status=FAILURE, 1 min, > 2  → high,   pd 0
 Compass IWFMReportException → "IWFMReportException", 5 min, > 15                 → medium, pd 0
 IWFM_Errors                → fmwsagentlog Caution/Fatal, 1 hour, > 0             → medium, pd 0

 before apply → run check.dql:
   Status only in text?            → content filter already covers it
   Compass namespace known?        → add k8s.namespace.name filter
   fmwsagentlog log.source differs → fix matchesValue(log.source, ...)
```

## Short takeaway

| Question | Answer |
|---|---|
| How many detectors? | Three, one per Splunk alert, all in one tf file. |
| Were they converted before? | Yes, on 10-05 (seq 32), with the old analyzer. This version replaces it. |
| PagerDuty | "0" for all three. Each alert only sends email. |
| Severity | EIP006 is high (email priority High). The other two are medium (priority Normal). |
| Biggest open point | Where these logs live in Grail. Run the check queries before apply. |

## Summary

All three are simple "count matching log lines in a window and compare to a number" alerts. In Dynatrace each one becomes a Records detector that counts the lines, keeps the row only when the count is over the Splunk threshold, and opens one problem. The problem closes on its own when the count drops back under the threshold.

## Investigation

### Alert 1: EIP - IWFM : EIP006 service Failure Alert

| Setting | Value |
|---|---|
| Description | Checks EIP006 services that depend on the backend provider system IWFM. |
| Search | `index=eip1015 sourcetype=eip_mediator_serverlog jp-Distributing-Sell-GenerateFormImage-v2-vs* Status=FAILURE` |
| Schedule | Cron `*/1`, last 1 minute |
| Expires | 24 hours |
| Trigger | Number of results greater than 2, once, for each result, no throttle |
| Action | Send email, priority High. I did not copy the recipients. |

### Alert 2: [Prod]ALJ-Compass-IWFMReportException発生

| Setting | Value |
|---|---|
| Search | `index=compass-prod-axa-li-jp "IWFMReportException"` |
| Schedule | Cron `*/5`, last 5 minutes |
| Expires | 1500 days |
| Trigger | Number of results greater than 15, once, for each result, no throttle |
| Action | Send email, priority Normal. I did not copy the recipients. |

### Alert 3: IWFM_Errors

| Setting | Value |
|---|---|
| Search | `index=iwfm sourcetype=fmwsagentlog earliest=-1h (LOGLEVEL="Caution" OR LOGLEVEL="Fatal") \| transaction host AGENTID maxspan=1s` |
| Schedule | Every hour at 15 minutes past the hour |
| Expires | 24 hours |
| Trigger | Number of results greater than 0, once, for each result |
| Throttle | Suppress for 1 hour |
| Action | Send email, priority Normal. I did not copy the recipient. |

### How the Splunk parts map to Dynatrace

| Splunk part | Dynatrace equivalent |
|---|---|
| Last 1 minute, 5 minutes, or 1 hour | `fetch logs, from:now()-1m`, `-5m` or `-1h` |
| Search words like `Status=FAILURE` | `contains(content, ...)`, plus the attribute check when one exists |
| Number of results greater than N | `summarize count()` then `filter count > N` |
| `transaction host AGENTID maxspan=1s` | Not needed. Any Caution or Fatal line makes the count greater than 0. |
| Throttle 1 hour | The problem stays open while errors exist in the last hour, so it does not re-notify. |
| Email priority High | `alert.severity` high |
| Email priority Normal | `alert.severity` medium |

## Result

| Detector | Window | Fires when | Severity | PagerDuty |
|---|---|---|---|---|
| `eip_iwfm_eip006_service_failure` | 1 minute | failures > 2 | high | "0" |
| `compass_iwfm_report_exception` | 5 minutes | exceptions > 15 | medium | "0" |
| `iwfm_errors` | 1 hour | errors > 0 | medium | "0" |

Things to confirm before apply:

| Item | Why it matters |
|---|---|
| EIP006 1-minute window | Logs that arrive late can miss a 1-minute window. If query 4 shows a lower count than Splunk, widen it to 2 minutes and keep `> 2`. |
| Compass source | Without a namespace filter, any app logging "IWFMReportException" counts. Add `k8s.namespace.name` from query 2. |
| IWFM log.source | The filter `*fmwsagentlog*` is a guess. If query 3 shows a different source, the detector will never fire. |
| Old seq 32 detectors | They have different titles, so applying this file will not replace them. Destroy them from the 10-05 folder if they were applied. |

## Data flow map

```
EIP mediator server log (eip1015)
  → GenerateFormImage-v2 + Status=FAILURE → count in 1 min → > 2 → problem (high) → email route

Compass prod pods (compass-prod-axa-li-jp)
  → "IWFMReportException" → count in 5 min → > 15 → problem (medium) → email route

IWFM agent log (fmwsagentlog)
  → LOGLEVEL Caution or Fatal → count in 1 h → > 0 → problem (medium) → email route
     (stays open while errors continue = 1-hour throttle)
```

## Related files

| File | What it is |
|---|---|
| `69-iwfm-three-alerts-records-tf.tf` | Three Records detectors |
| `69-iwfm-three-alerts-records-tf-check.dql` | Log source checks and a 1-day dry run |
| `69-iwfm-three-alerts-records-tf.spl` | Splunk-side counts to compare against |
| `69.sh` | Commands |

## Commands

These are in `69.sh`. Nothing has been run. Run the destroy lines only if 10-05 seq 32 was applied.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/32-iwfm-splunk-alerts-transform"
terraform state list
terraform plan -destroy -target='dynatrace_davis_anomaly_detectors.iwfm'
terraform destroy -target='dynatrace_davis_anomaly_detectors.iwfm'
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/69-iwfm-three-alerts-records-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
