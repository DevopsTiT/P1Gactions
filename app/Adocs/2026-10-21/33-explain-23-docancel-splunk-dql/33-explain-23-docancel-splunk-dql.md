# Explain 23 DoCancel Splunk And DQL

```
What is query 23 asking?
 → Find portals-amp-backend logs (last 1 day)
 → Unescape / parse JSON
 → Keep only message.url = doCancel
 → AND message.type = CAUGHT_EXCEPTION_ON_BACKEND
 → Show newest first
```

| Key point | Detail |
|---|---|
| What this is | Find backend cancel calls that threw a caught exception |
| Why it matters | doCancel failures mean cancel flow broke for a customer |
| Hard part | `message` is often a **JSON string**, not an object |

## Summary

Splunk **23** searches `portals-amp-backend` for cancel exceptions. DQL does the same, but you must parse the outer JSON, then parse `message` again when it is still a string. Do **not** `replaceString` a verify `dummy` that is already valid JSON — that made `j` empty in the Notebook.

## What the log looks like

```
{"timestamp":"2026-10-20T06:30:16.981Z","level":"info","message":"{\"request_id\":\"...\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\",\"url\":\"/api/doCancel\"}"}
```

| Piece | Meaning |
|---|---|
| Outer JSON | `timestamp`, `level`, `message` |
| `message` value | Another JSON document stored as **text** (escaped quotes) |
| `type` | What happened (exception vs completed) |
| `url` | Which API path (here: doCancel) |

---

## Splunk (item 23) — line by line

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw, "\\\"", "\"")
| eval _raw=replace(_raw, "\\", "")
| spath
| search message.url="doCancel" message.type="CAUGHT_EXCEPTION_ON_BACKEND"
```

| Line | Plain English | Why you care |
|---|---|---|
| `sourcetype="portals-amp-backend" earliest=-1d` | Backend logs from the last day | Right app + time window |
| `eval _raw=replace(...)` (twice) | Clean escape characters in the raw event | Splunk often sees double-escaped JSON |
| `spath` | Turn JSON into fields like `message.url` | So you can filter on nested keys |
| `search message.url=... message.type=...` | Keep only doCancel + caught exception | The actual alert condition |

---

## DQL — same story (correct version)

### Verify dummy (Notebook)

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

**Pass:** `msg_url` contains `doCancel`, `msg_type = CAUGHT_EXCEPTION_ON_BACKEND`.

### Live

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

| Step | Plain English | Splunk twin |
|---|---|---|
| `filter ... portals-amp-backend` | Right workload | `sourcetype=...` |
| `parse content, "JSON:j"` | Outer JSON → object `j` | `spath` (outer) |
| `msg_raw = toString(j[message])` | `message` is still text | (Splunk often flattens more) |
| `parse msg_raw, "JSON:msg"` | Inner JSON → object `msg` | `message.url` / `message.type` |
| `contains(msg_url, "doCancel")` | URL may be path or full URL | `message.url="doCancel"` |
| `msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` | Exception type | same |

---

## Why replace broke the Notebook

| Idea | Explanation |
|---|---|
| DQL `dummy = "{\"message\":\"{\\\"url\\\":...}\"}"` | After the string is built, it is **already** valid JSON |
| `replaceString(..., "\\\"", "\"")` | Strips the escapes **inside** `message` |
| Result in `raw` | `"message":"{request_id":...` → invalid → `j` empty |

| Do | Don’t |
|---|---|
| `parse dummy, "JSON:j"` with no replace | Replace a dummy that is already valid |
| Second parse on `j[message]` | Only `j[message][url]` when message is a string |
| Live: try `parse content` first | Blind copy of Splunk’s two replaces |

Only if **live** `content` still shows `\\\"` and outer parse fails, then one light replace **before** parse. If `raw` becomes `"message":"{request_id"`, undo the replace.

---

## Happy path vs common mistakes

| Path | What you see |
|---|---|
| Happy path | `j` filled, `msg_url` / `msg_type` filled, filter keeps the row |
| Replace on valid dummy | `j` empty, all `msg_*` null |
| Sample type is `CONTROLLER_EXECUTION` | 0 rows after filter (wrong type for #23) |
| Exact `msg_url == "doCancel"` but log has `/api/doCancel` | 0 rows — use `contains` |

---

## Data flow map

```
portals-amp-backend log / dummy
  → (live) parse content as JSON:j     ← usually no replace
  → msg_raw = j[message]               ← still a string
  → parse msg_raw as JSON:msg
  → msg_url / msg_type
  → keep doCancel + CAUGHT_EXCEPTION_ON_BACKEND
  → sort newest first
```

## Related files

| File | Role |
|---|---|
| `32-fix-23-parse-no-replace-dummy/` | Fix pack (verify + live DQL) |
| `30-explain-22-license-splunk-dql/` | Same explain style for item 22 |
| `33.sh` | Dual-write |

## Commands

See [33.sh](33.sh).
