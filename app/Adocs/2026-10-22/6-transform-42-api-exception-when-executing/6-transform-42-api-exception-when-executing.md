# Transform 42 API Exception When Executing

```
bc2-ui OR bc2-batch OR bcsubledger + "API - Exception when executing"?
 → match any of the three apps (caseSensitive:false / lower src)
 → contains exception text (caseSensitive:false)
 → sort newest first
```

| Key point | Detail |
|---|---|
| What this is | API execution exceptions across BC2 UI, batch, and subledger |
| Splunk indexes | `bc2-ui` OR `bc2-batch` OR `bcsubledger` / `bc2subledger` |
| Filter text | `API - Exception when executing` |

## Summary

Item **42** is a plain text search across three BC2 apps. No JSON parse. Keep rows that mention the exception phrase.

## Splunk (source)

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)
  "API - Exception when executing"
```

(Your UI may show `bc2subledger` — DQL below matches both spellings.)

## DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-ui")
    or startsWith(src, "bc2-batch")
    or startsWith(src, "bcsubledger")
    or startsWith(src, "bc2subledger")
    or contains(log.source, "bc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-batch", caseSensitive:false)
    or contains(log.source, "bcsubledger", caseSensitive:false)
    or contains(log.source, "bc2subledger", caseSensitive:false)
| filter contains(content, "API - Exception when executing", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, src, content
```

## Verify dummy

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 ERROR [ApiWorker-1] RestGateway - API - Exception when executing POST /ledger/v1/postings: java.net.SocketTimeoutException"
| fieldsAdd pod = "bcsubledger-7b5d9c6f8-t2xkn"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bcsubledger") or startsWith(src, "bc2subledger")
| filter contains(dummy, "API - Exception when executing", caseSensitive:false)
| fields src, dummy
```

**Pass:** one row with the exception text.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| three indexes OR | `startsWith(src, ...)` / `contains(log.source, ..., caseSensitive:false)` |
| `"API - Exception when executing"` | `contains(content, "...", caseSensitive:false)` |

## Data flow map

```
bc2-ui / bc2-batch / bcsubledger logs
  → content contains "API - Exception when executing"
  → sort desc → fields
```

## Related files

| File | Role |
|---|---|
| `6-transform-42-api-exception-when-executing.dql` | Live + verify |
| `6.sh` | Dual-write |

## Commands

See [6.sh](6.sh).
