# Summarize Entity Service Host Source Status

ERROR/FATAL only. Added **service** (same idea as Data Explorer “Split by Service”).

## Main DQL

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd entity = coalesce(toString(dt.source_entity), "unknown-entity")
| fieldsAdd service = coalesce(toString(dt.entity.service), entityName(dt.entity.service), "unknown-service")
| fieldsAdd status = coalesce(loglevel, status, "UNKNOWN")
| summarize error_fatal_count = count(), by: { entity, service, host, source, status }
| sort error_fatal_count desc
| limit 200
```

| Column | Dynatrace field |
| --- | --- |
| entity | `dt.source_entity` |
| service | `dt.entity.service` (+ name if `entityName` works) |
| host | `host.name` |
| source | `dt.source_entity` |
| status | `loglevel` (`ERROR` / `FATAL`) |

If `entityName(...)` fails, use the ALT query in the `.dql` file (service id only).

File: `error-fatal-by-app-host-source.dql`
