# ERROR FATAL Only No Info

```
loglevel == ERROR or FATAL only
  → no INFO / WARN / DEBUG / other
  → still group by app, host, source
```

| Key point | Detail |
| --- | --- |
| Included | `ERROR`, `FATAL` |
| Excluded | `INFO`, `WARN`, `DEBUG`, and other levels |
| File | `error-fatal-by-app-host-source.dql` |

## Strict filter (use this)

```dql
| filter loglevel == "ERROR" or loglevel == "FATAL"
```

Do **not** match Exception/fail keywords alone — that can pull INFO lines that only mention the word.

## Main gather query (A2)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd app = if(contains(toUpperCase(host), "EIP"), "eip",
    if(contains(toUpperCase(host), "API"), "api",
      if(contains(toUpperCase(host), "PAYMENT"), "payment",
        if(contains(toUpperCase(host), "CLAIM"), "claims", "other"))))
| summarize error_fatal_count = count(), by: { app, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

## Detail (B)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| sort timestamp desc
| fields timestamp, loglevel, host, source, content
| limit 200
```

If your tenant stores level in `status` instead of `loglevel`, use query **D** in the `.dql` file (still ERROR/FATAL only).
