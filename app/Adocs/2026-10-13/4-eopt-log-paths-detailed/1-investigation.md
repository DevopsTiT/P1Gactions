# eopt Log Paths In Detail Investigation

| Item | Status | Evidence |
|---|---|---|
| eopt in namespace eopt-prod-axa-li-jp on OpenShift | Confirmed | Host page, earlier checks |
| Splunk gets eopt logs from S3 axa-li-jp-logforwarders-prod | Confirmed | Splunk source |
| 15 eopt hosts, App only | Confirmed | Entity query |
| 0 eopt log lines in Dynatrace, 24 hours | Confirmed | Four queries |
| 11 namespaces via multilogforwarder | Confirmed | Namespace query |
| Collector is OpenShift Logging with ClusterLogForwarder | Inferred | Forwarder name |
| Splunk reads S3 via Splunk Add-on for AWS | Inferred | Typical setup |
| log-handler-dynatrace adds the token and calls the ingest API | Inferred | Name and ingest source |
