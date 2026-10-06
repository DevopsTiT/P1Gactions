# Cisco VPN LDAP Records Detector

## Decision Tree

```
Detector query must be only the 3 lines (no makeTimeseries)?
 → switch the analyzer to Records (RecordAnomalyDetectionAnalyzer)
   each returned row = violation → critical problem → page
   no from: → looks back 2 hours → problem closes 2 hours after the last FAILED line
   one problem per host → alertIdentityFields[0] = host.name
 need "more than 3 per minute"? → not possible with the 3 lines alone
```

## Short Takeaway

| Question | Answer |
|---|---|
| Query | Exactly your 3 lines |
| How it works without makeTimeseries | Data type Records: every matching log row is a violation |
| Analyzer name | `dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer` |
| Threshold | None; the first FAILED line alerts |
| How long it stays open | Until 2 hours after the last FAILED line |

## Summary

Dynatrace detectors have two data types. Timeseries detectors (seq 1 and seq 3) need `makeTimeseries`. Records detectors run any DQL every minute and alert on each row returned. With Records, your three lines are the whole query. Grouping by `host.name` gives one problem per host instead of one per log line.

## Timeseries vs Records

| Topic | Timeseries (seq 3) | Records (seq 4) |
|---|---|---|
| Analyzer | `...ui.anomaly_detection.StaticThresholdAnomalyDetectionAnalyzer` | `...anomaly_detection.RecordAnomalyDetectionAnalyzer` |
| Query ends with | `makeTimeseries` | Your filter |
| Alert rule | Count per minute above a threshold | Any row returned |
| Sliding window and dealerting | Yes | No |
| Close | After 15 quiet minutes | When the query returns no rows (2 hours after the last line) |

## Data Flow

```
ASA → ljcmgt14 → Grail
  → every minute: your 3 lines over the last 2 hours
  → rows found? → one critical problem per host.name → standard flow (page)
  → no rows → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Dynatrace docs, anomaly detection configuration | Data type can be Timeseries or Records |
| Records default timeframe | `from: -2h` when the query has none |
| Dynatrace alerting reference | Records analyzer name, `query.expression` input and `alertIdentityFields[N]` |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 2 to see the Sep 23 and Sep 24 lines |
| 2 | `terraform plan` shows 1 to add |
| 3 | Apply only one of seq 1, seq 2, seq 3 or seq 4 (same resource name) |

## Related Files

| File | Purpose |
|---|---|
| `4-cisco-vpn-ldap-records-detector.tf` | Records detector Terraform |
| `4-cisco-vpn-ldap-records-detector-check.dql` | Check queries |
| `4.sh` | Commands |
