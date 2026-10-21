# Transform 26 IsPolicyCancelAvailable Execution Completed

```
portals-amp-backend + isPolicyCancelAvailable + EXECUTION_COMPLETED?
 → filter backend
 → from:now()-7d  (Splunk earliest=-1w)
 → parse JSON:j → parse message JSON:msg
 → contains(url, "isPolicyCancelAvailable") AND type == EXECUTION_COMPLETED
 → sort newest first
```

| Key point | Detail |
|---|---|
| What this is | Successful isPolicyCancelAvailable completions (last 7 days) |
| Same as #24/#25 | Only URL token + time window change |

## Summary

Same portals-amp-backend parse pattern. Use a **7-day** window (`-1w`) and `contains` on `isPolicyCancelAvailable`.

## Splunk (source)

```
sourcetype="portals-amp-backend" earliest=-1w
| eval _raw=replace(_raw, "\\\"", "\"")
| eval _raw=replace(_raw, "\\\"", "\"")
| spath
| search message.url=*isPolicyCancelAvailable* message.type="EXECUTION_COMPLETED"
```

## DQL (live)

```
fetch logs, from:now()-7d
| filter contains(k8s.container.name, "portals-amp-backend")
    or contains(k8s.pod.name, "portals-amp-backend")
    or contains(log.source, "portals-amp-backend")
| parse content, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = coalesce(toString(msg[url]), toString(j[message][url])),
            msg_type = coalesce(toString(msg[type]), toString(j[message][type]))
| filter contains(msg_url, "isPolicyCancelAvailable")
    and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, host.name, msg_url, msg_type, content
```

## Verify dummy (no replaceString)

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T07:42:41.096Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"req-1\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"url\\\":\\\"https://portals-api-gateway.example.internal/isPolicyCancelAvailable\\\",\\\"method\\\":\\\"post\\\"}\"}"
| fields dummy
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "isPolicyCancelAvailable")
    and msg_type == "EXECUTION_COMPLETED"
| fields msg_url, msg_type, msg_raw
```

**Pass:** `msg_type = EXECUTION_COMPLETED`, `msg_url` contains `isPolicyCancelAvailable`.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `earliest=-1w` | `from:now()-7d` |
| `message.url=*isPolicyCancelAvailable*` | `contains(msg_url, "isPolicyCancelAvailable")` |
| `message.type="EXECUTION_COMPLETED"` | `msg_type == "EXECUTION_COMPLETED"` |

## Data flow map

```
portals-amp-backend content (7d)
  → parse JSON:j → parse j[message] → msg
  → msg_url contains isPolicyCancelAvailable
  → msg_type == EXECUTION_COMPLETED
  → sort desc → fields
```

## Related files

| File | Role |
|---|---|
| `36-transform-26-ispolicycancelavailable-execution-completed.dql` | Live + verify |
| `35-transform-25-doesrefundexist-execution-completed/` | Same pattern (1d) |
| `36.sh` | Dual-write |

## Commands

See [36.sh](36.sh).
