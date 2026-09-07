# Summarize By Entity Host Source Status

```
ERROR or FATAL only
  → summarize by entity, host, source, status
```

| Column | Meaning |
| --- | --- |
| entity | Source entity / service / process id |
| host | Host name |
| source | `dt.source_entity` |
| status | Log level (`ERROR` / `FATAL`) |
| error_fatal_count | How many lines |

## Main DQL

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd entity = coalesce(toString(dt.source_entity), toString(dt.entity.service), toString(dt.entity.process_group_instance), "unknown-entity")
| fieldsAdd status = coalesce(loglevel, status, "UNKNOWN")
| summarize error_fatal_count = count(), by: { entity, host, source, status }
| sort error_fatal_count desc
| limit 200
```

File: `error-fatal-by-app-host-source.dql` (both folders).
