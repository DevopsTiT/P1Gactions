# Transform 66 To 69 CC Sonpov ESBv4

```
#66 cc-* + NoUpdatePaymentError?
#67 sonpov OR temp-receipt-accounting + ERROR lines (group by time)?
#68 cc-ui + removeDocument called for DocUID?
#69 esbv4 + ebroker POST 503 service unavailable?
```

| Key point | Detail |
|---|---|
| #66 | Simple phrase on all cc-* |
| #67 | Parse log level, keep ERROR, summarize by timestamp |
| #68 / #69 | Phrase filters; #69 splits URL prefix + 503 suffix |
| #70 | Completed in `16-transform-70-ebroker-address-conversion/` |

## Summary

**66–69** match your drafts, with `caseSensitive:false` and `log.source` fallbacks. **67** uses the proven timestamp/level parse (`yyyy-mm-dd hh:mm:ss LEVEL`).

---

## #66 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "cc-")
    or contains(log.source, "cc-", caseSensitive:false)
| filter contains(content, "NoUpdatePaymentError", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #67 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter contains(src, "sonpov", caseSensitive:false)
    or contains(src, "temp-receipt-accounting", caseSensitive:false)
    or contains(log.source, "sonpov", caseSensitive:false)
    or contains(log.source, "temp-receipt-accounting", caseSensitive:false)
| parse content, "INT '-' INT '-' INT SPACE INT ':' INT ':' INT SPACE ALPHA:loglevel_parsed"
| filter loglevel_parsed == "ERROR"
| summarize loglevel = collectDistinct(loglevel_parsed),
            log = collectDistinct(content),
            podname = collectDistinct(src),
            by:{ timestamp }
| sort timestamp desc
```

## #68 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "cc-ui")
    or contains(log.source, "cc-ui", caseSensitive:false)
| filter contains(content, "removeDocument called for document with DocUID", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #69 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter contains(src, "esbv4", caseSensitive:false)
    or contains(log.source, "esbv4", caseSensitive:false)
    or startsWith(src, "esbv4")
| filter contains(content, "Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/", caseSensitive:false)
    and contains(content, "failed: service unavailable (503).", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## Verify dummies

```
// #66
fetch logs | limit 1
| fieldsAdd dummy = "ERROR PaymentService - NoUpdatePaymentError: payment record 88123 is locked"
| fieldsAdd pod = "cc-ui-6f8d9c7b4-abcde"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "cc-")
| filter contains(dummy, "NoUpdatePaymentError", caseSensitive:false)
| fields src, dummy

// #68
fetch logs | limit 1
| fieldsAdd dummy = "INFO DocumentService - removeDocument called for document with DocUID DOC-000731"
| fieldsAdd pod = "cc-ui-6f8d9c7b4-abcde"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "cc-ui")
| filter contains(dummy, "removeDocument called for document with DocUID", caseSensitive:false)
| fields src, dummy

// #69
fetch logs | limit 1
| fieldsAdd dummy = "ERROR Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/ebroker/api/policy/issue' failed: service unavailable (503)."
| fieldsAdd pod = "esbv4-7c9d8b6f5-k2m4p"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter contains(src, "esbv4", caseSensitive:false)
| filter contains(dummy, "Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/", caseSensitive:false)
    and contains(dummy, "failed: service unavailable (503).", caseSensitive:false)
| fields src, dummy
```

## Data flow map

```
#66: cc-* → NoUpdatePaymentError
#67: sonpov|temp-receipt → parse ERROR → summarize by time
#68: cc-ui → removeDocument DocUID
#69: esbv4 → ebroker POST … 503
```

## Related files

| File | Role |
|---|---|
| `15-transform-66-to-69-cc-sonpov-esbv4.dql` | All four |
| `2026-10-14/16-cc-esbv4-ebroker-silent-dql/` | Earlier pack (#66–#70) |
| `15.sh` | Dual-write |

## Commands

See [15.sh](15.sh).
