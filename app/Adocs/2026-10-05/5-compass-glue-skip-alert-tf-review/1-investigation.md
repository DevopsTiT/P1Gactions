# Investigation

| What was checked | Finding |
|---|---|
| Screenshot file `compass-sales-performance.tf` | Uses `resource "dynatrace_log_alert"` with Splunk-style fields |
| Provider docs, `log_alert` page | 404, the resource does not exist |
| Provider docs, `davis_anomaly_detectors` | Real resource for DQL threshold alerts |
| Provider docs, `log_events` | Real resource for per-line log events |
| DQL in the file | Filters on `aws.log_group` and `content` are valid; `sort` and `limit` don't produce an alertable number |
