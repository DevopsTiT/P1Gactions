# OK To Add Log Tile On Dashboard

```
Add a log tile on Dynatrace dashboard?
  │
  ├─ YES — OK, after you can find errors manually in Logs app
  ├─ Prefer NEW Dashboards → DQL `fetch logs` table tile
  └─ Classic → weak for live log lines (link/jump OK; full table often not)
```

| Key point | Detail |
| --- | --- |
| Is it OK? | **Yes** |
| Best tile | New Dashboards **DQL** tile showing ERROR / Exception |
| Classic board | Metrics stay; log tile limited — use Logs app or new board |
| Order | Manual Logs skill first → then pin a tile |

## Summary

Adding a tile to check logs is normal and useful. Use it as a **shortcut** to the same filters you already know by hand — not as a replacement for understanding Logs.

## What works well

| Platform | Log tile approach | OK? |
| --- | --- | --- |
| **New Dashboards** | DQL `fetch logs` → table of ERROR lines | **Best** |
| **New Dashboards** | Single value: count of ERROR logs | Good “any wrong logs?” |
| **Classic** | Markdown link to Logs / saved query | OK as reminder |
| **Classic** | Expect full live log table like V2 metrics | Often **not** good |

## Simple DQL for a log tile (new Dashboards)

```dql
fetch logs
| filter loglevel == "ERROR" or matchesValue(status, "ERROR")
| sort timestamp desc
| fields timestamp, loglevel, content, host.name
| limit 50
```

Optional: filter by app tag / `$app` when you have a variable.

## Good practice

| Do | Don’t |
| --- | --- |
| Same timeframe as the rest of the board | Dump all logs unfiltered |
| Limit to ERROR / Exception | Paste long markdown “import another JSON” as the only “log tile” |
| Keep Must-watch metrics on Classic; logs on new board if Classic is limited | Assume Classic honeycomb = log text |

## Answer

**Yes, it is OK** — especially on **new Dashboards** with a DQL ERROR table. On Classic Must-watch, prefer metrics + open Logs manually, or add a small link; put the real log checker on a new dashboard tile when ready.
