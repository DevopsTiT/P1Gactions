# Portals PC UI ESBv4 License Investigation

| What was checked | Finding |
|---|---|
| #20, #23–#28 | Escaped JSON logs. Splunk unescapes, then uses `spath`. |
| #21 | Uses `openshift_stats`, a metric source. Mapped to Kubernetes CPU metrics. |
| #22 | License expiry date inside log text, JST timezone. |
| #23 to #27 | Same query shape. Only url, type, and time range change. |
| #28 | Two sourcetypes joined with OR. |
| #29 | Japanese text unreadable in screenshot. Filter uses the English part only. |
| #30 | Java Metaspace exhausted. A sign of a memory problem. |
| #31 | Alfresco lock failure. |
| `sourcetype` and `index` | Not in Dynatrace. A check query is provided. |
