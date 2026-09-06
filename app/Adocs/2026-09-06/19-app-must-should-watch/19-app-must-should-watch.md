# App Must Should Watch Dashboard

One Classic board with **Must-watch** + **Should-watch**. Choose **any** app via Dashboard filter tag `app:<name>`.

| Item | Value |
| --- | --- |
| JSON | `App-Must-Should-Watch-Classic.json` |
| All apps | Leave dashboard filter empty |
| One app | Filter Tag `app` → any value |

## Import

1. Tag hosts + services: `app:<your-app-name>` (any monitored app)
2. Dynatrace → Dashboards Classic → Upload JSON
3. Empty filter = all apps; pick `app` tag = that app only

## Must-watch tiles

| Item | Metric / tile |
| --- | --- |
| Problems | OPEN_PROBLEMS |
| Traffic | `builtin:service.requestCount.total` |
| Errors | `builtin:service.errors.server.rate` |
| Latency avg | `builtin:service.response.time` |
| Latency 99th | `builtin:service.response.time:percentile(99)` |
| CPU | `builtin:host.cpu.usage` |
| Memory | `builtin:host.mem.usage` |
| Disk | `builtin:host.disk.usedPct` |

## Should-watch tiles

| Item | Metric / tile |
| --- | --- |
| Service / Host health | Honeycombs |
| GC suspension | `builtin:tech.jvm.memory.gc.suspensionTime` |
| Database health | DATABASE tile |
| External / dependency failures | Top list of server error rate by service |

## Note

Classic has no dropdown variable like new Dashboards. **Dashboard filter on tag `app`** is how you choose each app on this one board.
