# Transform 45 46 47 BC2 CVS And Duplicates

```
#45 bc2* + ERROR + Integration.CVS + CvsOfflinePaymentNotification exception?
#46 bc2* + MultipleMatchesException + ContactID_Adj + Values?
#47 bc2-batch + CVS Offline quick records with count > 1?
 → same as #41 duplicate pipeline
```

| Key point | Detail |
|---|---|
| #45 | CVS offline payment notification processing exception |
| #46 | DB multiple matches on ContactID_Adj |
| #47 | Same logic as #41 (duplicate Identifier/Amount/PaymentDate) |

## Summary

**45** and **46** are multi-phrase text filters on any `bc2*` host/pod. **47** is the duplicate CVS Offline quick-record stats query (same as #41).

---

## #45 Splunk

```
index=bc2* ERROR AND Integration.CVS
  AND "Exception caught while processing item {entity.CvsOfflinePaymentNotification_Adj:"
```

## #45 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2")
    or contains(log.source, "bc2", caseSensitive:false)
| filter contains(content, "ERROR", caseSensitive:false)
    and contains(content, "Integration.CVS", caseSensitive:false)
    and contains(content, "Exception caught while processing item", caseSensitive:false)
    and contains(content, "CvsOfflinePaymentNotification_Adj", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

(Logs may use `{entity...` or `[entity...` — matching the entity name covers both.)

## #45 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 ERROR Integration.CVS [CvsNotifyWorker-2] Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:pc:10482]"
| fieldsAdd pod = "bc2-batch-5c8d7f-m4tzr"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2")
| filter contains(dummy, "ERROR", caseSensitive:false)
    and contains(dummy, "Integration.CVS", caseSensitive:false)
    and contains(dummy, "CvsOfflinePaymentNotification_Adj", caseSensitive:false)
| fields src, dummy
```

---

## #46 Splunk

```
index=bc2* gw.api.database.MultipleMatchesException AND ContactID_Adj AND Values
```

## #46 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2")
    or contains(log.source, "bc2", caseSensitive:false)
| filter contains(content, "gw.api.database.MultipleMatchesException", caseSensitive:false)
    and contains(content, "ContactID_Adj", caseSensitive:false)
    and contains(content, "Values", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #46 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-9] gw.api.database.MultipleMatchesException: More than one row found for query on Contact where ContactID_Adj = ? Values: [C-000123]"
| fieldsAdd pod = "bc2-ui-7f9c6d-x2kqp"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2")
| filter contains(dummy, "gw.api.database.MultipleMatchesException", caseSensitive:false)
    and contains(dummy, "ContactID_Adj", caseSensitive:false)
    and contains(dummy, "Values", caseSensitive:false)
| fields src, dummy
```

---

## #47 Splunk (same as #41)

```
index=bc2-batch* "PaymentRecordType=Quick record for CVS Offline"
| dedup _raw
| stats count by Identifier, Amount, PaymentDate
| where count > 1
| eval PaymentDateForSort=strptime(PaymentDate, "%a %b %d %H:%M:%S %Z %Y")
| sort PaymentDateForSort
| fields Identifier, Amount, PaymentDate
```

## #47 DQL (live)

```
fetch logs, from:now()-7d
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-batch")
    or contains(log.source, "bc2-batch", caseSensitive:false)
    or contains(k8s.pod.name, "bc2-batch", caseSensitive:false)
| filter contains(content, "PaymentRecordType=Quick record for CVS Offline", caseSensitive:false)
| dedup content
| parse content, "LD 'Identifier=' LD:Identifier ','"
| parse content, "LD 'Amount=' LD:Amount ','"
| parse content, "LD 'PaymentDate=' LD:PaymentDate ','"
| summarize count = count(), by:{ Identifier, Amount, PaymentDate }
| filter count > 1
| fieldsAdd pd_clean = replaceString(PaymentDate, " JST ", " ")
| parse pd_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):PaymentDateForSort"
| sort PaymentDateForSort asc
| fields Identifier, Amount, PaymentDate
```

## Data flow map

```
#45: bc2* → ERROR + Integration.CVS + CvsOfflinePaymentNotification_Adj → fields
#46: bc2* → MultipleMatchesException + ContactID_Adj + Values → fields
#47: bc2-batch → parse keys → count > 1 → sort by PaymentDate
```

## Related files

| File | Role |
|---|---|
| `8-transform-45-46-47-bc2-cvs-and-duplicates.dql` | All three |
| `4-transform-41-bc2-cvs-offline-duplicates/` | Same as #47 |
| `8.sh` | Dual-write |

## Commands

See [8.sh](8.sh).
