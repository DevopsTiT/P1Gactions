# eopt Log Paths In Detail Glossary

| Term | What it means |
|---|---|
| Pod | Smallest running unit in OpenShift. |
| stdout | Normal program output, where container logs go. |
| Node | Server that runs pods. |
| Collector | Node program that reads pod log files (Vector or Fluentd). |
| ClusterLogForwarder | OpenShift setting mapping namespaces to log destinations. |
| S3 bucket | Amazon file storage. |
| OneAgent App only | Dynatrace agent inside each app process. No stdout logs. |
| Dynatrace Operator | Kubernetes operator that installs and manages OneAgent. |
| /api/v2/logs/ingest | Dynatrace API that accepts log lines. |
| OpenPipeline | Dynatrace processing before storage. |
| Grail | Dynatrace data store. |
