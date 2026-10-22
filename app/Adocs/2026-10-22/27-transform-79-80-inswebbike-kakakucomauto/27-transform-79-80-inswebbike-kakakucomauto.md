# Transform 79 80 Inswebbike Kakakucomauto

```
#79 esbv4 inswebbike/_quote + pc Timeout exceeded (lookup UUID)?
#80 same shape, channel = kakakucomauto?
```

| Key point | Detail |
|---|---|
| Same as #77 / #78 | Only the channel path changes |
| #79 path | `/esb/ebroker/inswebbike/online/_quote` |
| #80 path | `/esb/ebroker/kakakucomauto/online/_quote` |
| Timeout match | `.../ebroker/quote' failed: Timeout exceeded.` |

## Summary

**#79** / **#80** are the bike and kakakucomauto channels of the quote-timeout join. Full list + count DQL in companion `.dql`.

## Channel family (#77–#80)

| # | Channel path | `channel` label |
|---|---|---|
| 77 | bangauto | `bangauto` |
| 78 | inswebauto | `inswebauto` |
| 79 | inswebbike | `inswebbike` |
| 80 | kakakucomauto | `kakakucomauto` |

## Data flow map

```
A) channel _quote → UUID
B) pc quote Timeout exceeded → UUID
A lookup B → list / timeout_pct
```

## Related files

| File | Role |
|---|---|
| `27-transform-79-80-inswebbike-kakakucomauto.dql` | List + count |
| `24-transform-77-78-plus-76-example/` | #77 / #78 |
| `27.sh` | Dual-write |

## Commands

See [27.sh](27.sh).
