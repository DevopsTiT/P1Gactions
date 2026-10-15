# Dynatrace Dummy Data Pic

```
test logic only? → data record(...) instead of fetch logs → same filter lines → expected rows?
need it stored?  → JSON → curl /api/v2/logs/ingest (logs.ingest token) → wait 1-2 min → fetch logs | filter log.source == "dummy-test"
                   (test tenant, DUMMY-TEST marker, check alerts first)
metric?          → data with numbers, or /api/v2/metrics/ingest
lookup?          → data with the same columns
```
