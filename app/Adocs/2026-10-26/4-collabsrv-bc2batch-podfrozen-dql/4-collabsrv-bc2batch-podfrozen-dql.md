# Collabsrv Bc2batch Podfrozen DQL

```
#5 alfrescocollabsrv → Message != 1
#6 bc2-batch → Message != 2
```

| Key point | Detail |
|---|---|
| #5 | Healthy = **1** |
| #6 | Healthy = **2** |

## Summary

POD-frozen Total-row checks for collabsrv and bc2-batch.

## #5 DQL (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "alfrescocollabsrv", caseSensitive:false)
    or contains(log.source, "alfrescocollabsrv", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 1
| fieldsAdd host = "Total"
| fields host, Message
```

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

## Expected-count cheat sheet

| # | Index | Healthy |
|---|---|---|
| 5 | alfrescocollabsrv | **1** |
| 6 | bc2-batch | **2** |

## Data flow map

```
#5 → != 1 → alert
#6 → != 2 → alert
```

## Related files

| File | Role |
|---|---|
| `4-collabsrv-bc2batch-podfrozen-dql.dql` | Live + verify |
| `4.sh` | Dual-write |

## Commands

See [4.sh](4.sh).
