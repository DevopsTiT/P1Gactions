# ERROR / FATAL Logs By App Host Source

```
ERROR or FATAL logs
  → show app + host + source
  → gather all into one summary (counts)
  → optional: one detail table under it
```

| Key point | Detail |
| --- | --- |
| Levels | `ERROR` and `FATAL` only |
| Dimensions | App (tag/name), host, source entity |
| “All in one” | One **summary** query groups everything; one **detail** query lists lines |

## Summary

Use query **A** as the main tile: all ERROR/FATAL logs rolled up by app, host, and source with counts. Use query **B** if you also want the raw lines. Both are in `error-fatal-by-app-host-source.dql`.

## DQL — A) Gather together (one summary table) — use this first

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
    or matchesValue(status, "ERROR") or matchesValue(status, "FATAL")
| fieldsAdd
    host = coalesce(host.name, "unknown-host"),
    source = coalesce(toString(dt.source_entity), "unknown-source"),
    app = coalesce(
      toString(`dt.entity.host.tags[app]`),
      toString(`dt.entity.service.tags[app]`),
      if(contains(toUpperCase(toString(host.name)), "EIP"), "eip",
        if(contains(toUpperCase(content), "[EIP"), "eip", "unknown-app"))
    )
| summarize
    error_fatal_count = count(),
    by: { app, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

If tag fields differ in your tenant, use the **safer A2** version in the `.dql` file (app from host name / content only).

## DQL — B) Detail lines (same scope, all in one list)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
    or matchesValue(status, "ERROR") or matchesValue(status, "FATAL")
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| sort timestamp desc
| fields timestamp, loglevel, host, source, content
| limit 200
```

Full set (A1/A2/A3/B/C) is in `error-fatal-by-app-host-source.dql`.

## How to put on one dashboard section

| Tile | Query | Shows |
| --- | --- | --- |
| 1 (main) | **A** summary | Which **apps / hosts / sources** have ERROR/FATAL + counts |
| 2 (optional) | **B** detail | Full log lines |

Markdown header: `## LOGS — ERROR / FATAL by app, host, source`

## Related file

`error-fatal-by-app-host-source.dql` — paste into Notebooks / new Dashboard DQL tiles / Logs.
