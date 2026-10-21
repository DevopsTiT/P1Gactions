# Portals AMP Frontend Filter Dummy

```
Splunk: sourcetype=portals-amp-frontend + unescape quotes
 → Verify: fetch logs | fieldsAdd dummy = "<JSON piece>" | filter on dummy
 → Live: filter portals-amp-frontend → replaceString unescape → parse JSON
 → Filter msg type / url as needed
```

| Key point | Detail |
|---|---|
| Splunk source | `sourcetype="portals-amp-frontend"` |
| Your sample | `level=info`, `message.type=EXECUTION_COMPLETED`, `url=/amp/typelist/getTypeList` |
| Dummy style | Same as afterBind: `fieldsAdd dummy`, **not** `data record` |

## Summary

Use a short copy of your Splunk JSON line as `dummy` to prove filters. Then use the live DQL that unescapes quotes the same way Splunk `replace` does.

## Example log piece (from your screen)

```
{"timestamp":"2026-10-21T06:41:15.539Z","level":"info","message":{"request_id":"…","service":"frontendExpress","type":"EXECUTION_COMPLETED","url":"/amp/typelist/getTypeList","method":"POST"}}
```

---

## Verify — filter dummy (like afterBind)

```
// Verify: portals-amp-frontend EXECUTION_COMPLETED + getTypeList
fetch logs
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-21T06:41:15.539Z\",\"level\":\"info\",\"message\":{\"service\":\"frontendExpress\",\"type\":\"EXECUTION_COMPLETED\",\"url\":\"/amp/typelist/getTypeList\",\"method\":\"POST\"}}"
| fields dummy
| filter contains(dummy, "portals-amp-frontend", caseSensitive:false)
    or contains(dummy, "EXECUTION_COMPLETED", caseSensitive:false)
| filter contains(dummy, "EXECUTION_COMPLETED", caseSensitive:false)
    and contains(dummy, "getTypeList", caseSensitive:false)
```

Simpler (phrase-only, closest to afterBind):

```
// Verify:
fetch logs
| fieldsAdd dummy = "{\"level\":\"info\",\"message\":{\"type\":\"EXECUTION_COMPLETED\",\"url\":\"/amp/typelist/getTypeList\",\"service\":\"frontendExpress\"}}"
| fields dummy
| filter contains(dummy, "EXECUTION_COMPLETED", caseSensitive:false)
    and contains(dummy, "getTypeList", caseSensitive:false)
```

**Pass:** the dummy row still shows.

### Verify with unescape + parse (same logic as live)

```
fetch logs
| fieldsAdd content = "{\"level\":\"info\",\"message\":{\"type\":\"EXECUTION_COMPLETED\",\"url\":\"/amp/typelist/getTypeList\",\"service\":\"frontendExpress\"}}"
| fields content
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_type = toString(j[message][type]), msg_url = toString(j[message][url]), level = toString(j[level])
| filter msg_type == "EXECUTION_COMPLETED"
    and contains(msg_url, "getTypeList")
| fields level, msg_type, msg_url, raw
```

**Pass:** one row, `msg_type=EXECUTION_COMPLETED`, `msg_url` contains `getTypeList`.

---

## Live DQL (real logs)

```
fetch logs, from:now()-24h
| filter contains(k8s.container.name, "portals-amp-frontend")
    or contains(k8s.pod.name, "portals-amp-frontend")
    or contains(log.source, "portals-amp-frontend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_type = toString(j[message][type]),
            msg_url = toString(j[message][url]),
            level = toString(j[level])
| filter msg_type == "EXECUTION_COMPLETED"
    and contains(msg_url, "getTypeList")
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, level, msg_type, msg_url, raw
```

Drop the `getTypeList` line if you want **all** `EXECUTION_COMPLETED` from portals-amp-frontend.

### Splunk → DQL

| Splunk | DQL |
|---|---|
| `sourcetype="portals-amp-frontend"` | `contains(…, "portals-amp-frontend")` on container / pod / log.source |
| `eval _raw=replace(_raw,"\\\"","\"")` (twice) | `replaceString(replaceString(content, "\\\"", "\""), "\\", "")` |
| (later) `spath` / message fields | `parse raw, "JSON:j"` then `j[message][type]` |

## Data flow map

```
Splunk JSON line
  → fieldsAdd dummy / content
  → (optional) unescape + parse
  → filter EXECUTION_COMPLETED + url
  → pass → live fetch on portals-amp-frontend
```

## Related files

| File | Role |
|---|---|
| `26-portals-amp-frontend-filter-dummy.dql` | Copy-paste |
| `../2026-10-15/16-dql-1-to-85-line-by-line/` | Related #20–#28 AMP DQL |
| `26.sh` | Mirror |

## Commands

See [26.sh](./26.sh).
