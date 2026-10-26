# Agrex Alfrescoaca Podfrozen DQL

```
#3 Agrex PODFrozen → Message != 1
#4 Alfrescoaca PODFrozen → same pattern (confirm N from full SPL)
```

| Key point | Detail |
|---|---|
| #3 Agrex | Alert when distinct host count **≠ 1** |
| #4 Alfrescoaca | Same shape; set `Message != N` from full SPL |
| vs batch (#1) | Batch expected **4**; Agrex expected **1** |

## Summary

Agrex healthy count is **1 host**. Alfrescoaca uses the same Total-row pattern; finish `NOT Message=N` from the cut-off SPL.

## #3 DQL (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "agrex", caseSensitive:false)
    or contains(log.source, "agrex", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 1
| fieldsAdd host = "Total"
| fields host, Message
```

## #4 DQL (template)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "alfrescoaca", caseSensitive:false)
    or contains(log.source, "alfrescoaca", caseSensitive:false)
| filter not contains(lower(host), "alfrescoacr-batch", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 4
| fieldsAdd host = "Total"
| fields host, Message
```

## Data flow map

```
agrex logs → distinct hosts → Message != 1 → Total row
alfrescoaca logs → distinct hosts → Message != N → Total row
```

## Related files

| File | Role |
|---|---|
| `2-agrex-alfrescoaca-podfrozen-dql.dql` | Live + verify |
| `1-alfrescoacr-batch-podfrozen-dql/` | Batch Message != 4 |
| `2.sh` | Dual-write |

## Commands

See [2.sh](2.sh).
