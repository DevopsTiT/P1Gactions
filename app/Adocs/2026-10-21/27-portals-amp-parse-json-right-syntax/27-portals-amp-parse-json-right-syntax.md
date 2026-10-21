# Portals AMP Parse JSON Right Syntax

```
Dummy unescapes but message still a string?
 → parse raw, "JSON:j"   (name the object — not bare "JSON")
 → message is object? → j[message][type]
 → message is string? → parse toString(j[message]), "JSON:msg" → msg[type]
 → then filter EXECUTION_COMPLETED / url
```

| Key point | Detail |
|---|---|
| Wrong | `parse raw, "JSON"` with no alias (hard to reuse) |
| Right | `parse raw, "JSON:j"` then read `j[…]` |
| Nested string | Parse `message` a **second** time when it is `"{\"request_id\":…}"` |

## Summary

Your unescape + first parse is fine. The sample shows `message` as a **JSON string inside JSON**, so you must parse it again before you can filter `type` / `url`.

## Right syntax — verify dummy (your style)

Use this when `message` is a **string** (like your Notebook result):

```
fetch logs
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-20T05:46:14.825Z\",\"level\":\"info\",\"message\":\"{\\\"request_id\\\":\\\"d7afbd20-7144-4d9b-b318-23d13929f62d\\\",\\\"account_number\\\":\\\"A123\\\",\\\"type\\\":\\\"EXECUTION_COMPLETED\\\",\\\"url\\\":\\\"/amp/typelist/getTypeList\\\",\\\"service\\\":\\\"frontendExpress\\\"}\"}"
| fields dummy
| fieldsAdd raw = replaceString(replaceString(dummy, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd level = toString(j[level]),
            msg_type = toString(msg[type]),
            msg_url = toString(msg[url]),
            request_id = toString(msg[request_id])
| filter msg_type == "EXECUTION_COMPLETED"
    and contains(msg_url, "getTypeList")
| fields level, msg_type, msg_url, request_id, raw
```

**Pass:** one row with `msg_type = EXECUTION_COMPLETED` and `msg_url` containing `getTypeList`.

### If `message` is already an object (not a string)

Some lines look like `"message": { "type": "EXECUTION_COMPLETED", … }` — then **one** parse is enough:

```
fetch logs
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T06:41:15.539Z\",\"level\":\"info\",\"message\":{\"type\":\"EXECUTION_COMPLETED\",\"url\":\"/amp/typelist/getTypeList\",\"service\":\"frontendExpress\"}}"
| fields dummy
| fieldsAdd raw = replaceString(replaceString(dummy, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd level = toString(j[level]),
            msg_type = toString(j[message][type]),
            msg_url = toString(j[message][url])
| filter msg_type == "EXECUTION_COMPLETED"
    and contains(msg_url, "getTypeList")
| fields level, msg_type, msg_url, raw
```

---

## What was wrong in your Notebook

| Your line | Problem | Fix |
|---|---|---|
| `parse raw, "JSON"` | No named field | `parse raw, "JSON:j"` |
| Stop after first parse | `message` still a string column | `parse msg_raw, "JSON:msg"` |
| Filter on raw text only | Hard for nested fields | Filter `msg_type` / `msg_url` |

---

## Live query (real portals-amp-frontend logs)

Handles **both** shapes (object or string `message`):

```
fetch logs, from:now()-24h
| filter contains(k8s.container.name, "portals-amp-frontend")
    or contains(k8s.pod.name, "portals-amp-frontend")
    or contains(log.source, "portals-amp-frontend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd level = toString(j[level])
| fieldsAdd msg_raw = toString(j[message])
| fieldsAdd msg_type = if(isNotNull(j[message][type]), toString(j[message][type]), else: "")
| fieldsAdd msg_url = if(isNotNull(j[message][url]), toString(j[message][url]), else: "")
// If message was a JSON string, fill type/url from second parse:
| parse msg_raw, "JSON:msg"
| fieldsAdd msg_type = if(msg_type != "", msg_type, else: toString(msg[type]))
| fieldsAdd msg_url = if(msg_url != "", msg_url, else: toString(msg[url]))
| filter msg_type == "EXECUTION_COMPLETED"
    and contains(msg_url, "getTypeList")
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, level, msg_type, msg_url, raw
```

Simpler live version if you know all lines use **string** `message` (matches your Notebook):

```
fetch logs, from:now()-24h
| filter contains(k8s.container.name, "portals-amp-frontend")
    or contains(k8s.pod.name, "portals-amp-frontend")
    or contains(log.source, "portals-amp-frontend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd level = toString(j[level]),
            msg_type = toString(msg[type]),
            msg_url = toString(msg[url])
| filter msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, host.name, level, msg_type, msg_url, raw
```

---

## Splunk unescape ↔ DQL

| Splunk | DQL |
|---|---|
| `eval _raw=replace(_raw,"\\\"","\"")` | `replaceString(content, "\\\"", "\"")` |
| (second cleanup) | wrap again: `replaceString(…, "\\", "")` as you already do |
| `spath` / nested fields | `parse …, "JSON:j"` then `j[field]` or second parse |

## Data flow map

```
dummy / content
  → replaceString unescape → raw
  → parse JSON:j          → level, message
  → message is string?
       yes → parse JSON:msg → type, url, request_id
       no  → j[message][type], j[message][url]
  → filter
```

## Related files

| File | Role |
|---|---|
| `27-portals-amp-parse-json-right-syntax.dql` | Copy-paste |
| `../26-portals-amp-frontend-filter-dummy/` | Earlier phrase-only dummy |
| `27.sh` | Mirror |

## Commands

See [27.sh](./27.sh).
