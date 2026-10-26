# Bc2 Batch Podfrozen DQL

```
#6 bc2-batch → Message != 2
```

| Key point | Detail |
|---|---|
| Healthy | **2** hosts: `bc2-batch-inssuite-prod-0`, `bc2-batch-inssuite-prod-1` |

## #6 DQL (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "bc2-batch", caseSensitive:false)
    or contains(log.source, "bc2-batch", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 2
| fieldsAdd host = "Total"
| fields host, Message
```

## Data flow map

```
bc2-batch → distinct hosts → != 2 → alert
```

## Related files

| File | Role |
|---|---|
| `5-bc2-batch-podfrozen-dql.dql` | Live |
| `5.sh` | Dual-write |

## Commands

See [5.sh](5.sh).
