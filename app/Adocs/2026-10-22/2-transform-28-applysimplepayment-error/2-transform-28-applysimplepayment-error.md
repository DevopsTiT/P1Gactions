# Transform 28 ApplySimplePayment Error

```
claim customer frontend OR backend + error + applySimplePayment?
 → filter both sourcetypes (caseSensitive:false)
 → parse content JSON:j (no wipe-all-\ replace)
 → message string? → second parse JSON:msg
 → level == error AND url == /customer/exposure/applySimplePayment
 → fields
```

| Key point | Detail |
|---|---|
| What this is | Errors on applySimplePayment from claim customer FE/BE |
| Time | Last 24h (`from:now()-24h`) |
| contains | Always `caseSensitive:false` |

## Summary

Splunk **28** looks at claim-customer frontend and backend, parses JSON, and keeps only `level=error` with `message.url=/customer/exposure/applySimplePayment`. DQL uses the same double-parse pattern as amp-backend; do not strip every `\`.

## Splunk (source)

```
sourcetype="portals-claim-customer-frontend" OR sourcetype="portals-claim-customer-backend"
| eval _raw=replace(_raw, "\\\"", "\"")
| eval _raw=replace(_raw, "\\\"", "\"")
| spath
| search "level"="error" AND "message.url"="/customer/exposure/applySimplePayment"
```

## DQL (live)

```
fetch logs, from:now()-24h
| filter (
        contains(k8s.container.name, "portals-claim-customer-frontend", caseSensitive:false)
        or contains(k8s.pod.name, "portals-claim-customer-frontend", caseSensitive:false)
        or contains(log.source, "portals-claim-customer-frontend", caseSensitive:false)
        or contains(k8s.container.name, "portals-claim-customer-backend", caseSensitive:false)
        or contains(k8s.pod.name, "portals-claim-customer-backend", caseSensitive:false)
        or contains(log.source, "portals-claim-customer-backend", caseSensitive:false)
      )
| parse content, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd log_level = coalesce(toString(j[level]), toString(msg[level])),
            message_url = coalesce(toString(msg[url]), toString(j[message][url]))
| filter log_level == "error"
    and message_url == "/customer/exposure/applySimplePayment"
| sort timestamp desc
| fields timestamp, host.name, log.source, log_level, message_url, content
```

If outer parse fails because live `content` is double-escaped, use **one** light replace only:

```
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
```

Stop if `raw` looks like `"message":"{request_id"` (broken).

## Verify dummy (no replaceString)

```
fetch logs
| limit 1
| fieldsAdd dummy = "{\"timestamp\":\"2026-10-22T00:00:00.000Z\",\"level\":\"error\",\"message\":\"{\\\"request_id\\\":\\\"req-1\\\",\\\"service\\\":\\\"backendExpress\\\",\\\"type\\\":\\\"CAUGHT_EXCEPTION_ON_BACKEND\\\",\\\"url\\\":\\\"/customer/exposure/applySimplePayment\\\"}\"}"
| fields dummy
| parse dummy, "JSON:j"
| fieldsAdd msg_raw = toString(j[message])
| parse msg_raw, "JSON:msg"
| fieldsAdd log_level = toString(j[level]),
            message_url = toString(msg[url])
| filter log_level == "error"
    and message_url == "/customer/exposure/applySimplePayment"
| fields log_level, message_url
```

**Pass:** one row, `log_level=error`, `message_url=/customer/exposure/applySimplePayment`.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| two sourcetypes OR | six `contains` on container/pod/log.source |
| `spath` | `parse` outer + second parse on `message` |
| `level=error` | `log_level == "error"` |
| `message.url=...` | `message_url == "/customer/exposure/applySimplePayment"` |

## Data flow map

```
claim-customer FE or BE logs (24h)
  → contains(..., caseSensitive:false)
  → parse JSON:j → parse message → msg
  → level == error
  → url == /customer/exposure/applySimplePayment
  → fields
```

## Related files

| File | Role |
|---|---|
| `2-transform-28-applysimplepayment-error.dql` | Live + verify |
| `1-dql-contains-casesensitive-false/` | contains rule |
| `2.sh` | Dual-write |

## Commands

See [2.sh](2.sh).
