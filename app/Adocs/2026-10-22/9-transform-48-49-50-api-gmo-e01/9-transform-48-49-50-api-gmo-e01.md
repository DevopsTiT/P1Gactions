# Transform 48 49 50 API GMO E01

```
#48 three apps + "API - Exception when executing"?  → same as #42
#49 three apps + "Exception during GMO call EXECTRAN"? → same as #43
#50 bc2-ui + Map returned + errcode=E01 − known codes?
 → parse errcode → keep E01 → exclude E01390002 / E01260010 / E01110002
```

| Key point | Detail |
|---|---|
| #48 | Same as #42 |
| #49 | Same as #43 |
| #50 | E01 errors on method-call map, minus three ignore codes |

## Summary

**48** / **49** reuse the three-app text filters. **50** keeps `errcode=E01` on bc2-ui “Map returned by method call” lines and drops three known `errinfo` codes.

---

## #48 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-ui")
    or startsWith(src, "bc2-batch")
    or startsWith(src, "bcsubledger")
    or startsWith(src, "bc2subledger")
    or contains(log.source, "bc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-batch", caseSensitive:false)
    or contains(log.source, "bcsubledger", caseSensitive:false)
    or contains(log.source, "bc2subledger", caseSensitive:false)
| filter contains(content, "API - Exception when executing", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #49 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-ui")
    or startsWith(src, "bc2-batch")
    or startsWith(src, "bcsubledger")
    or startsWith(src, "bc2subledger")
    or contains(log.source, "bc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-batch", caseSensitive:false)
    or contains(log.source, "bcsubledger", caseSensitive:false)
    or contains(log.source, "bc2subledger", caseSensitive:false)
| filter contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #50 Splunk

```
index=bc2-ui* "Map returned by method call"
  AND errcode=E01
  AND NOT E01390002 AND NOT E01260010 AND NOT E01110002
```

## #50 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-ui")
    or contains(log.source, "bc2-ui", caseSensitive:false)
    or contains(k8s.pod.name, "bc2-ui", caseSensitive:false)
| filter contains(content, "Map returned by method call", caseSensitive:false)
| parse content, "LD 'errcode=' ALNUM:errcode"
| filter errcode == "E01"
| filter not contains(content, "E01390002", caseSensitive:false)
| filter not contains(content, "E01260010", caseSensitive:false)
| filter not contains(content, "E01110002", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, errcode, content
```

## #50 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-2] GmoClient - Map returned by method call EntryTran: errcode=E01&errinfo=E01170006&OrderID=ORD-20261015-0144"
| fieldsAdd pod = "bc2-ui-7f9c6d-x2kqp"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2-ui")
| filter contains(dummy, "Map returned by method call", caseSensitive:false)
| parse dummy, "LD 'errcode=' ALNUM:errcode"
| filter errcode == "E01"
| filter not contains(dummy, "E01390002", caseSensitive:false)
| filter not contains(dummy, "E01260010", caseSensitive:false)
| filter not contains(dummy, "E01110002", caseSensitive:false)
| fields src, errcode, dummy
```

**Pass:** `errcode=E01`, sample `errinfo=E01170006` kept (not in the exclude list).

## Data flow map

```
#48: three apps → API - Exception when executing
#49: three apps → Exception during GMO call EXECTRAN
#50: bc2-ui → Map returned → errcode=E01 → drop three codes → fields
```

## Related files

| File | Role |
|---|---|
| `9-transform-48-49-50-api-gmo-e01.dql` | All three |
| `6-transform-42-...` / `7-transform-43-44-...` | Twins of #48 / #49 |
| `9.sh` | Dual-write |

## Commands

See [9.sh](9.sh).
