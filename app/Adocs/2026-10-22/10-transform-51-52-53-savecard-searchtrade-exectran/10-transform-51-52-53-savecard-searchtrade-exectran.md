# Transform 51 52 53 SaveCard SearchTrade EXECTRAN

```
#51 bc2-batch + saveCardWithOrderID errors + MW-Writer-[54]?
#52 three apps + GMO SearchTrade confirm ExecTran?
#53 three apps + Exception during GMO call EXECTRAN? → same as #43 / #49
```

| Key point | Detail |
|---|---|
| #51 | Writer 54 saveCardWithOrderID errors |
| #52 | SearchTrade confirmation message |
| #53 | Same text as #43 / #49 |
| Tip | In DQL `contains`, use `MW-Writer-[54]` — do **not** escape `[` `]` |

## Summary

**51** is bc2-batch only with two phrase matches. **52** / **53** use the three-app filter; **53** matches #43/#49.

---

## #51 Splunk

```
index="bc2-batch" "Errors in saveCardWithOrderID call" "MW-Writer-[54]"
```

## #51 DQL (live)

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter startsWith(src, "bc2-batch")
    or contains(log.source, "bc2-batch", caseSensitive:false)
    or contains(k8s.pod.name, "bc2-batch", caseSensitive:false)
| filter contains(content, "Errors in saveCardWithOrderID call", caseSensitive:false)
| filter contains(content, "MW-Writer-[54]", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #51 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-20 09:50:23,825 ERROR [MW-Writer-[54]-0x] Integration.Payment - Errors in saveCardWithOrderID call:"
| fieldsAdd pod = "bc2-batch-5c8d7f-m4tzr"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2-batch")
| filter contains(dummy, "Errors in saveCardWithOrderID call", caseSensitive:false)
| filter contains(dummy, "MW-Writer-[54]", caseSensitive:false)
| fields src, dummy
```

---

## #52 Splunk

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)
AND "GMO SearchTrade used to confirm ExecTran status with OrderID"
```

## #52 DQL (live)

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
| filter contains(content, "GMO SearchTrade used to confirm ExecTran status with OrderID", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## #52 verify

```
fetch logs
| limit 1
| fieldsAdd dummy = "2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-6] GmoClient - GMO SearchTrade used to confirm ExecTran status with OrderID ORD-20261015-0152: status=CAPTURE"
| fieldsAdd pod = "bc2-ui-7f9c6d-x2kqp"
| fields dummy, pod
| fieldsAdd src = lower(pod)
| filter startsWith(src, "bc2-ui")
| filter contains(dummy, "GMO SearchTrade used to confirm ExecTran status with OrderID", caseSensitive:false)
| fields src, dummy
```

---

## #53 DQL (live) — same as #43 / #49

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

## Data flow map

```
#51: bc2-batch → saveCardWithOrderID + MW-Writer-[54]
#52: three apps → GMO SearchTrade confirm ExecTran
#53: three apps → Exception during GMO call EXECTRAN
```

## Related files

| File | Role |
|---|---|
| `10-transform-51-52-53-savecard-searchtrade-exectran.dql` | All three |
| `9-transform-48-49-50-api-gmo-e01/` | #53 twin (#49) |
| `10.sh` | Dual-write |

## Commands

See [10.sh](10.sh).
