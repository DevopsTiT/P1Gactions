# Datalake Batch Result Source Fix Pic

```
Splunk index batch_monitoring_logs
 → event detail: source = /app/splunk/var/log/splunk/datalake_transfer.log
   → Dynatrace filter: contains(log.source, "datalake_transfer.log")
     → check query 1 has rows?
       yes → terraform plan → apply
       no  → add file to OneAgent log ingest → retry
```

```
02:00 batch → datalake_transfer.log → OneAgent → Grail
 → Records detector → 1 problem per night → low email (no PagerDuty)
```
