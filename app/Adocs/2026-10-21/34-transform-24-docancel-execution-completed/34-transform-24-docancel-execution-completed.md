# Transform 24 DoCancel Execution Completed

```
portals-amp-backend + doCancel + EXECUTION_COMPLETED?
 → filter backend (container / pod / log.source)
 → parse content JSON:j
 → message string? → parse again as JSON:msg
 → contains(url, "doCancel") AND type == EXECUTION_COMPLETED
 → sort newest first
```

| Key point | Detail |
|---|---|
| What this is | Successful doCancel completions (last 1 day) |
| Splunk | `message.url=*doCancel*` + `message.type="EXECUTION_COMPLETED"` |
| Diff from #23 | Same shape; type is `EXECUTION_COMPLETED` not `CAUGHT_EXCEPTION_ON_BACKEND` |

## Summary

Same parse pattern as #23. Your Splunk sample shows a full gateway URL containing `doCancel` and type `EXECUTION_COMPLETED`. Use `contains` on the URL so path or full URL both match.

## Splunk (source)

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw, "\\\"", "\"")
| eval _raw=replace(_raw, "\\\"", "\"")
| spath
| search message.url=*doCancel* message.type="EXECUTION_COMPLETED"
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
| filter contains(msg_url, "doCancel")
    and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, host.name, msg_url, msg_type, content
```

## Verify dummy (no replaceString)

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T08:15:46.514Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"2f72291-1334-4858-bcc5-2255c517212c\\\",\\\"client_request_id\\\":\\\"22aa8439-bd18-42a9-bdbe-2311a7deba2f\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"url\\\":\\\"https://portals-api-gateway.example.internal/doCancel\\\",\\\"method\\\":\\\"post\\\",\\\"target_system\\\":\\\"PC_CUSTOMER\\\"}\"}"
| fields dummy
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "doCancel")
    and msg_type == "EXECUTION_COMPLETED"
| fields msg_url, msg_type, msg_raw
```

**Pass:** `msg_type = EXECUTION_COMPLETED`, `msg_url` contains `doCancel`.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `sourcetype="portals-amp-backend"` | filter container / pod / log.source |
| `earliest=-1d` | `from:now()-1d` |
| `spath` | `parse` outer + optional second parse on `message` |
| `message.url=*doCancel*` | `contains(msg_url, "doCancel")` |
| `message.type="EXECUTION_COMPLETED"` | `msg_type == "EXECUTION_COMPLETED"` |

## Data flow map

```
portals-amp-backend content
  → parse JSON:j
  → parse j[message] → msg
  → msg_url contains doCancel
  → msg_type == EXECUTION_COMPLETED
  → sort desc → fields
```

## Related files

| File | Role |
|---|---|
| `34-transform-24-docancel-execution-completed.dql` | Live + verify |
| `33-explain-23-docancel-splunk-dql/` | Same pattern for exception type |
| `32-fix-23-parse-no-replace-dummy/` | Why no replace on dummy |
| `34.sh` | Dual-write |

## Commands

See [34.sh](34.sh).
