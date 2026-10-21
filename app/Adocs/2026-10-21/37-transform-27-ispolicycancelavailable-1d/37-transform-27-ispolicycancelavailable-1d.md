# Transform 27 IsPolicyCancelAvailable 1d

```
portals-amp-backend + isPolicyCancelAvailable + EXECUTION_COMPLETED (1 day)?
 → same as #26
 → only change: from:now()-1d  (not -7d)
```

| Key point | Detail |
|---|---|
| What this is | Same API as #26, last **1 day** only |
| Splunk | `earliest=-1d` + `*isPolicyCancelAvailable*` + `EXECUTION_COMPLETED` |

## Summary

Item **27** is item **26** with a 1-day window. Same parse and filters; only `from:` changes.

## Splunk (source)

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw, "\\\"", "\"")
| eval _raw=replace(_raw, "\\\"", "\"")
| spath
| search message.url=*isPolicyCancelAvailable* message.type="EXECUTION_COMPLETED"
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
| filter contains(msg_url, "isPolicyCancelAvailable")
    and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, host.name, msg_url, msg_type, content
```

## Verify dummy (no replaceString)

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T08:06:53.482Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"req-1\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"url\\\":\\\"https://portals-api-gateway.example.internal/pc/next/cancellation/cancellation/v1/isPolicyCancelAvailable\\\",\\\"method\\\":\\\"post\\\",\\\"target_system\\\":\\\"PC_CUSTOMER\\\"}\"}"
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

## #26 vs #27

| Item | Time window |
|---|---|
| #26 | `from:now()-7d` (`earliest=-1w`) |
| #27 | `from:now()-1d` (`earliest=-1d`) |

## Data flow map

```
portals-amp-backend content (1d)
  → parse JSON:j → parse j[message] → msg
  → msg_url contains isPolicyCancelAvailable
  → msg_type == EXECUTION_COMPLETED
  → sort desc → fields
```

## Related files

| File | Role |
|---|---|
| `37-transform-27-ispolicycancelavailable-1d.dql` | Live + verify |
| `36-transform-26-ispolicycancelavailable-execution-completed/` | 7-day twin |
| `37.sh` | Dual-write |

## Commands

See [37.sh](37.sh).
