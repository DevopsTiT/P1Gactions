# Standard Dynatrace App Monitoring Items

```
What to monitor for an app in Dynatrace?
  │
  ├─ Availability / Problems (is it up / broken?)
  ├─ Traffic (requests)
  ├─ Errors / failure rate
  ├─ Latency (avg + 99th)
  ├─ Dependencies (DB / external)
  └─ Saturation (CPU / mem / disk / GC on hosts under the app)
```

| Key point | Detail |
| --- | --- |
| What this is | The usual “must watch” set for an application in Dynatrace |
| Why it matters | Matches SRE golden signals + Dynatrace Problems/Davis |
| Scope | One app or all apps — same items; filter by `app:<name>` |

## Summary

For apps, Dynatrace standard practice is: **Problems + service golden signals (traffic, errors, latency) + key dependencies + host saturation (CPU/mem/disk/GC)**. That is what presets like Generic V2 Overview show.

## Standard items (beginner map)

| Item | What it means | Typical Dynatrace metric / tile | Why you care |
| --- | --- | --- | --- |
| Problems / health | Something is wrong (Davis) | `OPEN_PROBLEMS`, service/host health honeycomb | First place L1 looks |
| Request / traffic | How much work the app does | `builtin:service.requestCount.total` | Load and sudden drop/spike |
| Error / failure rate | Failed calls (e.g. HTTP 5xx) | `builtin:service.errors.server.rate` | User-facing breakage |
| Latency (average) | Typical speed | `builtin:service.response.time` | Everyday slowness |
| Latency (tail / 99th) | Worst user experience | `builtin:service.response.time:percentile(99)` | Outliers / timeouts |
| Throughput success | Healthy completed work | Often derived from request vs errors | Capacity vs failures |
| Apdex / experience (if web) | User satisfaction score | RUM / application metrics when enabled | Front-end feel |
| Database health | DB behind the app | Database tile / DB service metrics | Common root cause |
| External / dependency calls | Downstream services | Service flow / failure on called services | Blame app vs neighbor |
| Host CPU | Compute saturation | `builtin:host.cpu.usage` | Box too busy |
| Host memory | RAM pressure | `builtin:host.mem.usage` | OOM / swap risk |
| Host disk | Disk full / pressure | `builtin:host.disk.usedPct` | Logs/DB fill disk |
| JVM GC (Java apps) | Pause time from garbage collection | `builtin:tech.jvm.memory.gc.suspensionTime` | Latency spikes on JVM |
| Network (optional) | NIC / connectivity health | host net / TCP tiles | Connectivity issues |
| Logs / exceptions (optional) | Error evidence | Log Monitoring ERROR / Exception | Proof for RCA |
| Synthetic (optional) | Outside-in uptime check | Synthetic monitors | “Is URL up?” |

## Golden signals → Dynatrace

| SRE golden signal | Dynatrace focus |
| --- | --- |
| Traffic | Request count |
| Errors | Server / 5xx failure rate + Problems |
| Latency | Avg + 99th response time |
| Saturation | CPU, memory, disk, GC |

## What “one main dashboard” should include first

| Priority | Include |
| --- | --- |
| Must | Problems, request count, failure rate, avg + 99th RT |
| Must | CPU, memory, disk (hosts of the apps) |
| Should | GC (if JVM), database tile, Last 10min top lists |
| Nice | Network honeycomb, logs jump, synthetics |

This matches popular **Generic V2 - Overview** style boards.

## Per app vs all apps

| Mode | How |
| --- | --- |
| All apps | Empty dashboard filter |
| One app | Filter tag `app:<any-monitored-app>` |
| Metrics | **Same list** for every app |

## Common mistakes

| Mistake | Better |
| --- | --- |
| Only CPU/mem, no request/errors | Add service golden signals |
| Only requests, no host saturation | Add CPU/mem/disk |
| One board per app | One board + any `app:` tag |
| Skip Problems tile | Keep Problems at top |

## Related JSON

`../17-main-all-apps-status-json/Main-All-Apps-Status-Classic.json` — implements this standard set for all apps.
