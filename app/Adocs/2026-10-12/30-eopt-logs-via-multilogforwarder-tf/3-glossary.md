# eopt Logs Via Multilogforwarder Glossary

| Term | What it means |
|---|---|
| multilogforwarder | Pipeline copying OpenPaaS pod logs to Splunk and Dynatrace. |
| `/api/v2/logs/ingest` | Dynatrace log intake API. |
| Namespace | Kubernetes folder holding one app's pods. |
| `k8s.namespace.name` | Namespace field on a log line. |
| `k8s.pod.name` | Pod name field on a log line. |
| Splunk internal logs | Splunk's own license and metrics records. |
| `dt.openpipeline.source` | Ingest path a log came through. |
