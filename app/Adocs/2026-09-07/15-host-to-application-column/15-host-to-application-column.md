# Can DQL Add Application Column For Host

```
Your ERROR log fields today
  → loglevel, host, source (HOST-…), content
  → NO dt.entity.application on the record

Can this DQL add "which Application the host belongs to"?
  → Not from Application entity on these logs (field missing)
  → RUM Applications (Applications page) usually do NOT own hosts
```

| Key point | Detail |
| --- | --- |
| Your question | Add column: host → which Application? |
| On your current logs | **No** — Application is not on the log record |
| Applications page | Web/Mobile **RUM** apps — not “host parent” |
| What works | Tag / host group / MZ that **you** define for the app |

## Summary

The DQL you ran is fine for ERROR/FATAL + host + source. It **cannot** invent an Application column if Grail does not store `dt.entity.application` (or a similar link) on that log. In Dynatrace, **hosts do not normally “belong to” a RUM Application** the way they belong to a host group. Frontend Applications and backend hosts are different entity types.

## What your screen proves

| Visible on log detail | Meaning |
| --- | --- |
| `loglevel` = ERROR | Level OK |
| `host` = …intraxa | Host name OK |
| `source` = `HOST-…` | Source is the **host**, not an Application |
| No Application field | Cannot `fieldsAdd application = …` from that record |

So this will stay empty or fail to enrich:

```dql
| filter isNotNull(dt.entity.application)
```

on those lines.

## Can you still show an “application” column?

| Approach | Works? | How |
| --- | --- | --- |
| `dt.entity.application` on these logs | **No** (not present) | — |
| Tag hosts `app:compass` / `app:eip` | **Yes** | Then read host tag into a column |
| Host group / naming (`…COMPASS…`) | **Partial** | `fieldsAdd` from `host.name` contains |
| Management Zone | **Partial** | Filter by MZ, not always a log column |
| Real RUM Application ↔ host link | **Rare** | Only if your topology/logs actually link them |

## Practical pattern (recommended)

**1. Tag each host** with the business app name (same idea as your Applications list names, shortened):

| Tag key | Example value |
| --- | --- |
| `app` | `compass-pbco-tst`, `emma-stg`, … |

**2. DQL** (ERROR/FATAL only; column from **host tag**, not RUM Application):

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

(Field name for tags can differ by tenant — check one host’s tags in the UI, then one log’s available fields.)

**3. Temporary without tags** — guess from hostname (weak):

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd application = if(contains(toUpperCase(host), "COMPASS"), "compass",
    if(contains(toUpperCase(host), "EMMA"), "emma", "other"))
| summarize error_fatal_count = count(), by: { application, host, source, loglevel }
| sort error_fatal_count desc
| limit 200
```

## Direct answers

| Question | Answer |
| --- | --- |
| Can *this* DQL add Application from Applications page for that host? | **Not with your current log attributes** |
| Is host → RUM Application a standard Dynatrace link? | **No** |
| How to get an application-like column? | **Tag the host** (or name/MZ convention), then `fieldsAdd` that tag |

## Keep using for detail (no application)

Your working query is still correct for raw ERROR lines:

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| sort timestamp desc
| fields timestamp, loglevel, host, source, content
| limit 200
```
