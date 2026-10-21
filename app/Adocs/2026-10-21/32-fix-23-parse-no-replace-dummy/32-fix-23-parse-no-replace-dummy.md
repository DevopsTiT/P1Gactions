# Fix 23 Parse No Replace Dummy

```
j empty / msg_* null after parse?
 → look at raw: does it show "message":"{request_id"  (broken)?
 → yes → replaceString removed escapes inside message → stop replace on dummy
 → dummy string in DQL is already valid JSON → parse dummy directly
 → then second parse on toString(j[message])
 → still broken? dummy must be complete (closing } and ")
```

| Key point | Detail |
|---|---|
| What went wrong | `replaceString(dummy, "\\\"", "\"")` broke valid nested JSON |
| Proof in your table | `raw` looks like `"message":"{request_id":...` (invalid) |
| Fix | **No replace** on the verify dummy — `parse dummy, "JSON:j"` |

## Summary

Your `dummy` value is already good JSON. The replace step turned the inner `\"` into bare `"`, which ends the string too early, so `parse` fails and `j` stays empty. Drop the replace for the Notebook test; parse twice on the string `message`.

## What your table showed

| Column | What you saw | Meaning |
|---|---|---|
| `dummy` | Escaped JSON text | OK as a string literal |
| `raw` | `"message":"{request_id":...` | Invalid JSON after replace |
| `j` | empty | Outer parse failed |
| `msg_*` | null | Nothing to read from `j` |

## Right verify (paste this)

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-20T06:30:16.981Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"3956aee6-c322-4c19-a12e-506f8b7dcaf4\\\",\\\"client_request_id\\\":\\\"dea8660c-74b7-4b49-982e-ae6719539eda\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"CAUGHT_EXCEPTION_ON_BACKEND\\\",\\\"url\\\":\\\"/api/doCancel\\\"}\"}"
| fields dummy
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "doCancel")
    and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| fields msg_url, msg_type, msg_raw
```

**Pass:** `msg_url` contains `doCancel`, `msg_type = CAUGHT_EXCEPTION_ON_BACKEND`, `j` is not empty.

### Optional: triple-quote style (easier to read)

If your Notebook accepts `"""` strings:

```
fetch logs
| limit 1
| fieldsAdd dummy = """{"timestamp":"2026-10-20T06:30:16.981Z","level":"info","message":"{\"request_id\":\"3956aee6-c322-4c19-a12e-506f8b7dcaf4\",\"client_request_id\":\"dea8660c-74b7-4b49-982e-ae6719539eda\",\"service\":\"backendExpress\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\",\"url\":\"/api/doCancel\"}"}"""
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| fields msg_url, msg_type, msg_raw
```

## Live #23 (real logs)

Try **no replace** first (Dynatrace `content` is often already one level cleaner than Splunk `_raw`):

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend")
    or contains(k8s.pod.name, "portals-amp-backend")
    or contains(log.source, "portals-amp-backend")
| parse content, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_url = toString(msg[url]), msg_type = toString(msg[type])
| filter contains(msg_url, "doCancel")
    and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, content
```

Only if live `content` is **double-escaped** (you still see `\\\"` in the UI) and outer parse fails, then use **one** light replace **before** parse — never after the string is already valid JSON:

```
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
```

If that replace makes `raw` look like `"message":"{request_id"` again, undo it — content was already valid.

## Escape rule (remember this)

| Stage | Should look like |
|---|---|
| Valid outer JSON | `"message":"{\"request_id\":\"...\"}"` |
| Broken (your `raw`) | `"message":"{request_id":"..."` |
| After first parse | `j[message]` = string `{"request_id":"..."}` |
| After second parse | `msg[url]`, `msg[type]` |

## Data flow map

```
dummy (already valid JSON in DQL)
  → parse JSON:j          ← no replaceString
  → msg_raw = j[message]  (string)
  → parse JSON:msg
  → msg_url / msg_type
  → filter doCancel + CAUGHT_EXCEPTION_ON_BACKEND
```

## Related files

| File | Role |
|---|---|
| `32-fix-23-parse-no-replace-dummy.dql` | Verify + live |
| `32.sh` | Dual-write |
| `31-fix-23-message-string-parse/` | Right idea (second parse); replace on dummy was the remaining bug |

## Commands

See [32.sh](32.sh).
