# What Data Explorer Is Most Used For

```
Dynatrace Data Explorer (Classic)
  → Build charts from METRICS
  → Split by Host / Service / Disk
  → Pin to Classic dashboards

Not for
  → Reading full ERROR log text (use Logs / DQL)
```

| Key point | Detail |
| --- | --- |
| What it is | Visual metric query builder (pick metric → aggregate → split → chart) |
| Most used for | **Infrastructure + service performance metrics** on dashboards |
| Output | Graph, Top list, Table, Single value → **Pin to dashboard** |

## Summary

**Data Explorer** is the everyday tool to explore and pin **metrics**: CPU, memory, disk, request count, errors, response time. That is what filled most rows of your layout (Requests, Errors, CPU, Memory, Disk). It is **not** the main tool for log message text.

## What people use it for most

| Category | Typical metrics | Split by | Why |
| --- | --- | --- | --- |
| Host health | CPU %, Memory used %, Disk used % | Host, Disk | Saturation / capacity |
| Service performance | Request count, Failure rate, Response time | Service | App golden signals |
| Top talkers | Same metrics as **Top list** | Service or Host | Who is hottest right now |
| Threshold views | Disk/CPU with red/yellow | Host | Quick “who is bad?” |
| Dashboard building | Any of the above | — | Pin tiles to Classic boards |

## Metrics you already used (most common set)

| Tile on your board | Data Explorer style metric |
| --- | --- |
| Requests | Request count (`builtin:service.requestCount.total`) |
| Errors | Server / failure rate (`builtin:service.errors.server.rate`) |
| Response Time | Response time (`builtin:service.response.time`) |
| CPU | CPU usage % (`builtin:host.cpu.usage`) |
| Memory | Memory used % (`builtin:host.mem.usage`) |
| Disk | Disk used % (`builtin:host.disk.usedPct`) Split Host + Disk |

## Typical UI flow (most common)

1. Open **Data explorer**
2. Pick a **metric**
3. Set **aggregation** (Average / Value / Auto — follow UI warnings)
4. **Split by** Host or Service (or Host + Disk)
5. Choose **Graph** or **Top list**
6. Optional **thresholds** (e.g. Disk red ≥ 90)
7. **Run query** → **Pin to dashboard**

## What it is *not* most used for

| Need | Use instead |
| --- | --- |
| ERROR / FATAL log **text** | Logs app |
| Exception stacks | Logs / DQL `fetch logs` |
| Summarize logs by host tag `app` | DQL in Notebooks / new Dashboards |
| Full Davis root-cause narrative | Open a **Problem** |

## How it fits your layout

| Layout section | Mainly Data Explorer? |
| --- | --- |
| Application selector | Dashboard filter (tag `app`) — not Data Explorer |
| Problems / Root cause | Problems tile + Problem UI |
| Requests / Errors / Response time | **Yes — Data Explorer** |
| Windows/Linux CPU / Memory (/ Disk) | **Yes — Data Explorer** |
| Error logs / Exceptions | Logs / DQL |
| DB / External | Often Data Explorer (+ Databases tile) |

## Short answer

**Data Explorer is most used to monitor and chart metrics** (host CPU/mem/disk and service request/error/latency), then pin those charts to Classic dashboards. Use **Logs** for log details.
