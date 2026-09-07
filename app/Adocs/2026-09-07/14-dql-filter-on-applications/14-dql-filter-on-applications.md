# Tags App To Application

Replace host/service **`tags[app]`** with **Application** entity.

| Old (remove) | New (use) |
| --- | --- |
| `` `dt.entity.host.tags[app]` `` | `dt.entity.application` |
| `` `dt.entity.service.tags[app]` `` | `entityName(dt.entity.application)` |

## Paste this (closest to your screen)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| filter isNotNull(dt.entity.application)
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd application = coalesce(entityName(dt.entity.application), toString(dt.entity.application), "unknown-application")
| summarize error_fatal_count = count(), by: { application, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

Do **not** use `tags[app]` or service tags in this query.

If empty: many logs are not linked to a RUM Application — check Logs fields for `dt.entity.application` on a sample ERROR line.
