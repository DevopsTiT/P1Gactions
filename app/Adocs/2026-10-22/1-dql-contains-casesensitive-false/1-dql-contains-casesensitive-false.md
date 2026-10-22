# DQL Contains CaseSensitive False

```
Writing DQL contains()?
 → always add caseSensitive:false
 → host / pod / log.source / content — all of them
 → same for #27 and every new item from now on
```

| Key point | Detail |
|---|---|
| Rule | Every `contains(...)` uses `caseSensitive:false` |
| Why | Match Splunk-style case-insensitive search; avoid missed rows |
| Example style | Items 92 / 93 in ADL_ADJ |

## Summary

From now on, DQL filters use case-insensitive `contains`. Below is **#27** rewritten that way (same logic as yesterday; only the `contains` flags change).

## Pattern (copy)

```
contains(log.source, "portals-amp-backend", caseSensitive:false)
contains(content, "error", caseSensitive:false)
```

| Wrong | Right |
|---|---|
| `contains(log.source, "portals-amp-backend")` | `contains(log.source, "portals-amp-backend", caseSensitive:false)` |

## #27 live (updated)

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend", caseSensitive:false)
    or contains(k8s.pod.name, "portals-amp-backend", caseSensitive:false)
    or contains(log.source, "portals-amp-backend", caseSensitive:false)
| parse content, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = coalesce(toString(msg[url]), toString(j[message][url])),
            msg_type = coalesce(toString(msg[type]), toString(j[message][type]))
| filter contains(msg_url, "isPolicyCancelAvailable", caseSensitive:false)
    and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, host.name, msg_url, msg_type, content
```

## #27 verify dummy

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T08:06:53.482Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"req-1\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"url\\\":\\\"https://portals-api-gateway.example.internal/pc/next/cancellation/cancellation/v1/isPolicyCancelAvailable\\\",\\\"method\\\":\\\"post\\\",\\\"target_system\\\":\\\"PC_CUSTOMER\\\"}\"}"
| fields dummy
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "isPolicyCancelAvailable", caseSensitive:false)
    and msg_type == "EXECUTION_COMPLETED"
| fields msg_url, msg_type, msg_raw
```

## Data flow map

```
filter contains(..., caseSensitive:false)
  → parse JSON:j → parse message → msg
  → contains(msg_url, "...", caseSensitive:false)
  → type exact match (still case-sensitive ==)
  → fields
```

Note: exact `==` on `msg_type` stays case-sensitive on purpose (values are `EXECUTION_COMPLETED`). Only `contains` is forced insensitive.

## Related files

| File | Role |
|---|---|
| `1-dql-contains-casesensitive-false.dql` | #27 live + verify |
| `1.sh` | Dual-write |
| Cursor rule | `dql-contains-case-insensitive.mdc` |

## Commands

See [1.sh](1.sh).
