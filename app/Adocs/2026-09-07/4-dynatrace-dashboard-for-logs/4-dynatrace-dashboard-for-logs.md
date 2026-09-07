# Dynatrace Dashboard For Logs

```
Need logs on a Dynatrace dashboard?
  │
  ├─ Classic Dashboards
  │     → LOG_ANALYTICS tile (limited) or Markdown jump to Logs
  │
  └─ New Dashboards (preferred for logs)
        → DQL tile: fetch logs | filter ...
        → Tables for ERROR / Exception / app filter
```

| Key point | Detail |
| --- | --- |
| What it is | A dashboard area that shows **log lines** (ERROR, Exception, keywords) |
| Why it matters | Metrics say “something is wrong”; logs give **evidence** |
| Best place today | **New Dashboards** + **DQL** `fetch logs` |
| Classic | Weaker for live log tables; often link out to Logs app |

## Summary

Dynatrace does not use the same “Request count” Data Explorer tile for full log browsing. For logs, use **Log Monitoring** data via the **Logs** app, or pin **DQL log queries** on a **new** dashboard. Classic boards mostly show metrics (CPU, requests) plus optional log jumps.

## Where logs live in Dynatrace

| Place | What it is | Use for |
| --- | --- | --- |
| **Logs** app (Logs and events) | Search/browse ingested logs | Ad-hoc investigation |
| **New Dashboards** + DQL | `fetch logs` tiles on a board | Standing ERROR / Exception views |
| **Classic Dashboards** | `LOG_ANALYTICS` tile (older) or Markdown link | Limited; many teams jump to Logs app |
| **OpenPipeline / OneAgent** | Ingest + PII mask before Grail | Control what is stored |

## Standard log tiles on an app dashboard

| Tile idea | What it means | Example DQL idea |
| --- | --- | --- |
| Error logs | ERROR level lines | `fetch logs \| filter loglevel == "ERROR"` |
| Exceptions | Stack traces | `fetch logs \| filter matchesPhrase(content, "Exception")` |
| App-scoped logs | Only selected app | Add filter on host/service tag `app:<name>` or content |
| Log volume | How many lines | `fetch logs \| summarize count()` |

## New Dashboards (recommended for logs)

1. Dashboards (new) → Create dashboard  
2. Add tile → **DQL** / Query  
3. Example:

```dql
fetch logs
| filter loglevel == "ERROR" or matchesValue(status, "ERROR")
| sort timestamp desc
| fields timestamp, loglevel, content, host.name, dt.source_entity
| limit 100
```

4. Duplicate tile for Exceptions; add variable/filter for `app` if you use tags/segments.

## Classic Dashboards (what you use for Must-watch)

| Option | Reality |
| --- | --- |
| Metrics board (Traffic/CPU/…) | Does **not** replace a log viewer |
| Markdown tile | Link: open Logs with a saved query |
| LOG_ANALYTICS tile | Older Classic tile; tenant-dependent |
| Full ERROR table like new Dashboards | Prefer **new** Dashboards for that |

So: keep **App-Must-Should-Watch** for health/metrics; add a **second** “App Logs” board in **new** Dashboards, or add DQL log tiles if your tenant supports mixing.

## How this fits your setup

| Board | Role |
| --- | --- |
| App-Must-Should-Watch (Classic) | Problems, traffic, errors %, latency, CPU/mem/disk |
| Logs dashboard (new) or Logs app | Actual log lines / exceptions |
| PII gates (OneAgent/OpenPipeline) | Stop PII landing in those logs |

## Common mistakes

| Mistake | Better |
| --- | --- |
| Expect Classic honeycomb to show log text | Use DQL `fetch logs` |
| Put raw PII in logs then dashboard them | Mask/block before ingest |
| One giant unfiltered log tile | Filter ERROR + app tag + limit |

## Related

Your metric board JSON: `App-Must-Should-Watch-Classic.json`  
Earlier log DQL ideas: PII / prevent folders under `2026-09-06`.
