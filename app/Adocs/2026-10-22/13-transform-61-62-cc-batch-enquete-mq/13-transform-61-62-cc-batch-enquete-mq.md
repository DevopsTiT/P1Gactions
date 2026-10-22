# Transform 61 62 CC Batch Enquete MQ

```
#61 cc-batch ERROR + EnqueteWorkItem_Adj?
 → parse loglevel → ERROR → contains EnqueteWorkItem_Adj → summarize by timestamp

#62 cc-batch ERROR + MessageQueueMonitor_Adj?
 → exclude Sonpovan noise
 → keep lines with "Found "
 → collect 10-digit detail lines → details array
```

| Key point | Detail |
|---|---|
| #61 | ERROR enquete work items |
| #62 | MQ monitor ERROR with detail rows (prettyPrint → details array) |
| Sonpovan exclude | Splunk JP text was garbled — exclude any `Sonpovan` for now; tighten later |

## Summary

**61** parses the log level, keeps ERROR + EnqueteWorkItem_Adj, groups by timestamp. **62** is the same level parse, MessageQueueMonitor_Adj, skips Sonpovan noise, then builds `queueMessage` + `details` like Splunk `prettyPrint`.

---

## #61 Splunk

```
index="cc-batch"
| rex field=_raw "\d+-\d+-\d+\s\d+:\d+:\d+,\d+\s+(?<loglevel>\w+)"
| stats values(loglevel) as loglevel, values(_raw) as log by _time
| search loglevel = "ERROR"
| search log="*EnqueteWorkItem_Adj*"
```

## #61 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "cc-batch")
    or contains(log.source, "cc-batch", caseSensitive:false)
| parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"
| filter loglevel == "ERROR"
| filter contains(content, "EnqueteWorkItem_Adj", caseSensitive:false)
| summarize loglevel = collectDistinct(loglevel), log = collectDistinct(content), by:{ timestamp }
| sort timestamp desc
```

## #61 verify

```
fetch logs
| limit 1
| fieldsAdd content = "2026-10-15 09:12:34,567 ERROR [worker-3] c.e.cc.batch.EnqueteWorkItem_Adj - Work item failed for enquete id 48213"
| fieldsAdd pod = "cc-batch-0"
| fields content, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "cc-batch")
| parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"
| filter loglevel == "ERROR"
| filter contains(content, "EnqueteWorkItem_Adj", caseSensitive:false)
| summarize loglevel = collectDistinct(loglevel), log = collectDistinct(content), by:{ timestamp }
| fields timestamp, loglevel, log
```

---

## #62 Splunk

```
index="*cc-batch*"
| rex ... loglevel ...
| stats values(loglevel) as loglevel, values(_raw) as log by _time
| search loglevel = "ERROR"
| search log = "*MessageQueueMonitor_Adj*"
| search log != "*Sonpovan <JP garbled>*"
| rex field=log "(?<queueMessage>Found .*$)"
| rex field=log max_match=0 "(?<details>[0-9]{10}\s.*$)"
| search details="*"
| eval prettyPrint = queueMessage + newline + mvjoin(details, newline)
```

## #62 DQL (live) — complete (your draft was cut at expand)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter contains(src, "cc-batch", caseSensitive:false)
    or contains(log.source, "cc-batch", caseSensitive:false)
| parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"
| filter loglevel == "ERROR"
| filter contains(content, "MessageQueueMonitor_Adj", caseSensitive:false)
| filter not contains(content, "Sonpovan", caseSensitive:false)
| filter contains(content, "Found ", caseSensitive:false)
| fieldsAdd queueMessage = substring(content, from:indexOf(content, "Found "))
| fieldsAdd line = splitString(content, "\n")
| expand line
| parse line, "(DIGIT{10} SPACE LD):detail"
| filter isNotNull(detail)
| summarize details = collectArray(detail), by:{ timestamp, src, queueMessage }
| sort timestamp desc
| fields timestamp, src, queueMessage, details
```

If you later get the exact Japanese after `Sonpovan`, tighten the exclude:

```
| filter not contains(content, "Sonpovan <PASTE_JP_HERE>", caseSensitive:false)
```

## #62 verify

```
fetch logs
| limit 1
| fieldsAdd content = "2026-10-15 09:12:34,567 ERROR [monitor-1] c.e.cc.batch.MessageQueueMonitor_Adj - [MQ] Found 2 stuck messages in queue CC_OUT\n1234567890 stuck message one\n9876543210 stuck message two"
| fieldsAdd pod = "cc-batch-2"
| fields content, pod
| fieldsAdd src = lower(pod)
| filter contains(src, "cc-batch", caseSensitive:false)
| parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"
| filter loglevel == "ERROR"
| filter contains(content, "MessageQueueMonitor_Adj", caseSensitive:false)
| filter not contains(content, "Sonpovan", caseSensitive:false)
| filter contains(content, "Found ", caseSensitive:false)
| fieldsAdd queueMessage = substring(content, from:indexOf(content, "Found "))
| fieldsAdd line = splitString(content, "\n")
| expand line
| parse line, "(DIGIT{10} SPACE LD):detail"
| filter isNotNull(detail)
| summarize details = collectArray(detail), by:{ timestamp, src, queueMessage }
| fields timestamp, src, queueMessage, details
```

**Pass:** `queueMessage` starts with `Found `, `details` has two 10-digit lines.

## Splunk → DQL

| Splunk | DQL |
|---|---|
| `rex` loglevel | `parse ... WORD:loglevel` |
| `stats by _time` | `summarize ... by:{ timestamp }` |
| `prettyPrint` / `mvjoin` | `details` array from `collectArray` |
| `log != "*Sonpovan...*"` | `not contains(..., "Sonpovan", ...)` until JP is known |

## Data flow map

```
#61: cc-batch → parse ERROR → EnqueteWorkItem_Adj → summarize by time
#62: cc-batch → parse ERROR → MessageQueueMonitor_Adj
      → drop Sonpovan → Found ... → expand lines → 10-digit details
```

## Related files

| File | Role |
|---|---|
| `13-transform-61-62-cc-batch-enquete-mq.dql` | Live + verify |
| `2026-10-15/6-pc2-cc-batch-sonpovan-58-66-dql/` | Earlier pack |
| `13.sh` | Dual-write |

## Commands

See [13.sh](13.sh).
