# Main All Apps Status (Generic V2 Style)

One Classic board shaped like Dynatrace **Generic V2 - Overview**: health row + request/failure charts with Last 10min lists + GC/CPU/mem/disk.

| Key point | Detail |
| --- | --- |
| Import | `Main-All-Apps-Status-Classic.json` |
| Scope | All apps / all hosts (empty `filterBy`) |
| Style | Same tile pattern as Generic V2 preset screenshots |

## Import

1. Dynatrace → **Dashboards Classic** → Upload JSON
2. Open **Main-All-Apps-Status (Generic V2 style)**
3. Leave dashboard filter empty = all entities

## Layout (matches your screenshots)

| Row | Tiles |
| --- | --- |
| Overview | Service health honeycomb, Host health honeycomb, Database, Network health, Problems |
| Web + Infra | Request count + Last 10min; GC time + Last 10min |
| Failures + CPU | Failure rate (5xx) + Last 10min; CPU % + Last min |
| Latency | 99th% RT, Average RT, Last 10min |
| Memory | Memory % (last 7d), Memory %, Last min lists |
| Disk | Disk % (last 7d), Last 2min by host+disk, Disk % |

## Metrics used

| Tile | Metric |
| --- | --- |
| Host health | `builtin:host.availability.state` |
| Service health | `builtin:service.errors.server.rate` (honeycomb) |
| Request count | `builtin:service.requestCount.total` |
| Failure rate | `builtin:service.errors.server.rate` |
| GC | `builtin:tech.jvm.memory.gc.suspensionTime` |
| CPU / Mem / Disk | `builtin:host.cpu.usage`, `host.mem.usage`, `host.disk.usedPct` |
| 99th RT | `builtin:service.response.time:percentile(99)` |

## Note

If a honeycomb or GC tile is empty in your tenant, edit the tile in Data Explorer and pick the closest available metric (metric keys vary slightly by OneAgent / JVM coverage). TCP/Network honeycomb may need retuning after import.

## Later

Same board → Dashboard filter `app:eip` when you want one app only.
