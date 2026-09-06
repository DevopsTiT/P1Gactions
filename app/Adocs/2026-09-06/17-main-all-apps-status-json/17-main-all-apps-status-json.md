# Main All Apps Status JSON

One Classic dashboard for **all monitored apps** (Generic V2 Overview template style).

| Item | Value |
| --- | --- |
| File | `Main-All-Apps-Status-Classic.json` |
| Scope | All apps / all hosts (empty filter) |
| Later | Dashboard filter tag `app:<any-name>` |

## Import

1. Dynatrace → Dashboards Classic → Upload
2. Open **Main-All-Apps-Status**
3. Leave filter empty = all apps

## Layout

| Row | Content |
| --- | --- |
| Overview | Service/Host honeycombs, Database, Network, Problems |
| Web + Infra | Request count + Last 10min; GC + Last 10min |
| Failures + CPU | 5xx failure rate + Last 10min; CPU + Last min |
| Latency | 99th% RT, Average RT, Last 10min |
| Memory / Disk | 7d + current + Last min / Last 2min |

## Metrics

| Tile | Metric |
| --- | --- |
| Host health | `builtin:host.availability.state` |
| Service health / Failure | `builtin:service.errors.server.rate` |
| Request count | `builtin:service.requestCount.total` |
| GC | `builtin:tech.jvm.memory.gc.suspensionTime` |
| CPU / Mem / Disk | `builtin:host.cpu.usage`, `builtin:host.mem.usage`, `builtin:host.disk.usedPct` |
| 99th RT | `builtin:service.response.time:percentile(99)` |
