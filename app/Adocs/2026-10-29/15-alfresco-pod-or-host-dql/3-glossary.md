# Glossary

| Term | What it means |
|---|---|
| `Message` | How many different names were found. Splunk writes this on the Total row. |
| `k8s.pod.name` | The Kubernetes pod name on the log. |
| `host.name` | The host name Dynatrace stored on the log. |
| `from_pod` | The pod name, kept only when it contains `alfrescoacr-batch`. |
| `from_host` | The host name, kept only when it contains `alfrescoacr-batch`. |
| `unit` | The one name counted for that log. Pod name first, otherwise host name. |
| `countDistinct` | Counts different values. Repeated lines for the same name count once. |
| `log_count` | How many log lines one name wrote. The alert does not use this number. |
