# Datalake Batch Result Pic

```
Splunk: index batch_monitoring_logs, 08:00, Today, > 0, email
 → Dynatrace Records detector
   filter: contains(log.source, "datalake_transfer.log")
   identity: check → 1 problem per night
   severity low, pagerduty "0"
 exact 08:00 needed? → workflow (2026-10-05 seq 42)
```
