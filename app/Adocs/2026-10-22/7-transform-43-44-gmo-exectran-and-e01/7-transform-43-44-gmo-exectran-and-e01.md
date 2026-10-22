# Transform 43 44 GMO EXECTRAN And E01

```
#43 three BC2 apps + GMO EXECTRAN exception?
 → same app filter as #42
 → contains "Exception during GMO call EXECTRAN"

#44 bc2-ui + errcode E01 / E01050004?
 → startsWith / contains bc2-ui
 → contains "errcode=E01&errinfo=E01050004"
```

| Key point | Detail |
|---|---|
| #43 | GMO EXECTRAN call failures (ui / batch / subledger) |
| #44 | Specific GMO-style error code on bc2-ui only |
| contains | Always `caseSensitive:false` |

## Summary

Both are plain text searches. **43** matches the GMO EXECTRAN exception across three apps. **44** matches a fixed `errcode` / `errinfo` pair on bc2-ui.

## #43 Splunk

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)
AND "Exception during GMO call EXECTRAN"
```

## #43 DQL (live)

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

## #43 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-20 16:49:31,702 ERROR [https-jsse-nio-8443-exec-15] Exception during GMO call EXECTRAN: timeout"
| fieldsAdd pod = "bc2-ui-inssuite-prod-0"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2-ui")
| filter contains(dummy, "Exception during GMO call EXECTRAN", caseSensitive:false)
| fields src, dummy
```

---

## #44 Splunk

```
index=bc2-ui* "errcode=E01&errinfo=E01050004"
```

## #44 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-ui")
    or contains(log.source, "bc2-ui", caseSensitive:false)
    or contains(k8s.pod.name, "bc2-ui", caseSensitive:false)
| filter contains(content, "errcode=E01&errinfo=E01050004", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #44 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-20 16:50:23,151 INFO [http-nio-8080-exec-15] errcode=E01&errinfo=E01050004"
| fieldsAdd pod = "bc2-ui-inssuite-prod-0"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2-ui")
| filter contains(dummy, "errcode=E01&errinfo=E01050004", caseSensitive:false)
| fields src, dummy
```

## Splunk → DQL

| Item | Splunk | DQL text filter |
|---|---|---|
| 43 | `"Exception during GMO call EXECTRAN"` | `contains(content, "...", caseSensitive:false)` |
| 44 | `"errcode=E01&errinfo=E01050004"` | `contains(content, "...", caseSensitive:false)` |

## Data flow map

```
#43: bc2-ui|batch|subledger → GMO EXECTRAN exception → fields
#44: bc2-ui only → errcode=E01&errinfo=E01050004 → fields
```

## Related files

| File | Role |
|---|---|
| `7-transform-43-44-gmo-exectran-and-e01.dql` | Both queries |
| `6-transform-42-api-exception-when-executing/` | Same three-app filter pattern |
| `7.sh` | Dual-write |

## Commands

See [7.sh](7.sh).
