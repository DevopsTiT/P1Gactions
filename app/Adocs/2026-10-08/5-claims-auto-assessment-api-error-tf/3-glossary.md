# Glossary

| Term | What it means | Why you care |
|---|---|---|
| `index=claimsda*` | Splunk claims indexes (wildcard) | No Dynatrace equivalent; filter by pod instead |
| Pod | One running copy of an app in Kubernetes | The host field shows pod names like `claims-auto-assessment-api-<hash>` |
| `k8s.pod.name` | Dynatrace field with the Kubernetes pod name | Pod logs often land here instead of `host.name` |
| `] ERROR ` | Log level ERROR right after the bracketed thread or logger name | The pattern the alert matches |
| Stacktrace notice | Startup message "Error stacktraces are turned on" | Contains "Error" but is not a failure, so it is excluded |
| `caseSensitive:false` | Match regardless of upper or lower case | Splunk search terms are case-insensitive |
| Records detector | Opens a problem when the query returns rows | No `makeTimeseries` needed |
