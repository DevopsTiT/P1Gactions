# What Can Be Used For App

From your **Properties and tags** screens — **yes**.

| Tag / property | Example value | Use as app? |
| --- | --- | --- |
| **`app`** | `DYNATRACE` | **Yes — best simple key** |
| **`AGO_GLOBAL_APP`** | `APM-AXAGO…` or `APM-AXAGO-AXA-GROUP-OPERATIONS-Acceptance-Pre-Prod` | **Yes — richer name** |
| `[Azure]global-app` | `APM AXAGO` | Yes if Azure-tagged hosts |
| `AGO_GLOBAL_APPSERVICEID` | `cd1561…` | ID only |
| Host group | `…_A_DYNATRACE_E_STG_…` | Encodes app name; backup |
| `bu` / `env` / `tier` | `APM` / `STG` / … | Not the app name — filters only |

## Use this (ERROR/FATAL)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd application = coalesce(
    toString(`dt.entity.host.tags[app]`),
    toString(`dt.entity.host.tags[AGO_GLOBAL_APP]`),
    "unknown-application"
  )
| summarize error_fatal_count = count(), by: { application, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

**Answer:** use **`app`** first; use **`AGO_GLOBAL_APP`** when you want the long name. Your hosts already have both.
