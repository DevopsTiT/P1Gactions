# Alfrescoaca Collabsrv Podfrozen DQL

```
#4 Alfrescoaca → Message != 3
#5 Alfrescocollabsrv → same pattern (confirm N)
```

| Key point | Detail |
|---|---|
| #4 | Healthy = **3** hosts |
| #5 | Template until `NOT Message=N` is visible |

## Summary

**#4** uses `Message != 3`. **#5** is the same POD-frozen shape for `alfrescocollabsrv`.

## #4 DQL (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "alfrescoaca", caseSensitive:false)
    or contains(log.source, "alfrescoaca", caseSensitive:false)
| filter not contains(lower(host), "alfrescoacr-batch", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 3
| fieldsAdd host = "Total"
| fields host, Message
```

## Expected-count cheat sheet

| # | Index | Healthy |
|---|---|---|
| 1 | alfrescoacr-batch | 4 |
| 3 | agrex | 1 |
| 4 | alfrescoaca | **3** |
| 5 | alfrescocollabsrv | N |

## Data flow map

```
alfrescoaca → distinct hosts → != 3 → alert
alfrescocollabsrv → distinct hosts → != N → alert
```

## Related files

| File | Role |
|---|---|
| `3-alfrescoaca-collabsrv-podfrozen-dql.dql` | Queries |
| `3.sh` | Dual-write |

## Commands

See [3.sh](3.sh).
