# Cm2ui Mailservice Podfrozen DQL

```
#8 cm2-ui → Message != 2
#9 mailservice → Message != 1
```

| Key point | Detail |
|---|---|
| #8 | Healthy **2** |
| #9 | Healthy **1** |

## #8 DQL (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "cm2-ui", caseSensitive:false)
    or contains(log.source, "cm2-ui", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 2
| fieldsAdd host = "Total"
| fields host, Message
```

## #9 DQL (live)

```
fetch logs, from:now()-15m
| fieldsAdd host = coalesce(k8s.pod.name, host.name)
| filter contains(lower(host), "mailservice", caseSensitive:false)
    or contains(log.source, "mailservice", caseSensitive:false)
| summarize by:{ host }
| summarize Message = count()
| filter Message != 1
| fieldsAdd host = "Total"
| fields host, Message
```

## Data flow map

```
cm2-ui → != 2 → alert
mailservice → != 1 → alert
```

## Related files

| File | Role |
|---|---|
| `7-cm2ui-mailservice-podfrozen-dql.dql` | Live |
| `7.sh` | Dual-write |

## Commands

See [7.sh](7.sh).
