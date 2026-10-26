# Alfrescoacr Batch Podfrozen DQL

```
Prod_PnC_Alfrescoacr_BatchPODFrozen_High
 → count distinct hosts logging as alfrescoacr-batch
 → expected = 4 (prod-0..3)
 → return a row only when Message != 4
```

| Key point | Detail |
|---|---|
| What this is | “POD frozen” check: are all 4 batch pods still sending logs? |
| Healthy | 4 hosts → **0 rows** |
| Unhealthy | Message != 4 → one row `host=Total` |

## Summary

Count distinct hosts for `alfrescoacr-batch`. Alert when the count is not 4.

## DQL — alert shape (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 4
| fieldsAdd host = "Total"
| fields host, Message
```

## DQL — host list (debug)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| summarize events = count(), by:{ host }
| sort host asc
| fields host, events
```

## Data flow map

```
logs → distinct hosts → Message = count → != 4 → Total row (alert)
```

## Related files

| File | Role |
|---|---|
| `1-alfrescoacr-batch-podfrozen-dql.dql` | Alert + list + verify |
| `1.sh` | Dual-write |

## Commands

See [1.sh](1.sh).
