# eopt Logs Via Multilogforwarder Investigation

| Check | Result |
|---|---|
| A. `search "eoptsystemapi"` | 469 rows, all Splunk license_usage.log and metrics.log, security context ALJ-APPRELEAS-SPLUNK-PRD |
| B. content words | Splunk hosts plus cap-portal-system-api and tax-deduction-process-api via multilogforwarder-log-handler-dynatrace |
| C. k8s fields contain eopt | 0 |
| D. log.source logforwarders or eopt | 0 |
| E. ingest sources | oneagent, /api/v2/logs/ingest, /api/v2/logs/ingest/aws_firehose, sql-oracle, sql-server, certificate monitor |
| Namespace pattern | `<app>-prod-axa-li-jp` |
