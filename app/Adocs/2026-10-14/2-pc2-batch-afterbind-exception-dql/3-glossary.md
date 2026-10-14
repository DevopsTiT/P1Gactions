# PC2 Batch AfterBind Exception DQL Glossary

| Term | What it means |
|---|---|
| index | Splunk storage bucket. Not in Dynatrace. |
| `fields + _raw` | Splunk: keep only the raw line. |
| `content` | DQL name for the raw log line. |
| `k8s.pod.name` | Kubernetes pod name on forwarded logs. |
| StatefulSet | Kubernetes workload with fixed numbered pods (-0, -1). |
| `startsWith` | DQL text check for a prefix. |
