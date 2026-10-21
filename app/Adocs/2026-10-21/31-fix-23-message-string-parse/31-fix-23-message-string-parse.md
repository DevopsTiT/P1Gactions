# Fix 23 Message String Parse

```
msg_url / msg_type null?
 → look at sample: "message":"{ \"request_id\": ... }"  (string, not object)
 → stop wiping all backslashes: do NOT replaceString(..., "\\", "")
 → parse outer JSON:j
 → parse toString(j[message]) as JSON:msg
 → filter msg[url] / msg[type]
 → still null? check type value (sample may be CONTROLLER_EXECUTION, not CAUGHT_...)
```

| Key point | Detail |
|---|---|
| What broke | `j[message][url]` needs `message` to be an **object** |
| Your sample | `message` is a **string of JSON** |
| Extra damage | Second replace that deletes every `\` makes outer JSON invalid / fields null |

## Summary

Item **23** examples failed because the real portals-amp-backend line stores `message` as an escaped JSON **string**. One outer parse is not enough, and `replaceString(..., "\\", "")` often destroys the nested escapes. Use a light unescape, parse twice, then filter.

## Why your Notebook shows null

| What you did | What happened |
|---|---|
| `j[message][url]` after one parse | `j[message]` is still text → no `[url]` → null |
| `replaceString(..., "\\\\", "")` or `"\\", ""` | Strips escapes inside the message string → parse/`j` unreliable |
| Filter `msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` on sample | Sample may say `CONTROLLER_EXECUTION` → 0 rows even after fix |

Broken shape after over-unescape (conceptually):

```
"message":"{"request_id":"..." }   ← invalid / not a nested object
```

Needed shape after light unescape + first parse:

```
j.message = '{"request_id":"...","type":"CAUGHT_EXCEPTION_ON_BACKEND","url":"/api/doCancel"}'  ← string
→ second parse → msg.type / msg.url
```

## Right verify dummy (matches your sample shape)

```
fetch logs
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-20T06:30:16.981Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"3956aee6-c322-4c19-a12e-506f8b7dcaf4\\\",\\\"client_request_id\\\":\\\"dea8660c-74b7-4b49-982e-ae6719539eda\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"CAUGHT_EXCEPTION_ON_BACKEND\\\",\\\"url\\\":\\\"/api/doCancel\\\"}\"}"
| fields dummy
| fieldsAdd raw = replaceString(dummy, "\\\"", "\"")
| parse raw, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "doCancel")
    and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| fields msg_url, msg_type, raw
```

**Pass:** one row, `msg_url` contains `doCancel`, `msg_type = CAUGHT_EXCEPTION_ON_BACKEND`.

## Live DQL for Splunk #23

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend")
    or contains(k8s.pod.name, "portals-amp-backend")
    or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "doCancel")
    and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

If some lines already have `message` as an object (older verify samples), this still often works: `toString(j[message])` then parse may fail for those rows — use the dual-shape version below when both shapes exist.

### Dual-shape live (string or object `message`)

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend")
    or contains(k8s.pod.name, "portals-amp-backend")
    or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = coalesce(toString(msg[url]), toString(j[message][url])),
            msg_type = coalesce(toString(msg[type]), toString(j[message][type]))
| filter contains(msg_url, "doCancel")
    and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `sourcetype="portals-amp-backend"` | filter container / pod / log.source |
| `replace` then `spath` | light `replaceString` + `parse JSON:j` + second parse on `message` |
| `message.url="doCancel"` | `contains(msg_url, "doCancel")` (URL may be a path or full URL) |
| `message.type="CAUGHT_EXCEPTION_ON_BACKEND"` | `msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` |

## Do / don’t

| Do | Don’t |
|---|---|
| One light unescape: `\\\"` → `"` | Second wipe of every `\` |
| Second `parse` on `j[message]` string | Only `j[message][url]` on string message |
| `contains(msg_url, "doCancel")` | Exact `== "doCancel"` if URL is a full path |

## Data flow map

```
content / dummy  (message is escaped JSON string)
  → replaceString only \\\" → "
  → parse JSON:j          (outer)
  → msg_raw = j[message]  (still a string)
  → parse JSON:msg        (inner)
  → msg_url / msg_type
  → filter doCancel + CAUGHT_EXCEPTION_ON_BACKEND
```

## Related files

| File | Role |
|---|---|
| `31-fix-23-message-string-parse.dql` | Verify + live |
| `31.sh` | Dual-write |
| `27-portals-amp-parse-json-right-syntax/` | Same string-message pattern (frontend) |
| `14-verify-dql-1-to-85-dummy/` | Old #23 used object `message` — wrong for your sample |

## Commands

See [31.sh](31.sh).
