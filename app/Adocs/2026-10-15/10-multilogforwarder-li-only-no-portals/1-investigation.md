# Multilogforwarder Life Only Investigation

| What was checked | Finding |
|---|---|
| Query | `log.source == "multilogforwarder-log-handler-dynatrace"`, count by `k8s.namespace.name` |
| Time window | 10/12/2026 23:34 to 10/13/2026 00:34 |
| Rows | 11 namespaces |
| Naming | Every namespace ends with `-prod-axa-li-jp`. |
| Largest | compassproxy-prod-axa-li-jp with 154,642 lines. |
| portals | Not present. |
| portals-amp destination | S3 `axa-gi-jp-logforwarders-prod`, then Splunk. |
