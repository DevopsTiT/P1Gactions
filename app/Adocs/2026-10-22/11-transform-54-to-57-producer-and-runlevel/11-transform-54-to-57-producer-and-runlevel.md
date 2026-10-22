# Transform 54 To 57 Producer And RunLevel

```
#54 pc2-ui|bc2-ui + Operation failed + ProducerCode/Producer 見つかりません?
#55 / #56 bc2* + Producer Contact is missing for Producer?
#57 bc2-* + Server.RunLevel + ready?
```

| Key point | Detail |
|---|---|
| #54 | Japanese phrases now filled in from your Splunk line |
| #55 / #56 | Same query (duplicate item) |
| #57 | Run level ready on bc2-* hosts |

## Summary

**54** needs `Operation failed` plus either Japanese “not found” phrase. **55** and **56** are identical. **57** matches Server.RunLevel lines that also say ready.

---

## #54 Splunk

```
index=pc2-ui* OR index=bc2-ui*
  "Operation failed"
  AND ("ProducerCode は見つかりませんでした。" OR "Producer は見つかりませんでした。")
```

## #54 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "pc2-ui")
    or startsWith(src, "bc2-ui")
    or contains(log.source, "pc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-ui", caseSensitive:false)
| filter contains(content, "Operation failed", caseSensitive:false)
| filter contains(content, "ProducerCode は見つかりませんでした。", caseSensitive:false)
    or contains(content, "Producer は見つかりませんでした。", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #54 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-1] ProducerService - Operation failed: ProducerCode は見つかりませんでした。"
| fieldsAdd pod = "pc2-ui-6c7d8e-h3nvb"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "pc2-ui") or startsWith(src, "bc2-ui")
| filter contains(dummy, "Operation failed", caseSensitive:false)
| filter contains(dummy, "ProducerCode は見つかりませんでした。", caseSensitive:false)
    or contains(dummy, "Producer は見つかりませんでした。", caseSensitive:false)
| fields src, dummy
```

---

## #55 / #56 Splunk

```
index=bc2* "Producer Contact is missing for Producer"
```

## #55 / #56 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2")
    or contains(log.source, "bc2", caseSensitive:false)
| filter contains(content, "Producer Contact is missing for Producer", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #55 / #56 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 WARN [CommissionWorker-2] ProducerSync - Producer Contact is missing for Producer AG-00417"
| fieldsAdd pod = "bc2-batch-5c8d7f-m4tzr"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2")
| filter contains(dummy, "Producer Contact is missing for Producer", caseSensitive:false)
| fields src, dummy
```

---

## #57 Splunk

```
index=bc2-*
Server.RunLevel AND ready
```

## #57 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-")
    or contains(log.source, "bc2-", caseSensitive:false)
| filter contains(content, "Server.RunLevel", caseSensitive:false)
| filter contains(content, "ready", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #57 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 INFO Server.RunLevel Server run level MULTIUSER is ready"
| fieldsAdd pod = "bc2-ui-7f9c6d-x2kqp"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2-")
| filter contains(dummy, "Server.RunLevel", caseSensitive:false)
| filter contains(dummy, "ready", caseSensitive:false)
| fields src, dummy
```

## Fix vs your draft #54

| Wrong | Right |
|---|---|
| `ProducerCode <JP_TEXT_1>` | `ProducerCode は見つかりませんでした。` |
| Separate `\| or contains` line | `\| filter A or B` on one filter |

## Data flow map

```
#54: pc2-ui|bc2-ui → Operation failed → JP Producer/ProducerCode not found
#55/#56: bc2* → Producer Contact is missing
#57: bc2-* → Server.RunLevel + ready
```

## Related files

| File | Role |
|---|---|
| `11-transform-54-to-57-producer-and-runlevel.dql` | All four |
| `11.sh` | Dual-write |

## Commands

See [11.sh](11.sh).
