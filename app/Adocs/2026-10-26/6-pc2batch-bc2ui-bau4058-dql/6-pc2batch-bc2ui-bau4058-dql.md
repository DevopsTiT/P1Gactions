# Pc2batch Bc2ui Bau4058 DQL

```
pc2-batch → Message != 2
BAU-4058 phrase on bc2-batch
bc2-ui → Message != 2
```

| Key point | Detail |
|---|---|
| pc2-batch | Healthy **2** (`prod-0`, `prod-1`) |
| bc2-ui | Healthy **2** |
| BAU-4058 | Phrase contains |

## #7 pc2-batch DQL

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "pc2-batch", caseSensitive:false)
    or contains(log.source, "pc2-batch", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 2
| fieldsAdd host = "Total"
| fields host, Message
```

## BAU-4058 DQL

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name, log.source))
| filter contains(src, "bc2-batch", caseSensitive:false)
    or contains(log.source, "bc2-batch", caseSensitive:false)
| filter contains(content, "Creation of payment request in BC has thrown an exception", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## bc2-ui POD frozen DQL

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "bc2-ui", caseSensitive:false)
    or contains(log.source, "bc2-ui", caseSensitive:false)
| filter not contains(lower(host), "bc2-batch", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 2
| fieldsAdd host = "Total"
| fields host, Message
```

## Data flow map

```
pc2-batch / bc2-ui → != 2 → alert
bc2-batch + exception phrase → rows
```

## Related files

| File | Role |
|---|---|
| `6-pc2batch-bc2ui-bau4058-dql.dql` | All |
| `6.sh` | Dual-write |

## Commands

See [6.sh](6.sh).
