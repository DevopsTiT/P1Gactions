# Transform 25 DoesRefundExist Execution Completed

```
portals-amp-backend + doesRefundExist + EXECUTION_COMPLETED?
 → filter backend
 → parse content JSON:j → parse message JSON:msg
 → contains(url, "doesRefundExist") AND type == EXECUTION_COMPLETED
 → sort newest first
```

| Key point | Detail |
|---|---|
| What this is | Successful doesRefundExist completions (last 1 day) |
| Same as #24 | Only the URL token changes: `doesRefundExist` instead of `doCancel` |

## Summary

Same DQL pattern as doCancel EXECUTION_COMPLETED. Filter URL with `contains(..., "doesRefundExist")` so full gateway URLs still match.

## Splunk (source)

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw, "\\\"", "\"")
| eval _raw=replace(_raw, "\\\"", "\"")
| spath
| search message.url=*doesRefundExist* message.type="EXECUTION_COMPLETED"
```

## DQL (live)

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend")
    or contains(k8s.pod.name, "portals-amp-backend")
    or contains(log.source, "portals-amp-backend")
| parse content, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = coalesce(toString(msg[url]), toString(j[message][url])),
            msg_type = coalesce(toString(msg[type]), toString(j[message][type]))
| filter contains(msg_url, "doesRefundExist")
    and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, host.name, msg_url, msg_type, content
```

## Verify dummy (no replaceString)

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T08:33:22.916Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"req-1\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"url\\\":\\\"https://portals-api-gateway.example.internal/doesRefundExist\\\",\\\"method\\\":\\\"post\\\"}\"}"
| fields dummy
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "doesRefundExist")
    and msg_type == "EXECUTION_COMPLETED"
| fields msg_url, msg_type, msg_raw
```

**Pass:** `msg_type = EXECUTION_COMPLETED`, `msg_url` contains `doesRefundExist`.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `message.url=*doesRefundExist*` | `contains(msg_url, "doesRefundExist")` |
| `message.type="EXECUTION_COMPLETED"` | `msg_type == "EXECUTION_COMPLETED"` |

## Data flow map

```
portals-amp-backend content
  → parse JSON:j → parse j[message] → msg
  → msg_url contains doesRefundExist
  → msg_type == EXECUTION_COMPLETED
  → sort desc → fields
```

## Related files

| File | Role |
|---|---|
| `35-transform-25-doesrefundexist-execution-completed.dql` | Live + verify |
| `34-transform-24-docancel-execution-completed/` | Same pattern (doCancel) |
| `35.sh` | Dual-write |

## Commands

See [35.sh](35.sh).
