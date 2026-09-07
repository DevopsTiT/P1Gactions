# Which Code Monitors Health

In `App-Must-Should-Watch-Classic.json`, **health** is the top section titled **MUST — Health & Problems**.

```
Health monitoring in the JSON
  │
  ├─ Service health   → honeycomb (error rate by service)
  ├─ Host health      → honeycomb (host availability)
  ├─ Problems         → OPEN_PROBLEMS (Davis)
  └─ Database health  → DATABASE tile
```

| Tile `name` in JSON | What monitors health | How (code) |
| --- | --- | --- |
| `Service health` | Are services “red/green”? | `tileType: DATA_EXPLORER` + `visualConfig.type: HONEYCOMB` + metric `builtin:service.errors.server.rate` |
| `Host health` | Are hosts up / available? | Honeycomb + metric `builtin:host.availability.state` |
| `Problems` | Did Davis detect a break? | `tileType: OPEN_PROBLEMS` (no metric key) |
| `Database health` | Are DBs OK? | `tileType: DATABASE` (built-in DB tile) |

## Section header (marks the health block)

```json
"name": "MUST — Health & Problems",
"tileType": "HEADER"
```

Everything under that header until **MUST — Traffic, Errors, Latency** is the health row.

## Example snippets

**Service health**

```json
"name": "Service health",
"tileType": "DATA_EXPLORER",
"customName": "Service health (honeycomb)",
"queries": [{ "metric": "builtin:service.errors.server.rate", "splitBy": ["dt.entity.service"] }],
"visualConfig": { "type": "HONEYCOMB" }
```

**Host health**

```json
"name": "Host health",
"metric": "builtin:host.availability.state",
"visualConfig": { "type": "HONEYCOMB" }
```

**Problems**

```json
"name": "Problems",
"tileType": "OPEN_PROBLEMS"
```

**Database health**

```json
"name": "Database health",
"tileType": "DATABASE"
```

## Not “health tiles” (but related)

| Tile | Role |
| --- | --- |
| Traffic / Errors / Latency | Performance golden signals (not the honeycomb health row) |
| CPU / Memory / Disk / GC | Saturation (host/process pressure) |
| External failures | Dependency error top-list (should-watch) |

## File

`App-Must-Should-Watch-Classic.json` (seq 19 folder / `Host/Host/` copy if present).
