# Transform 58 To 60 Bcsubledger PC2 CC

```
#58 bcsubledger + JP skip-message text?
#59 pc2-batch + payment request creation + failure?
#60 cc-ui|cc-batch + host cc-* + RemoveDocumentChain Execution Duration?
```

| Key point | Detail |
|---|---|
| #58 | Japanese skip-rule message (fill the commented SEARCH_TEXT) |
| #59 | Payment request creation failure |
| #60 | RemoveDocumentChain duration on CC apps |

## Summary

**58** uses the Japanese phrase from your Splunk line. **59** needs both the creation phrase and `failure`. **60** scopes to cc-ui/cc-batch (and `cc-` in src) plus three words.

---

## #58 Splunk

```
index=bcsubledger
適合するルールが無いため、当該メッセージの処理をスキップします
```

## #58 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bcsubledger")
    or startsWith(src, "bc2subledger")
    or contains(log.source, "bcsubledger", caseSensitive:false)
    or contains(log.source, "bc2subledger", caseSensitive:false)
| filter contains(content, "適合するルールが無いため、当該メッセージの処理をスキップします", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #58 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-20 17:04:12.975 INFO 適合するルールが無いため、当該メッセージの処理をスキップします"
| fieldsAdd pod = "bcsubledger-7b5d9c6f8-t2xkn"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bcsubledger")
| filter contains(dummy, "適合するルールが無いため、当該メッセージの処理をスキップします", caseSensitive:false)
| fields src, dummy
```

---

## #59 Splunk

```
index=pc2-batch "Creation of a payment request for transaction" failure
```

## #59 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "pc2-batch")
    or contains(log.source, "pc2-batch", caseSensitive:false)
    or contains(k8s.pod.name, "pc2-batch", caseSensitive:false)
| filter contains(content, "Creation of a payment request for transaction", caseSensitive:false)
| filter contains(content, "failure", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #59 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 ERROR [PaymentRequestWorker-3] Creation of a payment request for transaction TXN-20261015-0077 ended in failure"
| fieldsAdd pod = "pc2-batch-84d6c7b5f-r9lqv"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "pc2-batch")
| filter contains(dummy, "Creation of a payment request for transaction", caseSensitive:false)
| filter contains(dummy, "failure", caseSensitive:false)
| fields src, dummy
```

---

## #60 Splunk

```
(index=cc-ui OR index=cc-batch)
AND host="*cc-*"
RemoveDocumentChain Execution Duration
```

## #60 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "cc-ui")
    or startsWith(src, "cc-batch")
    or contains(log.source, "cc-ui", caseSensitive:false)
    or contains(log.source, "cc-batch", caseSensitive:false)
| filter contains(src, "cc-", caseSensitive:false)
| filter contains(content, "RemoveDocumentChain", caseSensitive:false)
| filter contains(content, "Execution", caseSensitive:false)
| filter contains(content, "Duration", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #60 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 INFO [DocWorker-2] RemoveDocumentChain Execution Duration: 1234 ms"
| fieldsAdd pod = "cc-batch-6f5b8d9c7-w8jzm"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "cc-ui") or startsWith(src, "cc-batch")
| filter contains(src, "cc-", caseSensitive:false)
| filter contains(dummy, "RemoveDocumentChain", caseSensitive:false)
| filter contains(dummy, "Execution", caseSensitive:false)
| filter contains(dummy, "Duration", caseSensitive:false)
| fields src, dummy
```

## Data flow map

```
#58: bcsubledger → JP skip message
#59: pc2-batch → payment request creation + failure
#60: cc-ui|cc-batch → RemoveDocumentChain Execution Duration
```

## Related files

| File | Role |
|---|---|
| `12-transform-58-to-60-bcsubledger-pc2-cc.dql` | All three |
| `12.sh` | Dual-write |

## Commands

See [12.sh](12.sh).
