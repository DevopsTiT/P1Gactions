# Host Tags You Can Use For App Column

```
Your host Properties and tags
  → YES — usable fields exist
  → Best: tag app  (you already have app: DYNATRACE)
  → Better name: AGO_GLOBAL_APP
  → Also: host group / env / bu / tier
  → Not needed: RUM Applications page link
```

| Tag / property | Example on your host | Use for log “application” column? |
| --- | --- | --- |
| **`app`** | `DYNATRACE` | **Yes — primary** (simple) |
| **`AGO_GLOBAL_APP`** | `APM-AXAGO-AXA-GROUP-OPERATIONS-Acceptance-Pre-Prod` | **Yes — richer name** |
| `AGO_GLOBAL_APPSERVICEID` | `cd1561…` | ID only — optional |
| `bu` | `APM` | Business unit, not full app |
| `env` | `STG` | Environment filter |
| `tier` | `AG-APDC` | Tier / location |
| Host group | `C_AGO_BU_APM_A_DYNATRACE_E_STG_T_AG-APDC` | Encodes app; harder to parse |
| RUM Application entity | (not on this panel) | Not on your ERROR logs |

## Summary

This host **is tagged with `app`**. You can build the log column from **`app`** or **`AGO_GLOBAL_APP`**. You do not need `dt.entity.application` for this host.

## Recommended DQL (use host tag `app`)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd application = coalesce(toString(`dt.entity.host.tags[app]`), "unknown-application")
| summarize error_fatal_count = count(), by: { application, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

## Richer name (AGO_GLOBAL_APP)

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd application = coalesce(
    toString(`dt.entity.host.tags[AGO_GLOBAL_APP]`),
    toString(`dt.entity.host.tags[app]`),
    "unknown-application"
  )
| summarize error_fatal_count = count(), by: { application, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

If backtick tag fields fail, open one ERROR log → check available host tag attribute names in your tenant (syntax can vary).

## Also useful filters (not the app name)

| Tag | Example use |
| --- | --- |
| `env: STG` | Only staging errors |
| `bu: APM` | Only that BU |
| `tier: AG-APDC` | Only that tier |

## Quick read of your screenshot

| Finding | Meaning |
| --- | --- |
| `app: DYNATRACE` | Host **has** app tag — ready |
| Host group contains `DYNATRACE` | Matches the `app` value |
| Monitoring mode Infrastructure only | Still fine for host tags + logs |

## Answer

**Yes.** Use **`app`** (and optionally **`AGO_GLOBAL_APP`**) from the host tags — that is what you can use for the application column on ERROR/FATAL logs.
