# DQL Applications No Service

ERROR/FATAL only. Filter on **Applications**. **No service** in the query.

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| filter isNotNull(dt.entity.application)
| fieldsAdd application = coalesce(entityName(dt.entity.application), toString(dt.entity.application), "unknown-application")
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd entity = coalesce(toString(dt.source_entity), "unknown-entity")
| fieldsAdd status = coalesce(loglevel, status, "UNKNOWN")
| summarize error_fatal_count = count(), by: { application, entity, host, source, status }
| sort error_fatal_count desc
| limit 200
```

| Include | Exclude |
| --- | --- |
| application, entity, host, source, status | service / `dt.entity.service` |

File: `error-fatal-by-app-host-source.dql`
