# Application Incident Analysis Pic

```
monitor_logs lookup (OK or NG per check)
 → 01:00 keep yesterday
   → count OK, NG, Maintenance per application
     → collect → monitoring_summary_idx (46 rows)
No notification → not an alert → Dynatrace dashboard instead of detector
```

```
Splunk: checks → lookup → nightly summary → index → report
Dynatrace: checks → Grail → dashboard query (live)
```
