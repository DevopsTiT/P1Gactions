# IWFM Splunk Alerts Transform

## Decision tree

```
3 Splunk alerts around IWFM
 each one = "count lines, fire above N" → detector (no workflow needed)
   EIP006 FAILURE > 2 in 1 min        → threshold 2, per minute
   IWFMReportException > 15 in 5 min  → arrayMovingSum(count, 5), threshold 15
   IWFM agent Caution or Fatal, hourly + 1 h throttle → threshold 0, dealerting 60
 Splunk field (Status=, LOGLEVEL=)?   → check.dql query 2, may only be inside content
 index name looks like a namespace?   → compass-prod-axa-li-jp → k8s.namespace.name (CONFIRM)
 _Normal alerts + standard flow?      → would page, decide skip rule (same as earlier seqs)
```

## Short takeaway

| Question | Answer |
|---|---|
| How many Dynatrace resources? | 3 detectors in one `for_each` block |
| Any merges? | No. Three different systems and signals |
| Biggest change | IWFM_Errors moves from an hourly check to near real time, with one problem per hour of errors |
| Odd Splunk setting | IWFM_Errors uses `transaction`, but with "results > 0" it just means "any Caution or Fatal line" |
| What must be confirmed | Field names for three indexes, and how Status and LOGLEVEL appear in the raw line |

## Summary

All three alerts count log lines and fire above a number, which is exactly what a Dynatrace detector does. EIP006 fires on more than 2 failures a minute, Compass on more than 15 report exceptions in 5 minutes, and the IWFM agent on any Caution or Fatal line, held open for an hour like the Splunk throttle.

## Mapping

| Splunk alert | Splunk logic | Dynatrace detector | Settings |
|---|---|---|---|
| EIP - IWFM : EIP006 service Failure Alert | Last 1 min, every min, > 2, High | `Prod_EIP_IWFM_EIP006ServiceFailure_High` | threshold 2, violating 1, window 5, dealerting 5, high |
| [Prod]ALJ-Compass-IWFMReportException発生 | Last 5 min, every 5 min, > 15, Normal | `Prod_Compass_IWFMReportException_Normal` | 5-minute moving sum, threshold 15, dealerting 5, medium |
| IWFM_Errors | Last 1 h at :15 each hour, > 0, throttle 1 h | `Prod_IWFM_AgentErrors_Normal` | threshold 0, dealerting 60, medium |

## Queries

```
// EIP006
fetch logs
| filter matchesValue(log.source, "*eip_mediator_serverlog*")                      // CONFIRM
| filter contains(content, "jp-Distributing-Sell-GenerateFormImage-v2-vs", caseSensitive: false)
| filter contains(content, "Status=FAILURE", caseSensitive: false)                 // CONFIRM format
| makeTimeseries count = count(default: 0), interval:1m

// Compass
fetch logs
| filter k8s.namespace.name == "compass-prod-axa-li-jp"                            // CONFIRM
| filter contains(content, "IWFMReportException", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
| fieldsAdd count = arrayMovingSum(count, 5)

// IWFM agent
fetch logs
| filter matchesValue(log.source, "*fmwsagentlog*")                                // CONFIRM
| filter contains(content, "LOGLEVEL=\"Caution\"", caseSensitive: false)
      or contains(content, "LOGLEVEL=\"Fatal\"", caseSensitive: false)              // CONFIRM format
| makeTimeseries count = count(default: 0), interval:1m
```

Full file: `32-iwfm-splunk-alerts-transform.tf`.

## Issues found in the Splunk alerts

| Alert | Issue | What it means |
|---|---|---|
| EIP006 | 1-minute window | Data that arrives a little late can be missed. The detector looks at a rolling window instead |
| EIP006 | Wildcard search term `...-v2-vs*` | Becomes "contains" the fixed part |
| Compass | Expires 1500 days | Triggered alert records are kept for about 4 years. Harmless but odd |
| Compass | Recipient list is cut off | Second address must be confirmed |
| IWFM_Errors | `transaction host AGENTID maxspan=1s` | Only groups lines within 1 second. With "> 0" it changes nothing except cost |
| IWFM_Errors | Hourly check | An error at :16 is reported about an hour later. The detector reports within minutes |
| IWFM_Errors | Personal recipient | One person gets all IWFM agent errors. A team list is safer |
| All | Subject `$name$` | Dynatrace uses the detector name |

## Data flow

```
EIP mediator log ─┐
Compass pods     ─┼→ Grail → 3 detectors (every minute)
IWFM agent log   ─┘
   → above threshold → CUSTOM_ALERT problem
   → standard flow → SILVA + PagerDuty (no host tags → routing gap)
   → quiet for dealerting samples → problem closes
```

## Investigation

| Screenshot | Alert | Search | Window and schedule | Trigger | Action |
|---|---|---|---|---|---|
| 1 | EIP - IWFM : EIP006 service Failure Alert | index=eip1015, eip_mediator_serverlog, GenerateFormImage-v2, Status=FAILURE | Last 1 minute, every minute | > 2, no throttle | Email alj_jp_dl_infra_mwss, High |
| 2 | [Prod]ALJ-Compass-IWFMReportException発生 | index=compass-prod-axa-li-jp "IWFMReportException" | Last 5 minutes, every 5 minutes | > 15, no throttle | Email compass IT member and an aog list, Normal |
| 3 | IWFM_Errors | index=iwfm fmwsagentlog, LOGLEVEL Caution or Fatal, transaction | Last 1 hour, hourly at :15 | > 0, throttle 1 hour | Email raju.kolukuluri, Normal |

## Result

| Step | Action |
|---|---|
| 1 | Run `check.dql` query 1 and fix the three source filters |
| 2 | Run query 2 and check how `Status=FAILURE` and `LOGLEVEL="Caution"` really look. Adjust the contains text |
| 3 | Run queries 3 to 5 to see how often each would fire |
| 4 | Decide whether the two `_Normal` detectors should page through the standard flow |
| 5 | `terraform plan` should show 3 detectors |
| 6 | Without workflows nobody gets the old emails. Add email workflows later if the teams still want them |

## Related files

| File | Purpose |
|---|---|
| `32-iwfm-splunk-alerts-transform.tf` | 3 detectors |
| `32-iwfm-splunk-alerts-transform-check.dql` | Source, format and frequency checks |
| `32.sh` | Commands |

## Commands

See `32.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
